import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'task_model.g.dart';

// --- ENUMS ---
@HiveType(typeId: 10)
enum TaskType {
  @HiveField(0)
  normal,
  @HiveField(1)
  event,
  @HiveField(2)
  habit,
  @HiveField(3)
  reminder,
}

@HiveType(typeId: 11)
enum TaskViewType {
  @HiveField(0)
  slim,
  @HiveField(1)
  expanded,
}

@HiveType(typeId: 12)
enum TaskImportance {
  @HiveField(0)
  none,
  @HiveField(1)
  low,
  @HiveField(2)
  medium,
  @HiveField(3)
  high,
}

@HiveType(typeId: 3)
class TaskModel extends HiveObject {
  // --- CORE ---
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  bool isDone;

  @HiveField(3)
  String folderId;

  @HiveField(4)
  String sectionName;

  @HiveField(5)
  DateTime dateCreated;

  // --- CONTENT ---
  @HiveField(6)
  String? description;

  @HiveField(7)
  List<String>? checklist;

  // --- CONFIGURATION ---
  @HiveField(8)
  TaskType taskType;

  @HiveField(9)
  TaskViewType viewType;

  @HiveField(10)
  TaskImportance importance;

  @HiveField(11)
  bool showCategoryIcon;

  // --- METADATA ---
  @HiveField(12)
  DateTime? startTime;

  @HiveField(13)
  DateTime? endTime;

  @HiveField(14)
  String? location;

  @HiveField(15)
  int? habitStreak;

  @HiveField(16)
  int? habitGoal;

  // --- ANALYTICS ---
  @HiveField(17)
  DateTime? completedAt;

  @HiveField(18)
  bool isArchived;

  @HiveField(19)
  int? focusSeconds;

  // --- TASK 2.0 FIELDS ---
  @HiveField(20)
  bool isPinned;

  @HiveField(21)
  String? parentId;

  @HiveField(22)
  DateTime? endDate;

  @HiveField(23)
  bool isHabit;

  @HiveField(24)
  List<DateTime>? completedHistory;

  @HiveField(25)
  bool isStreakCount;

  @HiveField(26)
  bool showSmartPopup;

  // --- NEW: TIME CONSTRAINTS & FOCUS (PHASE 1) ---
  @HiveField(27)
  DateTime? reminderTime;

  @HiveField(28)
  DateTime? activePeriodStart; // "Active from..."

  @HiveField(29)
  DateTime? activePeriodEnd; // "...until"

  @HiveField(30)
  int? durationMinutes; // "Requires Focus Mode"

  // --- NEW: SMART RECURRENCE (PHASE 2) ---
  @HiveField(31)
  String? recurrenceRule; // e.g., "DAILY", "WEEKLY:FRI"

  TaskModel({
    required this.id,
    required this.title,
    this.isDone = false,
    required this.folderId,
    required this.sectionName,
    required this.dateCreated,
    this.description,
    this.checklist,
    this.taskType = TaskType.normal,
    this.viewType = TaskViewType.slim,
    this.importance = TaskImportance.none,
    this.showCategoryIcon = false,
    this.startTime,
    this.endTime,
    this.location,
    this.habitStreak,
    this.habitGoal,
    this.completedAt,
    this.isArchived = false,
    this.focusSeconds,
    this.isPinned = false,
    this.parentId,
    this.endDate,
    this.isHabit = false,
    this.completedHistory,
    this.isStreakCount = false,
    this.showSmartPopup = false,
    // Phase 1 Fields
    this.reminderTime,
    this.activePeriodStart,
    this.activePeriodEnd,
    this.durationMinutes,
    // Phase 2 Fields
    this.recurrenceRule,
  });

  // --- LOGIC ---

  bool isCompletedOn(DateTime date) {
    if (!isHabit) return isDone;
    if (completedHistory == null || completedHistory!.isEmpty) return false;
    return completedHistory!.any((d) =>
        d.year == date.year && d.month == date.month && d.day == date.day);
  }

  bool get isCompletedToday => isCompletedOn(DateTime.now());

  bool get isGoalMet {
    if (!isHabit || habitGoal == null || habitGoal == 0) return false;
    int current =
        isStreakCount ? (habitStreak ?? 0) : (completedHistory?.length ?? 0);
    return current >= habitGoal!;
  }

  String? get startTimeString {
    if (startTime == null) return null;
    final hour = startTime!.hour;
    final minute = startTime!.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return "$h:$minute $period";
  }

  // --- NEW LOGIC (PHASE 1) ---

  // 1. Is this a "Focus Mode Only" task?
  bool get requiresFocusMode => durationMinutes != null && durationMinutes! > 0;

  // 2. Is the task "Locked" due to time period?
  bool get isLocked {
    if (activePeriodStart == null || activePeriodEnd == null) return false;
    if (isDone) return false;

    final now = DateTime.now();
    final allowableEnd = activePeriodEnd!.add(const Duration(minutes: 30));

    return now.isBefore(activePeriodStart!) || now.isAfter(allowableEnd);
  }

  static TaskModel create({
    required String title,
    required String folderId,
    required String sectionName,
    TaskType type = TaskType.normal,
    String? parentId,
  }) {
    return TaskModel(
      id: const Uuid().v4(),
      title: title,
      folderId: folderId,
      sectionName: sectionName,
      dateCreated: DateTime.now(),
      taskType: type,
      parentId: parentId,
      isHabit: type == TaskType.habit,
    );
  }

  TaskModel copyWith({
    String? title,
    bool? isDone,
    String? description,
    List<String>? checklist,
    TaskType? taskType,
    TaskViewType? viewType,
    TaskImportance? importance,
    bool? showCategoryIcon,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    int? habitStreak,
    int? habitGoal,
    DateTime? completedAt,
    bool? isArchived,
    int? focusSeconds,
    bool? isPinned,
    String? parentId,
    DateTime? endDate,
    bool? isHabit,
    List<DateTime>? completedHistory,
    bool? isStreakCount,
    bool? showSmartPopup,
    // Phase 1 Fields
    DateTime? reminderTime,
    DateTime? activePeriodStart,
    DateTime? activePeriodEnd,
    int? durationMinutes,
    // Phase 2 Fields
    String? recurrenceRule,
  }) {
    return TaskModel(
      id: id,
      folderId: folderId,
      sectionName: sectionName,
      dateCreated: dateCreated,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      description: description ?? this.description,
      checklist: checklist ?? this.checklist,
      taskType: taskType ?? this.taskType,
      viewType: viewType ?? this.viewType,
      importance: importance ?? this.importance,
      showCategoryIcon: showCategoryIcon ?? this.showCategoryIcon,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      habitStreak: habitStreak ?? this.habitStreak,
      habitGoal: habitGoal ?? this.habitGoal,
      completedAt: completedAt ?? this.completedAt,
      isArchived: isArchived ?? this.isArchived,
      focusSeconds: focusSeconds ?? this.focusSeconds,
      isPinned: isPinned ?? this.isPinned,
      parentId: parentId ?? this.parentId,
      endDate: endDate ?? this.endDate,
      isHabit: isHabit ?? this.isHabit,
      completedHistory: completedHistory ?? this.completedHistory,
      isStreakCount: isStreakCount ?? this.isStreakCount,
      showSmartPopup: showSmartPopup ?? this.showSmartPopup,
      // Assignments
      reminderTime: reminderTime ?? this.reminderTime,
      activePeriodStart: activePeriodStart ?? this.activePeriodStart,
      activePeriodEnd: activePeriodEnd ?? this.activePeriodEnd,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
    );
  }
}
