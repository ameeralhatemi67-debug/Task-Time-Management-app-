import 'dart:async';
import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import 'package:task_manager_app/features/tasks/models/task_model.dart';
import 'package:task_manager_app/data/repositories/task_repository.dart';

// FOCUS IMPORTS
import 'package:task_manager_app/features/focus/models/focus_task_model.dart';
import 'package:task_manager_app/data/repositories/focus_repository.dart';

// HABIT IMPORTS
import 'package:task_manager_app/features/habits/models/habit_model.dart';
import 'package:task_manager_app/data/repositories/habit_repository.dart';

// SERVICES
import 'package:task_manager_app/features/smart_add/services/smart_content_parser.dart';
import 'package:task_manager_app/features/smart_add/services/keyword_service.dart';

// WIDGETS
import 'package:task_manager_app/features/smart_add/widgets/smart_add_chips.dart'; // UniversalSmartChip
import 'package:task_manager_app/features/smart_add/widgets/smart_add_toolbar.dart';

class SmartAddSheet extends StatefulWidget {
  final bool isFocusMode;
  final bool initialIsHabit;
  final String? initialText;

  const SmartAddSheet({
    super.key,
    this.isFocusMode = false,
    this.initialIsHabit = false,
    this.initialText,
  });

  @override
  State<SmartAddSheet> createState() => _SmartAddSheetState();
}

class _SmartAddSheetState extends State<SmartAddSheet> {
  final TextEditingController _controller = TextEditingController();

  // Repositories
  final TaskRepository _taskRepo = TaskRepository();
  final FocusRepository _focusRepo = FocusRepository();
  final HabitRepository _habitRepo = HabitRepository();

  // State Flags
  late bool _isFocusMode;
  late bool _isHabitMode;

  // --- PARSED STATE ---
  SmartParseResult? _parsedResult;
  PredictionResult? _taskPrediction;
  bool _isTaskFolderConfirmed = false;

  // --- MANUAL OVERRIDES ---
  TaskImportance _selectedPriority = TaskImportance.none;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _isFocusMode = widget.isFocusMode;
    _isHabitMode = widget.initialIsHabit;

    // If text was passed (e.g. from Camera), initialize immediately
    if (widget.initialText != null) {
      _controller.text = widget.initialText!;
      // Use addPostFrameCallback to ensure UI is ready before triggering logic
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onTextChanged(widget.initialText!);
      });
    }
  }

  // FIX: Added async to await the Future from parse()
  Future<void> _onTextChanged(String text) async {
    // 1. Run Parser
    final result = await SmartContentParser.parse(text);

    // 2. Run Keyword Prediction (for folder) ONLY if we haven't manually confirmed one
    PredictionResult? prediction;
    if (result.potentialFolder == null) {
      prediction = KeywordService.instance.predictFolder(text);
    }

    if (!mounted) return;

    setState(() {
      _parsedResult = result;

      // Only update prediction if confidence is high enough or text is long enough
      if (prediction != null && prediction.confidence > 0.3) {
        _taskPrediction = prediction;
      } else {
        _taskPrediction = null;
      }

      // Auto-switch modes based on strict text triggers if user hasn't toggled them manually
      if (result.isFocusIntent) _isFocusMode = true;
      if (result.suggestHabit) _isHabitMode = true;
    });
  }

  Future<void> _handleSave() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // FIX: Await the parser result if _parsedResult is null
    SmartParseResult result;
    if (_parsedResult != null) {
      result = _parsedResult!;
    } else {
      result = await SmartContentParser.parse(text);
    }

    final title = result.cleanTitle.isEmpty ? "Untitled" : result.cleanTitle;

    // -------------------------------------------------------------------------
    // 1. SAVE AS HABIT
    // -------------------------------------------------------------------------
    if (_isHabitMode) {
      // Use parsed config or default to Weekly
      final config = result.habitConfig ??
          HabitParsingConfig(
              type: HabitType.weekly, scheduledDays: [1, 2, 3, 4, 5]);

      final newHabit = HabitModel.create(
        title: title,
        type: config.type,
        scheduledWeekdays: config.scheduledDays,
        streakGoal: config.streakGoal,
        startDate: _selectedDate ?? result.startTime ?? DateTime.now(),
        // Use parsed folder or default
        folderId: result.potentialFolder ?? "default",
        importance: _selectedPriority != TaskImportance.none
            ? _selectedPriority.index == 0
                ? HabitImportance.high
                : HabitImportance.none
            : HabitImportance.none, // Simple map
      );

      await _habitRepo.saveHabit(newHabit);
    }

    // -------------------------------------------------------------------------
    // 2. SAVE AS FOCUS SESSION
    // -------------------------------------------------------------------------
    else if (_isFocusMode) {
      int mins = result.durationMinutes ?? 25;
      int seconds = mins * 60;
      int count = result.pomodoroCount; // e.g. "2 pomodoros"

      // Create multiple sessions if requested
      for (int i = 0; i < (count > 0 ? count : 1); i++) {
        final focusTask = FocusTaskModel.create(
          title: (count > 1) ? "$title (${i + 1})" : title,
          targetDuration: seconds,
        );
        await _focusRepo.addFocusTask(focusTask);
      }
    }

    // -------------------------------------------------------------------------
    // 3. SAVE AS STANDARD TASK
    // -------------------------------------------------------------------------
    else {
      // A. Resolve Folder ID
      String folderId = "default";

      // Priority 1: AI Prediction (if user confirmed/clicked it)
      if (_isTaskFolderConfirmed && _taskPrediction?.folderId != null) {
        folderId = _taskPrediction!.folderId!;
        // Learn from this confirmation!
        if (_taskPrediction!.folderId != null) {
          await KeywordService.instance.learnCorrection(title, folderId);
        }
      }
      // Priority 2: Explicit Tag in text (e.g. #Work)
      else if (result.potentialFolder != null) {
        // Find folder by name
        final allFolders = _taskRepo.getFolders();
        final match = allFolders.firstWhere(
            (f) =>
                f.name.toLowerCase() == result.potentialFolder!.toLowerCase(),
            orElse: () => allFolders.isNotEmpty
                ? allFolders.first
                : allFolders.first // Fallback
            );
        folderId = match.id;
      }
      // Priority 3: Default Folder
      else {
        final allFolders = _taskRepo.getFolders();
        if (allFolders.isNotEmpty) folderId = allFolders.first.id;
      }

      // B. Resolve Importance
      // Manual selection overrides parsed importance
      TaskImportance finalImportance = _selectedPriority != TaskImportance.none
          ? _selectedPriority
          : (result.importance ?? TaskImportance.medium);

      // C. Resolve Time
      // Manual override > Parsed Time
      DateTime? finalStart = _selectedDate ?? result.startTime;
      if (_selectedTime != null && finalStart != null) {
        finalStart = DateTime(finalStart.year, finalStart.month, finalStart.day,
            _selectedTime!.hour, _selectedTime!.minute);
      } else if (_selectedTime != null) {
        final now = DateTime.now();
        finalStart = DateTime(now.year, now.month, now.day, _selectedTime!.hour,
            _selectedTime!.minute);
      }

      final newTask = TaskModel.create(
        title: title,
        folderId: folderId,
        sectionName: "To Do", // Default section
        type: TaskType.normal,
      ).copyWith(
        startTime: finalStart,
        importance: finalImportance,
        location: result.location,
      );

      await _taskRepo.addTask(newTask);
    }

    if (mounted) Navigator.pop(context);
  }

  // --- ACTIONS ---

  void _cyclePriority() {
    setState(() {
      if (_selectedPriority == TaskImportance.none) {
        _selectedPriority = TaskImportance.high;
      } else if (_selectedPriority == TaskImportance.high) {
        _selectedPriority = TaskImportance.medium;
      } else if (_selectedPriority == TaskImportance.medium) {
        _selectedPriority = TaskImportance.low;
      } else {
        _selectedPriority = TaskImportance.none;
      }
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? now,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final result =
        _parsedResult ?? SmartParseResult(originalText: "", cleanTitle: "");

    // Logic for showing chips
    // Show folder chip if we have a prediction OR an explicit tag OR user pinned it
    bool showFolder = _isTaskFolderConfirmed ||
        result.potentialFolder != null ||
        (_taskPrediction != null && !_isHabitMode && !_isFocusMode);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: colors.bgMain,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. INPUT FIELD
          TextField(
            controller: _controller,
            onChanged: _onTextChanged,
            autofocus: true,
            style: TextStyle(
                fontSize: 18,
                color: colors.textMain,
                fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: _isHabitMode
                  ? "New Habit (e.g. Gym Mon, Wed)"
                  : _isFocusMode
                      ? "New Focus Session (e.g. Study 25m)"
                      : "New Task (e.g. Buy Milk !high)",
              hintStyle:
                  TextStyle(color: colors.textSecondary.withOpacity(0.5)),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 10),

          // 2. SMART CHIPS ROW (Horizontally Scrollable)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // A. HABIT CHIP
                UniversalSmartChip(
                  label: "Habit",
                  icon: Icons.cached,
                  color: colors.completedWork,
                  state: _isHabitMode
                      ? ChipVisualState.confirmed
                      : ChipVisualState.suggested,
                  onTap: () => setState(() {
                    _isHabitMode = !_isHabitMode;
                    if (_isHabitMode)
                      _isFocusMode = false; // Mutually exclusive usually
                  }),
                ),
                const SizedBox(width: 8),

                // B. FOCUS CHIP
                UniversalSmartChip(
                  label: "Focus",
                  icon: Icons.filter_center_focus,
                  color: colors.focusLink,
                  state: _isFocusMode
                      ? ChipVisualState.confirmed
                      : ChipVisualState.suggested,
                  onTap: () => setState(() {
                    _isFocusMode = !_isFocusMode;
                    if (_isFocusMode) _isHabitMode = false;
                  }),
                ),
                const SizedBox(width: 8),

                // C. PRIORITY CHIP
                UniversalSmartChip(
                  label: (_selectedPriority != TaskImportance.none)
                      ? _selectedPriority.name.toUpperCase()
                      : (result.importance?.name.toUpperCase() ?? "Priority"),
                  icon: Icons.flag,
                  // Color logic: Red for High, Orange for Med, Blue for Low
                  color: (_selectedPriority == TaskImportance.high ||
                          result.importance == TaskImportance.high)
                      ? colors.priorityHigh
                      : (_selectedPriority == TaskImportance.medium ||
                              result.importance == TaskImportance.medium)
                          ? colors.priorityMedium
                          : colors.priorityLow,
                  state: (_selectedPriority != TaskImportance.none ||
                          result.importance != null)
                      ? ChipVisualState.confirmed
                      : ChipVisualState.suggested,
                  onTap: _cyclePriority,
                ),
                const SizedBox(width: 8),

                // D. FOLDER CHIP
                if (showFolder)
                  UniversalSmartChip(
                    label: _isTaskFolderConfirmed
                        ? (_taskPrediction?.folderName ??
                            result.potentialFolder!)
                        : (_taskPrediction?.folderName ??
                            result.potentialFolder ??
                            "Folder"),
                    icon: Icons.folder_open,
                    color: colors.highlight,
                    state: _isTaskFolderConfirmed
                        ? ChipVisualState.confirmed
                        : ChipVisualState.suggested,
                    onTap: () => setState(
                        () => _isTaskFolderConfirmed = !_isTaskFolderConfirmed),
                  ),

                // E. DATE/TIME CHIP
                if (result.startTime != null ||
                    _selectedDate != null ||
                    _selectedTime != null) ...[
                  const SizedBox(width: 8),
                  UniversalSmartChip(
                    label: _selectedTime != null
                        ? "${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}"
                        : (result.startTime != null
                            ? "${result.startTime!.hour}:${result.startTime!.minute.toString().padLeft(2, '0')}"
                            : "Time"),
                    icon: Icons.access_time,
                    color: colors.textSecondary,
                    state: ChipVisualState.confirmed,
                    onTap: _pickTime,
                  )
                ]
              ],
            ),
          ),

          const SizedBox(height: 15),

          // 3. TOOLBAR (Send Button)
          SmartAddToolbar(
            isHabitMode: _isHabitMode,
            colors: colors,
            importance: _selectedPriority != TaskImportance.none ||
                    _parsedResult?.importance != null
                ? (_selectedPriority != TaskImportance.none
                    ? _selectedPriority
                    : _parsedResult!.importance!)
                : TaskImportance.none,
            showCategory: true,
            hasLocation: _parsedResult?.location != null,
            showSmartPopup: false,
            onSaveTap: _handleSave,
            onFlagTap: _cyclePriority,
            onLocationTap: () {
              // Placeholder: In real app, open location picker dialog
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Location picker coming soon")));
            },
            onDateTap: _pickDate,
            onTimeTap: _pickTime,
            onCategoryTap: () {
              // Placeholder: Toggle folder selection logic
            },
            onChecklistTap: () {
              // Placeholder
            },
            onSmartPopupTap: () {},
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
