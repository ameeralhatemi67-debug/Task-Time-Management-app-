import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'habit_model.g.dart';

@HiveType(typeId: 0)
class HabitModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  String typeString;

  @HiveField(4)
  int streakGoal;

  @HiveField(5)
  List<DateTime> completedDaysList;

  @HiveField(6)
  List<int> scheduledWeekdays;

  @HiveField(7)
  DateTime startDate;

  @HiveField(8)
  DateTime? endDate;

  @HiveField(9)
  String? startTimeString;

  @HiveField(10)
  String? endTimeString;

  @HiveField(11)
  String? folderId;

  @HiveField(12)
  bool? isArchived;

  @HiveField(13)
  String? importanceString;

  @HiveField(14)
  String? reminderTimeString;

  @HiveField(15)
  String? activePeriodStartString;

  @HiveField(16)
  String? activePeriodEndString;

  @HiveField(17)
  int? durationMinutes;

  @HiveField(18)
  String? statusString;

  @HiveField(19)
  List<DateTime>? targetDates;

  @HiveField(20)
  String? durationModeString;

  // Added defaultValue to prevent migration crashes
  @HiveField(21, defaultValue: false)
  bool isPinned;

  HabitModel({
    required this.id,
    required this.title,
    required this.description,
    required this.typeString,
    required this.streakGoal,
    required this.completedDaysList,
    this.scheduledWeekdays = const [],
    required this.startDate,
    this.endDate,
    this.startTimeString,
    this.endTimeString,
    this.folderId,
    this.isArchived,
    this.importanceString,
    this.reminderTimeString,
    this.activePeriodStartString,
    this.activePeriodEndString,
    this.durationMinutes,
    this.statusString,
    this.targetDates,
    this.durationModeString,
    this.isPinned = false,
  });

  // --- GETTERS & LOGIC ---

  HabitType get type {
    return HabitType.values.firstWhere(
      (e) => e.name == typeString,
      orElse: () => HabitType.weekly,
    );
  }

  HabitImportance get importance {
    final value = importanceString ?? 'none';
    return HabitImportance.values.firstWhere(
      (e) => e.name == value,
      orElse: () => HabitImportance.none,
    );
  }

  HabitStatus get status {
    final value = statusString ?? HabitStatus.active.name;
    return HabitStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => HabitStatus.active,
    );
  }

  HabitDurationMode get durationMode {
    final value = durationModeString ?? HabitDurationMode.anyTime.name;
    return HabitDurationMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => HabitDurationMode.anyTime,
    );
  }

  List<DateTime> get safeTargetDates => targetDates ?? [];

  // Used by yearly_habit_card.dart (in Slidable actions)
  bool get archived => isArchived ?? false;

  Set<DateTime> get completedDays => completedDaysList.toSet();

  // Time Helpers
  TimeOfDay? get startTime => _parseTime(startTimeString);
  TimeOfDay? get endTime => _parseTime(endTimeString);
  TimeOfDay? get reminderTime => _parseTime(reminderTimeString);
  TimeOfDay? get activePeriodStart => _parseTime(activePeriodStartString);
  TimeOfDay? get activePeriodEnd => _parseTime(activePeriodEndString);

  // --- LOCKING LOGIC (Preserved Exactly) ---
  bool get isLocked {
    if (durationMode != HabitDurationMode.fixedWindow) return false;
    if (activePeriodStart == null || activePeriodEnd == null) return false;

    final now = TimeOfDay.now();
    final start = activePeriodStart!;
    final end = activePeriodEnd!;

    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes <= endMinutes) {
      return nowMinutes < startMinutes || nowMinutes > endMinutes;
    } else {
      return nowMinutes > endMinutes && nowMinutes < startMinutes;
    }
  }

  TimeOfDay? _parseTime(String? s) {
    if (s == null || !s.contains(":")) return null;
    final parts = s.split(":");
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String? _formatTime(TimeOfDay? t) {
    if (t == null) return null;
    return "${t.hour}:${t.minute}";
  }

  // --- DATE HELPERS (FIXED) ---

  // Helper to compare dates ignoring time
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void toggleCompletion(DateTime date) {
    if (isLocked) return;

    // Use specific date check logic
    final exists = completedDaysList.any((d) => _isSameDay(d, date));

    if (exists) {
      completedDaysList.removeWhere((d) => _isSameDay(d, date));
    } else {
      // Add as midnight to keep clean
      completedDaysList.add(DateTime(date.year, date.month, date.day));
    }
    save();
  }

  bool isCompletedOn(DateTime date) {
    // FIXED: Use any() to check date parts instead of exact equality
    return completedDaysList.any((d) => _isSameDay(d, date));
  }

  bool isScheduledOn(DateTime date) {
    final cleanDate = DateTime(date.year, date.month, date.day);
    final cleanStart = DateTime(startDate.year, startDate.month, startDate.day);

    if (cleanDate.isBefore(cleanStart)) return false;

    if (endDate != null) {
      final cleanEnd = DateTime(endDate!.year, endDate!.month, endDate!.day);
      if (cleanDate.isAfter(cleanEnd)) return false;
    }

    if (safeTargetDates.isNotEmpty) {
      return safeTargetDates.any((d) => _isSameDay(d, date));
    }

    if (type == HabitType.weekly && scheduledWeekdays.isNotEmpty) {
      return scheduledWeekdays.contains(date.weekday);
    }

    // Default for Daily/others without specific schedules
    return true;
  }

  // --- NEW: STREAK CALCULATION (Added on top) ---
  int get currentStreak {
    int streak = 0;
    final now = DateTime.now();
    DateTime cursor = DateTime(now.year, now.month, now.day);

    // Look back up to 5 years
    for (int i = 0; i < 365 * 5; i++) {
      if (isScheduledOn(cursor)) {
        if (isCompletedOn(cursor)) {
          streak++;
        } else {
          // If it's today and not done yet, don't break streak
          if (!_isSameDay(cursor, now)) {
            break;
          }
        }
      }
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // --- FACTORY ---
  static HabitModel create({
    required String title,
    String description = '',
    HabitType type = HabitType.weekly,
    int streakGoal = 3,
    List<int> scheduledWeekdays = const [1, 2, 3, 4, 5],
    DateTime? startDate,
    DateTime? endDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? folderId,
    HabitImportance importance = HabitImportance.none,
  }) {
    return HabitModel(
      id: const Uuid().v4(),
      title: title,
      description: description,
      typeString: type.name,
      streakGoal: streakGoal,
      completedDaysList: [],
      scheduledWeekdays: scheduledWeekdays,
      startDate: startDate ?? DateTime.now(),
      endDate: endDate,
      startTimeString:
          startTime != null ? "${startTime.hour}:${startTime.minute}" : null,
      endTimeString:
          endTime != null ? "${endTime.hour}:${endTime.minute}" : null,
      folderId: folderId,
      isArchived: false,
      isPinned: false,
      importanceString: importance.name,
      statusString: HabitStatus.active.name,
      durationModeString: HabitDurationMode.anyTime.name,
      targetDates: [],
    );
  }

  // --- COPY WITH ---
  HabitModel copyWith({
    String? title,
    String? description,
    String? typeString,
    int? streakGoal,
    List<DateTime>? completedDaysList,
    List<int>? scheduledWeekdays,
    DateTime? startDate,
    DateTime? endDate,
    String? startTimeString,
    String? endTimeString,
    String? folderId,
    bool? isArchived,
    bool? isPinned,
    HabitImportance? importance,
    TimeOfDay? reminderTime,
    TimeOfDay? activePeriodStart,
    TimeOfDay? activePeriodEnd,
    int? durationMinutes,
    HabitStatus? status,
    List<DateTime>? targetDates,
    HabitDurationMode? durationMode,
  }) {
    return HabitModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      typeString: typeString ?? this.typeString,
      streakGoal: streakGoal ?? this.streakGoal,
      completedDaysList: completedDaysList ?? List.from(this.completedDaysList),
      scheduledWeekdays: scheduledWeekdays ?? List.from(this.scheduledWeekdays),
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startTimeString: startTimeString ?? this.startTimeString,
      endTimeString: endTimeString ?? this.endTimeString,
      folderId: folderId ?? this.folderId,
      isArchived: isArchived ?? this.isArchived,
      isPinned: isPinned ?? this.isPinned,
      importanceString: importance?.name ?? this.importanceString,
      reminderTimeString: reminderTime != null
          ? _formatTime(reminderTime)
          : this.reminderTimeString,
      activePeriodStartString: activePeriodStart != null
          ? _formatTime(activePeriodStart)
          : this.activePeriodStartString,
      activePeriodEndString: activePeriodEnd != null
          ? _formatTime(activePeriodEnd)
          : this.activePeriodEndString,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      statusString: status?.name ?? this.statusString,
      targetDates: targetDates ??
          (this.targetDates != null ? List.from(this.targetDates!) : []),
      durationModeString: durationMode?.name ?? this.durationModeString,
    );
  }
}

// --- ENUMS ---

enum HabitType { weekly, monthly, yearly }

enum HabitImportance { none, low, medium, high }

enum HabitStatus { active, completed, failed }

enum HabitDurationMode { anyTime, fixedWindow, focusTimer }
