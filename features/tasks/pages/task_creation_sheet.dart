import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:task_manager_app/core/theme/colorsettings.dart';
import 'package:task_manager_app/core/services/notification_service.dart';
import 'package:task_manager_app/data/repositories/settings_repository.dart';

// --- MODELS & REPO ---
import '../models/task_model.dart';
import '../models/task_folder_model.dart';
import '../../../data/repositories/task_repository.dart';

// --- WIDGETS ---
import '../widgets/task_toolbar.dart';
import '../widgets/time_configuration_dialog.dart';
import '../widgets/task_form_body.dart';

class TaskCreationSheet extends StatefulWidget {
  final TaskFolder folder;
  final String section;

  const TaskCreationSheet({
    super.key,
    required this.folder,
    required this.section,
  });

  static void show(BuildContext context, TaskFolder folder, String section) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskCreationSheet(folder: folder, section: section),
    );
  }

  @override
  State<TaskCreationSheet> createState() => _TaskCreationSheetState();
}

class _TaskCreationSheetState extends State<TaskCreationSheet> {
  final TaskRepository _repo = TaskRepository();

  late TaskModel _draftTask;

  late TextEditingController _titleCtrl;
  late quill.QuillController _quillCtrl;

  @override
  void initState() {
    super.initState();
    // Initialize a blank task
    _draftTask = TaskModel.create(
      title: "",
      folderId: widget.folder.id,
      sectionName: widget.section,
    );

    _titleCtrl = TextEditingController();
    _quillCtrl = quill.QuillController.basic();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _quillCtrl.dispose();
    super.dispose();
  }

  // FIXED: Converted to async to ensure DB write completes
  Future<void> _saveTask() async {
    if (_titleCtrl.text.trim().isEmpty) return;

    // 1. Update Title
    _draftTask.title = _titleCtrl.text.trim();

    // 2. Update Description
    final json = jsonEncode(_quillCtrl.document.toDelta().toJson());
    if (_quillCtrl.document.length > 1) {
      _draftTask.description = json;
    }

    try {
      // 3. Save to DB
      await _repo.addTask(_draftTask);

      // 4. NOTIFICATION LOGIC (NEW)
      // Check if user has notifications enabled
      final settings = SettingsRepository().getSettings();

      if (settings.allEnabled && settings.taskNotifications) {
        // Only schedule if we have a valid reminder time
        if (_draftTask.reminderTime != null) {
          await NotificationService().scheduleReminder(
            id: _draftTask.id.hashCode, // Unique ID based on Task ID
            title: "Reminder: ${_draftTask.title}",
            body: "Your task is due now!",
            scheduledDate: _draftTask.reminderTime!,
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving task: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: colors.bgMain,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 5),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. REUSED FORM BODY
                TaskFormBody(
                  colors: colors,
                  titleController: _titleCtrl,
                  quillController: _quillCtrl,
                  onTitleSubmitted: (_) => _saveTask(),

                  // Pass Draft Data
                  reminderTime: _draftTask.reminderTime,
                  startTime: _draftTask.startTime,
                  activePeriodStart: _draftTask.activePeriodStart,
                  activePeriodEnd: _draftTask.activePeriodEnd,
                  durationMinutes: _draftTask.durationMinutes,
                  location: _draftTask.location,
                  isHabit: _draftTask.isHabit,
                  habitGoal: _draftTask.habitGoal,
                  isStreakCount: _draftTask.isStreakCount,
                ),

                // 2. HABIT SETTINGS (Only if Habit mode is toggled on)
                if (_draftTask.isHabit) ...[
                  const SizedBox(height: 20),
                  Divider(color: colors.textSecondary.withOpacity(0.1)),
                  _buildHabitSettingsOnly(colors),
                ],
              ],
            ),
          ),

          // 3. TOOLBAR
          TaskToolbar(
            colors: colors,
            importance: _draftTask.importance,
            isEvent: _draftTask.taskType == TaskType.event,
            isHabit: _draftTask.isHabit,
            hasLocation: _draftTask.location != null,
            onSaveTap: _saveTask,

            // Actions update the _draftTask model directly
            onTimeTap: () async {
              final result = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (ctx) => TimeConfigurationDialog(
                  colors: colors,
                  initialReminder: _draftTask.reminderTime,
                  initialPeriodStart: _draftTask.activePeriodStart,
                  initialPeriodEnd: _draftTask.activePeriodEnd,
                  initialDuration: _draftTask.durationMinutes,
                ),
              );

              if (result != null) {
                setState(() {
                  _draftTask.reminderTime = result['reminder'];
                  _draftTask.activePeriodStart = result['periodStart'];
                  _draftTask.activePeriodEnd = result['periodEnd'];
                  _draftTask.durationMinutes = result['duration'];
                });
              }
            },
            onDateTap: () async {
              final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030));
              if (d != null) {
                setState(() => _draftTask.startTime = d);
              }
            },
            onLocationTap: () => _askForLocation(colors),
            onFlagTap: () {
              setState(() {
                int next = (_draftTask.importance.index + 1) %
                    TaskImportance.values.length;
                _draftTask.importance = TaskImportance.values[next];
              });
            },
            onHabitTap: () {
              setState(() {
                _draftTask.isHabit = !_draftTask.isHabit;
                if (_draftTask.isHabit) {
                  _draftTask.taskType = TaskType.habit;
                  // Set Default Goal to 7 immediately for visual feedback
                  if (_draftTask.habitGoal == null) {
                    _draftTask.habitGoal = 7;
                  }
                } else {
                  _draftTask.taskType = TaskType.normal;
                }
              });
            },
          ),
        ],
      ),
    );
  }

  // A simplified Habit UI for creation
  Widget _buildHabitSettingsOnly(AppColors colors) {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.repeat, size: 16, color: colors.priorityLow),
            const SizedBox(width: 8),
            Text("New Habit Setup",
                style: TextStyle(
                    color: colors.priorityLow, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // GOAL CARD
            Expanded(
              child: GestureDetector(
                onTap: () => _showGoalDialog(colors),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.bgBottom, // <--- UPDATED: bgBottom
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text("Goal",
                          style: TextStyle(
                              color: colors.textSecondary, fontSize: 10)),
                      Text("${_draftTask.habitGoal ?? 7}", // Default to 7
                          style: TextStyle(
                              color: colors
                                  .textSecondary, // <--- UPDATED: textSecondary
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // MODE CARD
            Expanded(
              child: GestureDetector(
                onTap: () => setState(
                    () => _draftTask.isStreakCount = !_draftTask.isStreakCount),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.bgBottom, // <--- UPDATED: bgBottom
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _draftTask.isStreakCount
                            ? colors.highlight
                            : Colors.transparent),
                  ),
                  child: Column(
                    children: [
                      Text(
                          _draftTask.isStreakCount
                              ? "Streak Mode"
                              : "Total Mode",
                          style: TextStyle(
                              color: colors.textSecondary, fontSize: 10)),
                      Icon(
                          _draftTask.isStreakCount
                              ? Icons.local_fire_department
                              : Icons.functions,
                          size: 20,
                          color: colors
                              .textSecondary), // <--- UPDATED: textSecondary
                    ],
                  ),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  void _askForLocation(AppColors colors) {
    String loc = "";
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgMiddle,
        content: TextField(
          onChanged: (v) => loc = v,
          autofocus: true,
          style: TextStyle(color: colors.textMain),
          decoration: InputDecoration(
              hintText: "Location",
              hintStyle: TextStyle(color: colors.textSecondary)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _draftTask.location = loc);
              Navigator.pop(ctx);
            },
            child: Text("OK", style: TextStyle(color: colors.highlight)),
          ),
        ],
      ),
    );
  }

  void _showGoalDialog(AppColors colors) {
    String val = _draftTask.habitGoal?.toString() ?? "";
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgMiddle,
        title: Text("Set Goal", style: TextStyle(color: colors.textMain)),
        content: TextField(
          keyboardType: TextInputType.number,
          style: TextStyle(color: colors.textMain),
          controller: TextEditingController(text: val),
          decoration: InputDecoration(
              hintText: "Number of days (Default: 7)",
              hintStyle: TextStyle(color: colors.textSecondary)),
          onChanged: (v) => val = v,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              setState(() {
                _draftTask.habitGoal = int.tryParse(val) ?? 7;
              });
              Navigator.pop(ctx);
            },
            child: Text("Save", style: TextStyle(color: colors.highlight)),
          ),
        ],
      ),
    );
  }
}
