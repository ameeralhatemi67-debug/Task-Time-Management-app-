import '../models/task_model.dart';
import '../models/task_folder_model.dart';
import '../../../data/repositories/task_repository.dart';

// --- CENTRALIZED ENUMS ---
enum TaskSortOption { importance, dateNewest, dateOldest, alphabetical }

enum SidebarItemType { all, archived, folder }

class TaskViewController {
  final TaskRepository _repo = TaskRepository();

  /// Main Calculation Engine
  ({List<TaskModel> active, List<TaskModel> overdue, List<TaskModel> done})
      calculateTaskLists({
    required SidebarItemType sidebarType,
    required List<TaskFolder> folders,
    required int currentFolderIndex,
    required int currentSectionIndex,
    required DateTime selectedDate,
    required TaskSortOption sortOption,
  }) {
    // 1. Fetch Source Tasks based on Navigation
    List<TaskModel> sourceTasks = [];

    if (sidebarType == SidebarItemType.all) {
      sourceTasks = _repo.getAll().where((t) => !t.isArchived).toList();
    } else if (sidebarType == SidebarItemType.archived) {
      sourceTasks = _repo.getAll().where((t) => t.isArchived).toList();
    } else if (folders.isNotEmpty && currentFolderIndex < folders.length) {
      final folder = folders[currentFolderIndex];
      if (currentSectionIndex != -1 &&
          currentSectionIndex < folder.sections.length) {
        final section = folder.sections[currentSectionIndex];
        sourceTasks = _repo
            .getAllTasksInFolder(folder.id)
            .where((t) => t.sectionName == section && !t.isArchived)
            .toList();
      } else {
        sourceTasks = _repo
            .getAllTasksInFolder(folder.id)
            .where((t) => !t.isArchived)
            .toList();
      }
    }

    // 2. Filter by Date & Status
    final selectedDayStart =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final selectedDayEnd = selectedDayStart.add(const Duration(days: 1));
    final thirtyDaysAgo = selectedDayStart.subtract(const Duration(days: 30));

    List<TaskModel> active = [];
    List<TaskModel> overdue = [];
    List<TaskModel> done = [];

    for (var task in sourceTasks) {
      // --- ARCHIVED VIEW EXCEPTION ---
      if (sidebarType == SidebarItemType.archived) {
        if (task.isDone) {
          done.add(task);
        } else {
          active.add(task);
        }
        continue;
      }

      // --- STANDARD VIEW LOGIC ---
      if (task.isDone) {
        if (task.isHabit) {
          if (task.isCompletedOn(selectedDate)) done.add(task);
        } else if (task.completedAt != null) {
          final comp = task.completedAt!;
          if ((comp.isAfter(selectedDayStart) &&
                  comp.isBefore(selectedDayEnd)) ||
              _isSameDay(comp, selectedDayStart)) {
            done.add(task);
          }
        }
        continue;
      }

      // --- Active / Overdue Logic ---
      if (task.isHabit) {
        if (task.dateCreated.isBefore(selectedDayEnd)) active.add(task);
        continue;
      }

      if (task.startTime == null) {
        active.add(task);
        continue;
      }

      final start = DateTime(
          task.startTime!.year, task.startTime!.month, task.startTime!.day);
      DateTime end = start;
      if (task.endDate != null) {
        end = DateTime(
            task.endDate!.year, task.endDate!.month, task.endDate!.day);
      }

      // Overdue Check
      if (end.isBefore(selectedDayStart)) {
        if (end.isAfter(thirtyDaysAgo)) overdue.add(task);
        continue;
      }

      // Active Check
      if (start.isBefore(selectedDayEnd)) {
        active.add(task);
      }
    }

    // 3. Sort
    active.sort((a, b) => _getSortComparator(a, b, sortOption));

    // Overdue always sorted by date (most urgent first)
    overdue.sort((a, b) => (a.endTime ?? a.startTime ?? a.dateCreated)
        .compareTo(b.endTime ?? b.startTime ?? b.dateCreated));

    // Done always sorted by completion time (most recent first)
    done.sort((a, b) => (b.completedAt ?? DateTime.now())
        .compareTo(a.completedAt ?? DateTime.now()));

    return (active: active, overdue: overdue, done: done);
  }

  /// Helper: Sort Comparator
  int _getSortComparator(TaskModel a, TaskModel b, TaskSortOption option) {
    // 1. Pinned always on top
    if (a.isPinned && !b.isPinned) return -1;
    if (!a.isPinned && b.isPinned) return 1;

    // 2. Specific Sorts
    switch (option) {
      case TaskSortOption.importance:
        // High(3) > Low(1). So Descending order of index.
        final cmp = b.importance.index.compareTo(a.importance.index);
        return cmp != 0 ? cmp : b.dateCreated.compareTo(a.dateCreated);

      case TaskSortOption.dateNewest:
        return b.dateCreated.compareTo(a.dateCreated); // Newest First

      case TaskSortOption.dateOldest:
        return a.dateCreated.compareTo(b.dateCreated); // Oldest First

      case TaskSortOption.alphabetical:
        return a.title.toLowerCase().compareTo(b.title.toLowerCase()); // A-Z
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
