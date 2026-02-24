import '../models/task_model.dart';

class HabitController {
  final TaskModel task;

  /// Stores a snapshot of the completedHistory for a single-step undo.
  List<DateTime> _undoStack = [];

  HabitController(this.task);

  // --- ACTIONS ---

  void toggleHistoryDate(DateTime date) {
    _saveStateForUndo();
    task.completedHistory ??= [];

    final checkDate = DateTime(date.year, date.month, date.day);

    // Check if this date exists in history
    final index = task.completedHistory!.indexWhere((d) =>
        d.year == checkDate.year &&
        d.month == checkDate.month &&
        d.day == checkDate.day);

    if (index != -1) {
      task.completedHistory!.removeAt(index);
    } else {
      task.completedHistory!.add(checkDate);
    }

    _updateStreak();
    task.save();
  }

  void resetProgress() {
    _saveStateForUndo();
    task.completedHistory?.clear();
    _updateStreak();
    task.save();
  }

  void revertProgress() {
    _saveStateForUndo();
    if (task.completedHistory != null && task.completedHistory!.isNotEmpty) {
      // Sort to remove the latest entries first
      task.completedHistory!.sort((a, b) => a.compareTo(b));

      // Remove up to 7 days (1 Tier Cycle)
      for (int i = 0; i < 7 && task.completedHistory!.isNotEmpty; i++) {
        task.completedHistory!.removeLast();
      }

      _updateStreak();
      task.save();
    }
  }

  void undoLastAction() {
    if (_undoStack.isEmpty) return;

    // Restore state from stack
    task.completedHistory = List.from(_undoStack);

    _updateStreak();
    task.save();
  }

  void addProgress() {
    _saveStateForUndo();
    task.completedHistory ??= [];
    final int currentCount = task.completedHistory!.length;

    // Add 7 dummy days for visual testing/progress
    for (int i = 0; i < 7; i++) {
      task.completedHistory!
          .add(DateTime(2000, 1, 1).add(Duration(days: currentCount + i)));
    }

    _updateStreak();
    task.save();
  }

  // --- HELPERS ---

  void _saveStateForUndo() {
    // Deep copy the current history
    _undoStack = List.from(task.completedHistory ?? []);
  }

  void _updateStreak() {
    if (task.completedHistory == null || task.completedHistory!.isEmpty) {
      task.habitStreak = 0;
      return;
    }

    final dates = task.completedHistory!;
    dates.sort((a, b) => b.compareTo(a)); // Newest first

    int streak = 0;
    DateTime checkDate = DateTime.now();
    checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day);

    // Logic: If today is missing, check yesterday to maintain streak
    if (!_isSameDay(dates.first, checkDate)) {
      final yesterday = checkDate.subtract(const Duration(days: 1));
      bool hasYesterday = dates.any((d) => _isSameDay(d, yesterday));

      if (!hasYesterday) {
        if (dates.first.isBefore(yesterday)) {
          task.habitStreak = 0;
          return;
        }
      } else {
        checkDate = yesterday;
      }
    }

    // Count consecutive days
    for (var date in dates) {
      if (_isSameDay(date, checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    }

    task.habitStreak = streak;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
