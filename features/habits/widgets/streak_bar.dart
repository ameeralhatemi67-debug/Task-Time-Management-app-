import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:task_manager_app/core/services/storage_service.dart';
import 'package:task_manager_app/data/repositories/habit_repository.dart';
import '../models/habit_model.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';

class StreakBar extends StatelessWidget {
  final AppColors colors;
  final List<HabitModel> habits;
  final DateTime firstLaunchDate;

  const StreakBar({
    super.key,
    required this.colors,
    required this.habits,
    required this.firstLaunchDate,
  });

  /// Helper: Calculates progress based on USER GOAL & SCHEDULE
  ({double progress, int completed, int goal}) _calculateDailyProgress(
      DateTime date, int dailyGoal) {
    int completed = 0;
    int scheduled = 0;

    for (var habit in habits) {
      // 1. Skip archived habits
      if (habit.isArchived ?? false) continue;

      // 2. Skip habits that hadn't started yet (Normalize start date to midnight)
      final startMidnight = DateTime(
          habit.startDate.year, habit.startDate.month, habit.startDate.day);
      if (date.isBefore(startMidnight)) continue;

      // 3. Check Schedule
      if (habit.isScheduledOn(date)) {
        scheduled++;
        // 4. Check Completion
        if (habit.isCompletedOn(date)) {
          completed++;
        }
      }
    }

    // --- DYNAMIC GOAL LOGIC ---
    // Rule: "If less than streak goal, match amount. If more, follow streak."
    int effectiveGoal = dailyGoal;

    // If you only have 1 habit scheduled, goal becomes 1.
    // If you have 5 scheduled, goal stays at 3 (or whatever user set).
    if (scheduled < dailyGoal) {
      effectiveGoal = scheduled;
    }

    // Safety: If nothing scheduled, goal is 0 (empty state)
    if (effectiveGoal == 0) {
      return (progress: 0.0, completed: 0, goal: 0);
    }

    double progress = completed / effectiveGoal;
    if (progress > 1.0) progress = 1.0;

    return (progress: progress, completed: completed, goal: effectiveGoal);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    // Show range starting from 2 days ago
    DateTime startDisplayDate = today.subtract(const Duration(days: 2));

    // Clamp to first launch date so we don't show invalid history
    final DateTime cleanLaunchDate = DateTime(
      firstLaunchDate.year,
      firstLaunchDate.month,
      firstLaunchDate.day,
    );
    if (startDisplayDate.isBefore(cleanLaunchDate)) {
      startDisplayDate = cleanLaunchDate;
    }

    const int totalDaysToShow = 9;

    // Listen to Settings/Preferences for instant updates
    return ValueListenableBuilder(
        valueListenable: StorageService.instance.prefsBox.listenable(),
        builder: (context, box, _) {
          final repo = HabitRepository();
          final int dailyGoal = repo.getDailyGoal();
          final bool showCounter = repo.getShowStreakCounter(); // NEW TOGGLE

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(totalDaysToShow, (index) {
                final date = startDisplayDate.add(Duration(days: index));
                final isToday = date.year == today.year &&
                    date.month == today.month &&
                    date.day == today.day;

                final stats = _calculateDailyProgress(date, dailyGoal);

                return _buildDayIndicator(
                  context,
                  date: date,
                  progress: stats.progress,
                  completed: stats.completed,
                  goal: stats.goal,
                  isToday: isToday,
                  showCounter: showCounter,
                );
              }),
            ),
          );
        });
  }

  Widget _buildDayIndicator(
    BuildContext context, {
    required DateTime date,
    required double progress,
    required int completed,
    required int goal,
    required bool isToday,
    required bool showCounter,
  }) {
    // Visual Logic
    final bool isEmpty = goal == 0;
    final bool isComplete = progress >= 1.0 && !isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Weekday Label
          Text(
            DateFormat('E').format(date).toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isToday
                  ? colors.highlight
                  : colors.textSecondary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),

          // 2. The Progress Ring
          SizedBox(
            width: 45,
            height: 45,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background Track
                CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colors.textSecondary.withOpacity(0.1),
                  ),
                ),

                // Foreground Progress (Satisfying Animation)
                if (!isEmpty)
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: progress),
                    // Slower duration + Elastic Curve = Satisfying "Fill Up"
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.elasticOut,
                    builder: (context, value, _) {
                      return CircularProgressIndicator(
                        value: value,
                        strokeWidth: 4,
                        strokeCap: StrokeCap.round,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          // Switch color when complete
                          value >= 1.0 ? colors.done : colors.highlight,
                        ),
                        backgroundColor: Colors.transparent,
                      );
                    },
                  ),

                // Date Number inside
                Text(
                  "${date.day}",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isToday
                        ? colors.textMain
                        : (isEmpty
                            ? colors.textSecondary.withOpacity(0.5)
                            : colors.textMain),
                  ),
                ),
              ],
            ),
          ),

          // 3. Debug/Count Text (Conditional)
          if (showCounter && !isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                "$completed/$goal",
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isComplete ? colors.done : colors.textSecondary),
              ),
            )
          else
            // Maintain layout height if hidden
            const SizedBox(height: 16),
        ],
      ),
    );
  }
}
