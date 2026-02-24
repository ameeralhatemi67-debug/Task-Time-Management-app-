import 'dart:math';
import 'package:flutter/foundation.dart'; // For compute
import 'package:flutter/material.dart';
import 'package:task_manager_app/data/repositories/settings_repository.dart';
import 'package:task_manager_app/core/services/notification_service.dart';
import 'package:task_manager_app/core/services/storage_service.dart';
import 'package:task_manager_app/features/habits/models/habit_model.dart';
import 'package:task_manager_app/features/tasks/models/task_model.dart';
import 'package:task_manager_app/data/repositories/habit_repository.dart';
import 'package:task_manager_app/data/repositories/task_repository.dart';

// -----------------------------------------------------------------------------
// DATA TRANSFER OBJECTS (For Isolate)
// -----------------------------------------------------------------------------
class HabitAnalysisData {
  final String id;
  final String title;
  final HabitType type;
  final List<int> scheduledWeekdays;
  final DateTime startDate;
  final List<DateTime> completedDaysList;
  final Map<int, int> dailyLoadMap;

  HabitAnalysisData({
    required this.id,
    required this.title,
    required this.type,
    required this.scheduledWeekdays,
    required this.startDate,
    required this.completedDaysList,
    required this.dailyLoadMap,
  });
}

class NudgeContent {
  final String title;
  final String body;
  final String payload;
  final String? suggestionAction;

  NudgeContent({
    required this.title,
    required this.body,
    required this.payload,
    this.suggestionAction,
  });
}

// -----------------------------------------------------------------------------
// TOP-LEVEL ISOLATE FUNCTION
// -----------------------------------------------------------------------------
NudgeContent? _analyzeHabitInIsolate(HabitAnalysisData data) {
  // 1. Validation
  if (data.type != HabitType.weekly || data.scheduledWeekdays.isEmpty) {
    return null;
  }

  // Only analyze mature habits (active for at least 3 weeks)
  final daysActive = DateTime.now().difference(data.startDate).inDays;
  if (daysActive < 21) return null;

  // 2. Replay History
  Map<int, _DayStats> stats = {};
  for (int day in data.scheduledWeekdays) {
    stats[day] = _DayStats();
  }

  DateTime cursor = data.startDate;
  final now = DateTime.now();

  final completedSet = data.completedDaysList
      .map((d) => DateTime(d.year, d.month, d.day))
      .toSet();

  while (cursor.isBefore(now)) {
    if (data.scheduledWeekdays.contains(cursor.weekday)) {
      stats[cursor.weekday]!.opportunities++;

      final cursorDate = DateTime(cursor.year, cursor.month, cursor.day);
      if (!completedSet.contains(cursorDate)) {
        stats[cursor.weekday]!.misses++;
      }
    }
    cursor = cursor.add(const Duration(days: 1));
  }

  // 3. Find the "Fail Day"
  int? failDay;
  double highestFailRate = 0.0;

  stats.forEach((day, stat) {
    if (stat.opportunities < 3) return;
    double rate = stat.misses / stat.opportunities;

    if (rate > 0.40 && rate > highestFailRate) {
      highestFailRate = rate;
      failDay = day;
    }
  });

  if (failDay == null) return null;

  // 4. Find a "Better Day"
  int betterDay = _findBetterDayIsolated(data.dailyLoadMap);

  // 5. Generate Nudge
  String dayName = _getWeekdayNameIsolated(failDay!);
  String betterName = _getWeekdayNameIsolated(betterDay);

  return NudgeContent(
    title: "Smart Suggestion 💡",
    body:
        "You often miss '${data.title}' on ${dayName}s. Move it to $betterName?",
    payload: "habit_reschedule:${data.id}:$failDay:$betterDay",
    suggestionAction: "Move to $betterName",
  );
}

int _findBetterDayIsolated(Map<int, int> dailyLoad) {
  var sortedKeys = dailyLoad.keys.toList()
    ..sort((a, b) => (dailyLoad[a] ?? 0).compareTo(dailyLoad[b] ?? 0));
  return sortedKeys.first;
}

String _getWeekdayNameIsolated(int day) {
  const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  if (day < 1 || day > 7) return "Day";
  return days[day - 1];
}

class _DayStats {
  int opportunities = 0;
  int misses = 0;
}

// -----------------------------------------------------------------------------
// MANAGER CLASS
// -----------------------------------------------------------------------------

class SmartNudgeManager {
  static final SmartNudgeManager instance = SmartNudgeManager._();
  SmartNudgeManager._();

  final Random _random = Random();
  final HabitRepository _habitRepo = HabitRepository();
  final TaskRepository _taskRepo = TaskRepository();

  Future<void> triggerDailyNudges() async {
    final box = StorageService.instance.prefsBox;
    final lastRunString = box.get('last_nudge_run');
    final now = DateTime.now();

    // 1. SPAM PREVENTION
    if (lastRunString != null) {
      final lastRun = DateTime.parse(lastRunString);
      if (lastRun.year == now.year &&
          lastRun.month == now.month &&
          lastRun.day == now.day) {
        return;
      }
    }

    // 2. PRE-CALCULATE LOAD MAP
    final allHabits = _habitRepo.getAllActiveHabits();
    Map<int, int> globalDailyLoad = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    for (var h in allHabits) {
      if (h.type == HabitType.weekly) {
        for (var d in h.scheduledWeekdays) {
          globalDailyLoad[d] = (globalDailyLoad[d] ?? 0) + 1;
        }
      }
    }

    // --- 3. PROCESS HABITS (With Settings Check) ---
    final settings = SettingsRepository().getSettings();

    if (settings.allEnabled && settings.habitNotifications) {
      for (var habit in allHabits) {
        await Future.delayed(const Duration(milliseconds: 20));

        try {
          // A. Fail Patterns (Run in Background Isolate)
          final analysisData = HabitAnalysisData(
            id: habit.id,
            title: habit.title,
            type: habit.type,
            scheduledWeekdays: habit.scheduledWeekdays,
            startDate: habit.startDate,
            completedDaysList: habit.completedDaysList,
            dailyLoadMap: Map.from(globalDailyLoad),
          );

          final failNudge = await compute(_analyzeHabitInIsolate, analysisData);

          if (failNudge != null) {
            // FIXED: Break object into named params
            await NotificationService().showSmartNudge(
              id: habit.id.hashCode,
              title: failNudge.title,
              body: failNudge.body,
              payload: failNudge.payload,
            );
            continue;
          }

          // B. Routine Nudges (Main Thread)
          final nudge = generateHabitNudge(habit);
          if (nudge != null) {
            if (_random.nextDouble() > 0.7) {
              // FIXED: Break object into named params
              await NotificationService().showSmartNudge(
                id: habit.id.hashCode,
                title: nudge.title,
                body: nudge.body,
                payload: nudge.payload,
              );
            }
          }
          // (Removed Duplicate Block Here)
        } catch (e) {
          debugPrint("Error processing nudge for ${habit.title}: $e");
        }
      }
    }

    // 4. PROCESS TASKS (Lightweight)
    final tasks =
        _taskRepo.getAll().where((t) => !t.isDone && !t.isArchived).toList();
    tasks.sort((a, b) => b.importance.index.compareTo(a.importance.index));

    int taskNudgeCount = 0;
    for (var task in tasks) {
      if (taskNudgeCount >= 2) break;
      await Future.delayed(const Duration(milliseconds: 20));

      final nudge = generateTaskNudge(task);
      if (nudge != null) {
        // FIXED: Updated Task Nudge to use named params
        await NotificationService().showSmartNudge(
          id: task.id.hashCode, // Unique ID
          title: nudge.title,
          body: nudge.body,
          payload: nudge.payload,
        );
        taskNudgeCount++;
      }
    }

    await box.put('last_nudge_run', now.toIso8601String());
  }

  // ... (Keep existing generateHabitNudge, generateTaskNudge, templates, and helpers) ...

  // ---------------------------------------------------------------------------
  // EXISTING TEMPLATES & GENERATORS
  // ---------------------------------------------------------------------------

  final List<String> _streakSaverTemplates = [
    "Don't break the chain! 🔗 Do '{title}' today.",
    "{streak} day streak at risk! 🚨 '{title}' is waiting.",
    "Keep the momentum going! Time for '{title}'.",
  ];

  final List<String> _recoveryTemplates = [
    "We miss you! 👋 It's been {days} days since you did '{title}'.",
    "Fresh start? 🌿 Do '{title}' today and feel great.",
  ];

  final List<String> _highStreakTemplates = [
    "You are on fire! 🔥 {streak} days of '{title}'.",
    "Unstoppable! Keep crushing '{title}'.",
  ];

  final List<String> _urgentTaskTemplates = [
    "Priority Alert: '{title}' needs your attention! ⚡",
    "Don't forget '{title}'. It's marked as High Priority.",
  ];

  final List<String> _staleTaskTemplates = [
    "Still planning to do '{title}'? 🤔",
    "Is '{title}' still relevant? Complete or Archive it today.",
  ];

  NudgeContent? generateHabitNudge(HabitModel habit) {
    if (habit.isArchived ?? false) return null;
    final now = DateTime.now();
    int daysMissed = 0;
    if (habit.completedDaysList.isNotEmpty) {
      final lastDate =
          habit.completedDaysList.reduce((a, b) => a.isAfter(b) ? a : b);
      daysMissed = now.difference(lastDate).inDays;
    } else {
      daysMissed = now.difference(habit.startDate).inDays;
    }

    if (daysMissed == 0) return null;

    String template = "";
    if (daysMissed >= 3) {
      template = _getRandom(_recoveryTemplates);
    } else if (habit.currentStreak > 5) {
      template = _getRandom(_highStreakTemplates);
    } else {
      template = _getRandom(_streakSaverTemplates);
    }

    final body = _format(template, {
      '{title}': habit.title,
      '{streak}': habit.currentStreak.toString(),
      '{days}': daysMissed.toString(),
    });

    return NudgeContent(
      title: "Habit Reminder",
      body: body,
      payload: "habit:${habit.id}",
    );
  }

  NudgeContent? generateTaskNudge(TaskModel task) {
    if (task.isDone || task.isArchived) return null;
    final now = DateTime.now();
    final daysOld = now.difference(task.dateCreated).inDays;
    String template = "";

    if (task.importance == TaskImportance.high) {
      template = _getRandom(_urgentTaskTemplates);
    } else if (daysOld > 7) {
      template = _getRandom(_staleTaskTemplates);
    } else {
      template = "Action Item: '{title}' is still pending.";
    }

    final body = _format(template, {
      '{title}': task.title,
      '{duration}': task.durationMinutes?.toString() ?? "25",
    });

    return NudgeContent(
      title: "Task Reminder",
      body: body,
      payload: "task:${task.id}",
    );
  }

  String _getRandom(List<String> options) =>
      options[_random.nextInt(options.length)];

  String _format(String template, Map<String, String> values) {
    String result = template;
    values.forEach((key, value) {
      result = result.replaceAll(key, value);
    });
    return result;
  }
}
