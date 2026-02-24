import '../../features/tasks/models/task_model.dart';
import '../../features/tasks/models/task_folder_model.dart';
import '../../core/services/storage_service.dart';
import '../../features/smart_add/services/keyword_service.dart'; // <--- NEW: Link to the Brain
import 'base_repository.dart';
import 'package:hive/hive.dart';

class TaskRepository extends BaseRepository<TaskModel> {
  @override
  Box<TaskModel> get box => StorageService.instance.taskBox;

  final _folderBox = StorageService.instance.taskFolderBox;

  // ---------------------------------------------------------------------------
  // 1. BASIC CRUD & HYBRID TOGGLE
  // ---------------------------------------------------------------------------

  Future<void> addTask(TaskModel task) async {
    // 1. CRITICAL: Save the task FIRST. Ensure data integrity.
    await save(task.id, task);

    // 2. NEW: Silent Learning (The Teacher)
    // We fire and forget. We don't want AI learning to slow down the UI.
    try {
      // Only learn if the folder isn't default
      if (task.folderId != 'default') {
        await KeywordService.instance
            .learnCorrection(task.title, task.folderId);
      }
    } catch (e) {
      // Fail silently. The user's task is saved, that's what matters.
      print("SmartLearning Error: $e");
    }
  }

  /// THE HYBRID TOGGLE ENGINE
  Future<void> toggleTask(TaskModel task) async {
    final now = DateTime.now();

    if (task.isHabit) {
      // --- HABIT LOGIC ---
      task.completedHistory ??= [];

      // Check if already done today
      // Logic: If user clicks check, we toggle 'Today' in the history.
      final index = task.completedHistory!.indexWhere((d) =>
          d.year == now.year && d.month == now.month && d.day == now.day);

      if (index != -1) {
        // Undo: Remove today
        task.completedHistory!.removeAt(index);
      } else {
        // Do: Add today
        task.completedHistory!.add(now);
      }

      // Recalculate Streak
      task.habitStreak = _calculateStreak(task.completedHistory!);

      // Check Goal: If reached, mark global isDone = true
      if (task.habitGoal != null && task.habitGoal! > 0) {
        // Use model helper to determine if we crossed the finish line
        if (task.isGoalMet) {
          task.isDone = true;
        } else {
          task.isDone = false;
        }
      } else {
        // If no goal, it's never "fully done", just done for today.
        task.isDone = false;
      }

      // Update completion timestamp for sorting
      task.completedAt = DateTime.now();
    } else {
      // --- NORMAL TASK LOGIC ---
      task.isDone = !task.isDone;
      if (task.isDone) {
        task.completedAt = DateTime.now();
      } else {
        task.completedAt = null;
      }
    }

    await save(task.id, task);
  }

  // --- REPEAT & RESTART LOGIC ---

  // 1. REPEAT: Creates a fresh copy of the task (Undone, Clean Slate)
  Future<void> repeatTask(TaskModel original) async {
    final newTask = TaskModel.create(
      title: original.title,
      folderId: original.folderId,
      sectionName: original.sectionName,
      type: original.taskType,
      parentId: original.parentId,
    ).copyWith(
      description: original.description,
      checklist:
          original.checklist != null ? List.from(original.checklist!) : null,
      viewType: original.viewType,
      importance: original.importance,
      showCategoryIcon: original.showCategoryIcon,
      // Copy Configs
      startTime: original.startTime,
      endTime: original.endTime,
      location: original.location,
      endDate: original.endDate,
      habitGoal: original.habitGoal,
      isHabit: original.isHabit,
      isStreakCount: original.isStreakCount,
      showSmartPopup: original.showSmartPopup,
      // Time Fields
      reminderTime: original.reminderTime,
      activePeriodStart: original.activePeriodStart,
      activePeriodEnd: original.activePeriodEnd,
      durationMinutes: original.durationMinutes,
      // Recurrence
      recurrenceRule: original.recurrenceRule,
      // RESET STATE
      habitStreak: 0,
      completedHistory: [],
      completedAt: null,
      isDone: false,
      isArchived: false,
      focusSeconds: 0,
      isPinned: false,
    );

    await addTask(newTask);
  }

  // 2. RESTART: Like Repeat, but shifts time-based tasks to "Tomorrow"
  Future<void> restartTask(TaskModel original) async {
    // Start with a clean copy
    var newTask = TaskModel.create(
      title: original.title,
      folderId: original.folderId,
      sectionName: original.sectionName,
      type: original.taskType,
      parentId: original.parentId,
    ).copyWith(
      description: original.description,
      checklist:
          original.checklist != null ? List.from(original.checklist!) : null,
      viewType: original.viewType,
      importance: original.importance,
      showCategoryIcon: original.showCategoryIcon,
      location: original.location,
      durationMinutes: original.durationMinutes,
      isHabit: original.isHabit,
      habitGoal: original.habitGoal,
      isStreakCount: original.isStreakCount,
      showSmartPopup: original.showSmartPopup,
      recurrenceRule: original.recurrenceRule,
      // Reset State
      habitStreak: 0,
      completedHistory: [],
      completedAt: null,
      isDone: false,
      isArchived: false,
      focusSeconds: 0,
      isPinned: false,
    );

    // LOGIC: If it's a Reminder/Time-Based, shift dates to Tomorrow
    if (original.taskType == TaskType.reminder ||
        original.startTime != null ||
        original.reminderTime != null ||
        original.activePeriodStart != null) {
      final now = DateTime.now();
      // Helper: Same time, but tomorrow
      DateTime shift(DateTime dt) {
        final tomorrow = now.add(const Duration(days: 1));
        return DateTime(
            tomorrow.year, tomorrow.month, tomorrow.day, dt.hour, dt.minute);
      }

      if (original.startTime != null)
        newTask.startTime = shift(original.startTime!);
      if (original.endTime != null) newTask.endTime = shift(original.endTime!);
      if (original.endDate != null) newTask.endDate = shift(original.endDate!);
      if (original.reminderTime != null)
        newTask.reminderTime = shift(original.reminderTime!);
      if (original.activePeriodStart != null)
        newTask.activePeriodStart = shift(original.activePeriodStart!);
      if (original.activePeriodEnd != null)
        newTask.activePeriodEnd = shift(original.activePeriodEnd!);
    }

    await addTask(newTask);
  }

  // --- STREAK HELPERS ---

  int _calculateStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;
    // Sort newest first
    dates.sort((a, b) => b.compareTo(a));

    int streak = 0;
    // Start checking from Today
    DateTime checkDate = DateTime.now();
    checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day);

    // If today is NOT done, check if Yesterday was done to keep streak alive
    if (dates.isEmpty || !_isSameDay(dates.first, checkDate)) {
      final yesterday = checkDate.subtract(const Duration(days: 1));
      // If newest entry is not today AND not yesterday, streak is broken
      // (Unless list is empty which we handled)
      bool hasYesterday = dates.any((d) => _isSameDay(d, yesterday));

      if (!hasYesterday) {
        // Check if newest date is actually today (handled by first if) or yesterday
        // If dates.first is older than yesterday, streak is 0.
        if (dates.first.isBefore(yesterday)) return 0;
      }

      // If we are here, it means we don't have today, but we might have yesterday.
      // So we start counting from yesterday.
      checkDate = yesterday;
    }

    // Simple consecutive check
    for (var date in dates) {
      if (_isSameDay(date, checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    }
    return streak;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> deleteTask(String id) async {
    final subtasks = getSubtasks(id);
    for (var sub in subtasks) {
      await delete(sub.id);
    }
    await delete(id);
  }

  Future<void> togglePin(TaskModel task) async {
    task.isPinned = !task.isPinned;
    await save(task.id, task);
  }

  // ---------------------------------------------------------------------------
  // 2. QUERY METHODS
  // ---------------------------------------------------------------------------

  List<TaskModel> getTasks(String folderId, String sectionName) {
    final tasks = getAll()
        .where((t) =>
            t.folderId == folderId &&
            t.sectionName == sectionName &&
            !t.isArchived &&
            t.parentId == null)
        .toList();

    tasks.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.dateCreated.compareTo(a.dateCreated);
    });

    return tasks;
  }

  List<TaskModel> getSubtasks(String parentId) {
    final tasks =
        getAll().where((t) => t.parentId == parentId && !t.isArchived).toList();
    tasks.sort((a, b) => a.dateCreated.compareTo(b.dateCreated));
    return tasks;
  }

  List<TaskModel> getAllTasksInFolder(String folderId) {
    return getAll().where((t) => t.folderId == folderId).toList();
  }

  // ---------------------------------------------------------------------------
  // 3. CALENDAR INTELLIGENCE
  // ---------------------------------------------------------------------------

  int getIndicatorStatusForDay(DateTime date) {
    final tasks = getTasksForDay(date);
    if (tasks.isEmpty) return 0;

    bool hasHighPriority =
        tasks.any((t) => t.importance == TaskImportance.high && !t.isDone);
    if (hasHighPriority) return -1;

    return tasks.length;
  }

  /// Used by Calendar Dots Logic & Task Lists
  List<TaskModel> getTasksForDay(DateTime date) {
    return getAll().where((t) {
      if (t.isArchived || t.parentId != null) return false;

      // 1. HABITS LOGIC (Updated for Smart Recurrence)
      if (t.isHabit) {
        // A. If Habit is "Fully Done" (Goal met), only show on completed days
        if (t.isDone) {
          return t.isCompletedOn(date);
        }

        // B. Check Start Date
        // If the date is before the habit was created, don't show it
        final startOfCreation = DateTime(
            t.dateCreated.year, t.dateCreated.month, t.dateCreated.day);
        final checkDate = DateTime(date.year, date.month, date.day);

        if (checkDate.isBefore(startOfCreation)) return false;

        // C. Check Recurrence Rule
        if (t.recurrenceRule != null) {
          // "WEEKLY:FRI" -> Split to get "FRI"
          if (t.recurrenceRule!.startsWith("WEEKLY:")) {
            final dayCode = t.recurrenceRule!.split(":")[1]; // "FRI"
            final dayMap = {
              "MON": 1,
              "TUE": 2,
              "WED": 3,
              "THU": 4,
              "FRI": 5,
              "SAT": 6,
              "SUN": 7
            };

            // If the weekday matches, show it. Otherwise hide it.
            if (date.weekday != dayMap[dayCode]) return false;
          }
          // "WEEKLY" (Generic) -> User probably meant once a week, but we default to show it?
          // For now, let's treat generic "WEEKLY" as show every day (or you can decide logic).
          // "DAILY" -> Show every day (Default)
        }

        return true;
      }

      // 2. Date Range (Normal Tasks)
      if (t.startTime != null) {
        final start =
            DateTime(t.startTime!.year, t.startTime!.month, t.startTime!.day);
        final check = DateTime(date.year, date.month, date.day);

        if (t.endDate != null) {
          final end =
              DateTime(t.endDate!.year, t.endDate!.month, t.endDate!.day);
          return (check.isAtSameMomentAs(start) || check.isAfter(start)) &&
              (check.isAtSameMomentAs(end) || check.isBefore(end));
        } else {
          return check.isAtSameMomentAs(start);
        }
      }
      return false;
    }).toList();
  }

  // Folder ops... (Unchanged)
  List<TaskFolder> getFolders() => _folderBox.values.toList()
    ..sort((a, b) => a.dateCreated.compareTo(b.dateCreated));
  Future<void> saveFolder(TaskFolder f) async => await _folderBox.put(f.id, f);
  Future<void> deleteFolder(String id) async => await _folderBox.delete(id);
  Future<void> addSection(TaskFolder f, String n) async {
    if (!f.sections.contains(n)) {
      f.sections.add(n);
      await saveFolder(f);
    }
  }

  // --- NEW: AUTO ARCHIVING LOGIC ---
  Future<void> runAutoArchiving() async {
    final now = DateTime.now();
    bool changed = false;

    for (var task in getAll()) {
      if (task.isArchived) continue; // Already archived

      bool shouldArchive = false;

      // RULE 1: Finished tasks > 2 days ago
      if (task.isDone && task.completedAt != null) {
        final diff = now.difference(task.completedAt!).inDays;
        if (diff >= 2) {
          shouldArchive = true;
        }
      }

      // RULE 2: Unfinished tasks > 1 week old (7 days)
      // Note: We use dateCreated for simplicity.
      // Ideally, check for overdue, but dateCreated ensures old stale tasks get cleaned.
      if (!task.isDone) {
        final diff = now.difference(task.dateCreated).inDays;
        if (diff >= 7) {
          shouldArchive = true;
        }
      }

      if (shouldArchive) {
        task.isArchived = true;
        await box.put(task.id, task);
        changed = true;
      }
    }

    if (changed) {
      // Notify listeners if necessary (Hive ValueListenable handles this automatically)
    }
  }
}
