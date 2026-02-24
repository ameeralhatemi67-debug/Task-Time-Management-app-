import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import '../models/habit_model.dart';
import '../../../data/repositories/habit_repository.dart';

// --- LOGIC ---
import '../logic/habit_controller.dart';

// --- WIDGETS ---
import '../widgets/habit_basic_details.dart';
import '../widgets/habit_history_panel.dart';

// --- SERVICES & PAGES ---
import 'package:task_manager_app/core/services/notification_service.dart';
import 'package:task_manager_app/features/focus/pages/focus_page.dart';

class HabitFormPage extends StatefulWidget {
  final HabitModel? existingHabit;
  final String? initialFolderId;

  const HabitFormPage({
    super.key,
    this.existingHabit,
    this.initialFolderId,
  });

  @override
  State<HabitFormPage> createState() => _HabitFormPageState();
}

class _HabitFormPageState extends State<HabitFormPage> {
  final HabitRepository _repo = HabitRepository();
  late HabitController _controller;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  // --- 1. FORM STATE ---
  HabitType _selectedType = HabitType.weekly;
  int _streakGoal = 3;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  // Schedule
  List<int> _scheduledWeekdays = [1, 2, 3, 4, 5];
  List<DateTime> _targetDates = [];

  // FIX: Initialize with ALL 31 days by default for Monthly
  List<int> _monthlyDays = List.generate(31, (index) => index + 1);

  // Time & Details
  HabitImportance _importance = HabitImportance.none;
  HabitDurationMode _durationMode = HabitDurationMode.anyTime;
  TimeOfDay? _reminderTime;
  TimeOfDay? _activePeriodStart;
  TimeOfDay? _activePeriodEnd;
  int? _durationMinutes;

  @override
  void initState() {
    super.initState();
    _controller = HabitController();
    _controller.initialize(habit: widget.existingHabit);

    if (widget.existingHabit != null) {
      final h = widget.existingHabit!;
      _titleController.text = h.title;
      _descController.text = h.description;
      _selectedType = h.type;
      _streakGoal = h.streakGoal;
      _scheduledWeekdays = List.from(h.scheduledWeekdays);
      _startDate = h.startDate;
      _endDate = h.endDate;
      _importance = h.importance;
      _reminderTime = h.reminderTime;
      _activePeriodStart = h.activePeriodStart;
      _activePeriodEnd = h.activePeriodEnd;
      _durationMinutes = h.durationMinutes;
      _durationMode = h.durationMode;
      _targetDates = h.safeTargetDates;

      if (h.type == HabitType.monthly && _targetDates.isNotEmpty) {
        _monthlyDays = _targetDates.map((d) => d.day).toSet().toList();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // --- MODEL BUILDER ---
  HabitModel _buildHabitModel() {
    List<int> finalWeekdays = [];
    List<int> finalMonthlyDays = [];

    if (_selectedType == HabitType.weekly) {
      finalWeekdays = _scheduledWeekdays.isEmpty
          ? [1, 2, 3, 4, 5, 6, 7]
          : _scheduledWeekdays;
    }

    if (_selectedType == HabitType.monthly) {
      finalMonthlyDays =
          _monthlyDays.isEmpty ? List.generate(31, (i) => i + 1) : _monthlyDays;
    }

    List<DateTime>? finalTargetDates;
    if (_selectedType == HabitType.monthly) {
      finalTargetDates = _controller.generateMonthlyTargetDates(
        startDate: _startDate,
        streakGoal: _streakGoal,
        monthlyDays: finalMonthlyDays,
      );
    } else if (_selectedType == HabitType.yearly) {
      finalTargetDates = _targetDates;
    }

    // Ensure durationMinutes is set if in Focus Mode
    int? finalDurationMinutes = _durationMinutes;
    if (_durationMode == HabitDurationMode.focusTimer &&
        (finalDurationMinutes == null || finalDurationMinutes == 0)) {
      finalDurationMinutes = 30; // Default to 30 if missing
    }

    return HabitModel(
      id: widget.existingHabit?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      typeString: _selectedType.name,
      streakGoal: _streakGoal,
      completedDaysList: _controller.completedDays.toList(),
      scheduledWeekdays: finalWeekdays,
      startDate: _startDate,
      endDate: _endDate,
      folderId: widget.existingHabit?.folderId ?? widget.initialFolderId,
      isArchived: widget.existingHabit?.isArchived ?? false,
      isPinned: widget.existingHabit?.isPinned ?? false,
      importanceString: _importance.name,
      reminderTimeString: _formatTime(_reminderTime),
      activePeriodStartString: _formatTime(_activePeriodStart),
      activePeriodEndString: _formatTime(_activePeriodEnd),
      durationMinutes: finalDurationMinutes,
      statusString: HabitStatus.active.name,
      targetDates: finalTargetDates,
      durationModeString: _durationMode.name,
    );
  }

  // --- ACTIONS ---
  void _saveHabit() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a habit name")));
      return;
    }

    final newHabit = _buildHabitModel();
    await _repo.saveHabit(newHabit);

    final notificationId = newHabit.id.hashCode;
    if (newHabit.reminderTime != null) {
      await NotificationService().scheduleDaily(
        id: notificationId,
        title: "Reminder: ${newHabit.title}",
        body: "Time to build your habit!",
        time: newHabit.reminderTime!,
      );
    } else {
      await NotificationService().cancelNotification(notificationId);
    }

    if (mounted) Navigator.pop(context);
  }

  void _startFocusSession() {
    final habit = _buildHabitModel();
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => FocusPage(initialHabit: habit)));
  }

  // --- PROGRESS LOGIC ---
  int _calculateTotalGoal() {
    if (_selectedType == HabitType.weekly) {
      final int daysPerCycle =
          _scheduledWeekdays.isEmpty ? 7 : _scheduledWeekdays.length;
      return _streakGoal * daysPerCycle;
    } else if (_selectedType == HabitType.monthly) {
      final int daysPerCycle = _monthlyDays.isEmpty ? 30 : _monthlyDays.length;
      return _streakGoal * daysPerCycle;
    } else {
      final int daysPerCycle = _targetDates.isEmpty ? 365 : _targetDates.length;
      return _streakGoal * daysPerCycle;
    }
  }

  void _updateProgress(int amount) {
    if (amount > 0) {
      final int totalGoal = _calculateTotalGoal();
      final int current = _controller.completionCount;
      if (current >= totalGoal) return;

      int added = 0;
      DateTime cursor = _startDate;
      for (int i = 0; i < 365 * 5; i++) {
        if (added >= amount || (current + added) >= totalGoal) break;
        final d = DateTime(cursor.year, cursor.month, cursor.day);
        bool alreadyDone = _controller.completedDays.any((done) =>
            done.year == d.year && done.month == d.month && done.day == d.day);
        if (!alreadyDone) {
          _controller.toggleDate(d);
          added++;
        }
        cursor = cursor.add(const Duration(days: 1));
      }
    }
  }

  void _removeRecentProgress(int amount) {
    int removed = 0;
    final sorted = _controller.completedDays.toList()
      ..sort((a, b) => b.compareTo(a));

    for (var date in sorted) {
      if (removed >= amount) break;
      _controller.toggleDate(date);
      removed++;
    }
  }

  String? _formatTime(TimeOfDay? t) =>
      t == null ? null : "${t.hour}:${t.minute}";

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final bool showFocusBtn = _durationMode == HabitDurationMode.focusTimer ||
        _durationMode == HabitDurationMode.fixedWindow;

    final int totalGoal = _calculateTotalGoal();

    return Scaffold(
      backgroundColor: colors.bgMain,
      appBar: AppBar(
        backgroundColor: colors.bgMain,
        elevation: 0,
        // Move title closer to leading arrow
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        // Align title to left
        centerTitle: false,
        title: Text(
          widget.existingHabit == null ? "New Habit" : "Edit Habit",
          style: TextStyle(color: colors.textMain, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (showFocusBtn)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GestureDetector(
                onTap: _startFocusSession,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    // EXACT DESIGN FROM WEEKLY CARD
                    color: colors.focusLink.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                    border:
                        Border.all(color: colors.focusLink.withOpacity(0.5)),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.filter_center_focus,
                          size: 14, color: colors.focusLink),
                      const SizedBox(width: 4),
                      Text(
                        "Start Focus Session",
                        style: TextStyle(
                          color: colors.focusLink,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          children: [
            HabitBasicDetails(
              colors: colors,
              titleController: _titleController,
              descController: _descController,
              selectedType: _selectedType,
              streakGoal: _streakGoal,
              scheduledWeekdays: _scheduledWeekdays,
              monthlyDays: _monthlyDays,
              targetDates: _targetDates,
              importance: _importance,
              durationMode: _durationMode,
              reminderTime: _reminderTime,
              activePeriodStart: _activePeriodStart,
              activePeriodEnd: _activePeriodEnd,
              durationMinutes: _durationMinutes,
              onTypeChanged: (val) => setState(() => _selectedType = val),
              onImportanceChanged: (val) => setState(() => _importance = val),
              onStreakChanged: (val) => setState(() => _streakGoal = val),

              onWeekdayToggle: (day) => setState(() {
                if (_scheduledWeekdays.contains(day)) {
                  if (_scheduledWeekdays.length > 1) {
                    _scheduledWeekdays.remove(day);
                  }
                } else {
                  _scheduledWeekdays.add(day);
                }
                _scheduledWeekdays = List.from(_scheduledWeekdays);
              }),

              onMonthlyDayToggle: (day) => setState(() {
                final newList = List<int>.from(_monthlyDays);
                if (newList.contains(day)) {
                  if (newList.length > 1) {
                    newList.remove(day);
                  }
                } else {
                  newList.add(day);
                }
                _monthlyDays = newList;
              }),

              onYearlyDateAdd: (date) {
                if (!_targetDates.contains(date)) {
                  setState(() => _targetDates.add(date));
                }
              },
              onYearlyDateRemove: (date) =>
                  setState(() => _targetDates.remove(date)),

              // MODIFIED: Ensure duration is initialized if Focus Mode is selected
              onDurationModeChanged: (val) {
                setState(() {
                  _durationMode = val;
                  if (_durationMode == HabitDurationMode.focusTimer &&
                      (_durationMinutes == null || _durationMinutes == 0)) {
                    _durationMinutes = 30; // Default to 30 mins
                  }
                });
              },

              onReminderChanged: (val) => setState(() => _reminderTime = val),
              onActiveStartChanged: (val) =>
                  setState(() => _activePeriodStart = val),
              onActiveEndChanged: (val) =>
                  setState(() => _activePeriodEnd = val),
              onDurationMinutesChanged: (val) =>
                  setState(() => _durationMinutes = val),
            ),
            const SizedBox(height: 30),
            Divider(color: colors.textSecondary.withOpacity(0.1)),
            const SizedBox(height: 20),
            HabitHistoryPanel(
              colors: colors,
              previewHabit: _buildHabitModel(),
              completionCount: _controller.completionCount,
              startDate: _startDate,
              streakGoal: _streakGoal,
              scheduledWeekdays: _scheduledWeekdays,
              totalGoalOverride: totalGoal,
              onDateToggled: _controller.toggleDate,
              onUndo: _controller.undo,
              onReset: _controller.resetProgress,
              onAdd: (amount) => _updateProgress(amount),
              onRemove: (amount) => _removeRecentProgress(amount),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.highlight,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 5,
          ),
          onPressed: _saveHabit,
          child: Text(
            widget.existingHabit == null ? "Create Habit" : "Save Changes",
            style: TextStyle(
              color: colors.textHighlighted,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
