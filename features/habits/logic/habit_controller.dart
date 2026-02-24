import 'package:flutter/material.dart';
import '../models/habit_model.dart';

class HabitController extends ChangeNotifier {
  // --- STATE ---
  Set<DateTime> _completedDays = {};

  // Single-level undo stack (Restore Point)
  // Stores a snapshot of _completedDays before the last destructive action
  List<DateTime> _undoStack = [];

  // --- GETTERS ---
  Set<DateTime> get completedDays => _completedDays;
  int get completionCount => _completedDays.length;

  // --- INITIALIZATION ---
  void initialize({HabitModel? habit}) {
    if (habit != null) {
      _completedDays = Set.from(habit.completedDaysList);
    } else {
      _completedDays = {};
    }
    _undoStack = [];
    notifyListeners(); // Update UI immediately
  }

  // --- HISTORY MANIPULATION ---

  void toggleDate(DateTime date) {
    _saveStateForUndo();
    final clean = DateTime(date.year, date.month, date.day);
    if (_completedDays.contains(clean)) {
      _completedDays.remove(clean);
    } else {
      _completedDays.add(clean);
    }
    notifyListeners();
  }

  void _saveStateForUndo() {
    _undoStack = List.from(_completedDays);
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    // Restore the state from the stack
    _completedDays = _undoStack.toSet();
    notifyListeners();
  }

  void resetProgress() {
    _saveStateForUndo();
    _completedDays.clear();
    notifyListeners();
  }

  // --- PROGRESS SIMULATION (Time Travel) ---

  /// Revert = -1 Week of Progress
  /// Removes the latest N entries where N = days per week
  void revertProgress(List<int> scheduledWeekdays) {
    if (_completedDays.isEmpty) return;
    _saveStateForUndo();

    final int daysPerWeek =
        scheduledWeekdays.isNotEmpty ? scheduledWeekdays.length : 7;

    // Sort completions to find the latest ones (Descending)
    List<DateTime> sorted = _completedDays.toList()
      ..sort((a, b) => b.compareTo(a));

    int toRemove = daysPerWeek;
    for (var date in sorted) {
      if (toRemove <= 0) break;
      _completedDays.remove(date);
      toRemove--;
    }
    notifyListeners();
  }

  /// Fast Forward = +1 Week of Progress
  /// Simulates 7 days passing and auto-completes scheduled days
  void fastForwardProgress({
    required List<int> scheduledWeekdays,
    required int streakGoal, // in Weeks
    required DateTime startDate,
  }) {
    final int daysPerWeek =
        scheduledWeekdays.isNotEmpty ? scheduledWeekdays.length : 7;

    // Goal Cap: Days per week * Weeks
    final int goalDays = daysPerWeek * streakGoal;

    if (_completedDays.length >= goalDays) return;

    _saveStateForUndo();

    // Start from last completion or start date
    DateTime cursor = _completedDays.isEmpty
        ? startDate.subtract(const Duration(days: 1))
        : _completedDays.reduce((a, b) => a.isAfter(b) ? a : b);

    // Simulate 7 calendar days passing
    for (int i = 0; i < 7; i++) {
      cursor = cursor.add(const Duration(days: 1));

      // If this day matches schedule, complete it
      // If schedule is empty (Daily), 1-5, 6-7 are irrelevant, we assume daily
      // NOTE: HabitModel uses 1=Mon, 7=Sun.
      bool isScheduled = scheduledWeekdays.isEmpty ||
          scheduledWeekdays.contains(cursor.weekday);

      if (isScheduled) {
        if (_completedDays.length < goalDays) {
          _completedDays.add(DateTime(cursor.year, cursor.month, cursor.day));
        }
      }
    }
    notifyListeners();
  }

  // --- DATE GENERATION HELPER ---

  /// Generates the physical list of target dates for Monthly habits
  /// strictly based on the user's selected "Monthly Days" (e.g., 1st, 15th)
  List<DateTime> generateMonthlyTargetDates({
    required DateTime startDate,
    required int streakGoal, // Months count for Monthly type
    required List<int> monthlyDays, // e.g. [1, 15]
  }) {
    List<DateTime> generated = [];
    DateTime cursor = startDate;

    for (int i = 0; i < streakGoal; i++) {
      for (int day in monthlyDays) {
        final int year = cursor.year;
        final int month = cursor.month;

        // Handle "30th of Feb" edge case by clamping to last day of month
        final int lastDayOfMonth = DateTime(year, month + 1, 0).day;
        final int validDay = day > lastDayOfMonth ? lastDayOfMonth : day;

        generated.add(DateTime(year, month, validDay));
      }
      // Move to next month
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    return generated;
  }
}
