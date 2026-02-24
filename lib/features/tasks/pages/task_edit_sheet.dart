import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:task_manager_app/core/theme/colorsettings.dart';
import 'package:task_manager_app/core/services/notification_service.dart';
import 'package:task_manager_app/data/repositories/settings_repository.dart';

// --- MODELS & REPO ---
import '../models/task_model.dart';
import '../../../data/repositories/task_repository.dart';

// --- LOGIC ---
import '../logic/habit_controller.dart';

// --- WIDGETS ---
import '../widgets/smart_task_card.dart';
import '../widgets/task_toolbar.dart';
import '../widgets/task_folder_dialog.dart';
import '../widgets/section_picker_dialog.dart';
import '../widgets/time_configuration_dialog.dart';
import '../widgets/task_form_body.dart';
import '../widgets/habit_dashboard.dart';

// --- EDITOR TOOLS ---
import 'package:task_manager_app/features/notes/widgets/note_editor/editor_toolbar.dart';
import 'package:task_manager_app/features/notes/widgets/note_editor/simple_color_palette.dart';
import 'package:task_manager_app/features/notes/widgets/note_editor/color_picker_sheet.dart';
import 'package:task_manager_app/features/notes/widgets/note_editor/font_size_sheet.dart';
import 'package:task_manager_app/features/notes/widgets/note_editor/alignment_sheet.dart';

// --- FOCUS PAGE ---
import 'package:task_manager_app/features/focus/pages/focus_page.dart';

class TaskEditSheet extends StatefulWidget {
  final TaskModel task;

  const TaskEditSheet({super.key, required this.task});

  static void show(BuildContext context, TaskModel task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskEditSheet(task: task),
    );
  }

  @override
  State<TaskEditSheet> createState() => _TaskEditSheetState();
}

class _TaskEditSheetState extends State<TaskEditSheet> {
  final TaskRepository _repo = TaskRepository();

  late TaskModel _task;
  late HabitController _habitController; // Logic Controller

  late TextEditingController _titleCtrl;
  late quill.QuillController _quillCtrl;

  List<TaskModel> _subtasks = [];
  bool _isNoteMode = false;

  // Editor State
  Color _currentEditorColor = Colors.black;
  double _currentEditorSize = 16.0;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _habitController = HabitController(_task); // Initialize Logic

    _titleCtrl = TextEditingController(text: _task.title);
    _initQuill();
    _loadSubtasks();
  }

  Future<void> _rescheduleNotification() async {
    final settings = SettingsRepository().getSettings();
    final int notifId = _task.id.hashCode;

    // 1. Cancel existing (to be safe)
    await NotificationService().cancelNotification(notifId);

    // 2. Schedule new if allowed
    if (settings.allEnabled && settings.taskNotifications) {
      if (_task.reminderTime != null && !_task.isDone) {
        await NotificationService().scheduleReminder(
          id: notifId,
          title: "Reminder: ${_task.title}",
          body: "Your task is due now!",
          scheduledDate: _task.reminderTime!,
        );
      }
    }
  }

  void _initQuill() {
    try {
      if (_task.description != null && _task.description!.startsWith('[')) {
        final json = jsonDecode(_task.description!);
        _quillCtrl = quill.QuillController(
          document: quill.Document.fromJson(json),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } else {
        _quillCtrl = quill.QuillController(
          document: quill.Document()..insert(0, _task.description ?? ''),
          selection: const TextSelection.collapsed(offset: 0),
        );
      }
    } catch (e) {
      _quillCtrl = quill.QuillController.basic();
    }

    _quillCtrl.document.changes.listen((event) {
      _saveDescription();
    });
  }

  void _loadSubtasks() {
    setState(() {
      _subtasks = _repo.getSubtasks(_task.id);
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _quillCtrl.dispose();
    super.dispose();
  }

  // --- SAVING ---

  void _saveTask() {
    _task.title = _titleCtrl.text;
    _task.save();
    _rescheduleNotification();
    setState(() {});
  }

  void _saveDescription() {
    final json = jsonEncode(_quillCtrl.document.toDelta().toJson());
    _task.description = json;
    _task.save();
  }

  // --- ACTIONS ---

  void _addSubtask() {
    final subtask = TaskModel.create(
      title: "New Subtask",
      folderId: _task.folderId,
      sectionName: _task.sectionName,
      parentId: _task.id,
    );
    _repo.addTask(subtask);
    _loadSubtasks();
  }

  void _deleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Task?"),
        content: const Text("This will also delete all subtasks."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await NotificationService().cancelNotification(_task.id.hashCode);
      await _repo.deleteTask(_task.id);

      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _moveToFolder(AppColors colors) async {
    final folders = _repo.getFolders();
    showDialog(
      context: context,
      builder: (ctx) => TaskFolderDialog(
        colors: colors,
        folders: folders,
        onUpdate: () {},
        onFolderSelected: (folder) {
          _task.folderId = folder.id;
          if (folder.sections.isNotEmpty) {
            _task.sectionName = folder.sections.first;
          }
          _task.save();
          setState(() {});
        },
      ),
    );
  }

  Future<void> _moveToSection(AppColors colors) async {
    final folders = _repo.getFolders();
    final currentFolder = folders.firstWhere((f) => f.id == _task.folderId,
        orElse: () => folders.first);

    showDialog(
      context: context,
      builder: (ctx) => SectionPickerDialog(
        colors: colors,
        folder: currentFolder,
        onSectionSelected: (section) {
          _task.sectionName = section;
          _task.save();
          setState(() {});
        },
      ),
    );
  }

  // --- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final double sheetHeight = bottomInset > 0 ? 0.95 : 0.65;

    return DraggableScrollableSheet(
      initialChildSize: sheetHeight,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: colors.bgMiddle.withOpacity(0.9),
              child: Column(
                children: [
                  _buildHeader(colors),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 10),
                      children: [
                        // 1. START FOCUS SESSION BUTTON
                        if (_task.requiresFocusMode ||
                            (_task.activePeriodStart != null)) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colors.highlight,
                                  foregroundColor: colors.textHighlighted,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.play_circle_fill),
                                label: const Text("Start Focus Session",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          FocusPage(initialTask: _task),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],

                        // 2. FORM BODY (Title, Meta Chips, Editor)
                        TaskFormBody(
                          colors: colors,
                          titleController: _titleCtrl,
                          quillController: _quillCtrl,
                          onTitleSubmitted: (_) => _saveTask(),

                          // Meta Fields for Chips
                          reminderTime: _task.reminderTime,
                          startTime: _task.startTime,
                          activePeriodStart: _task.activePeriodStart,
                          activePeriodEnd: _task.activePeriodEnd,
                          durationMinutes: _task.durationMinutes,
                          location: _task.location,
                          isHabit: _task.isHabit,
                          habitGoal: _task.habitGoal,
                          isStreakCount: _task.isStreakCount,
                        ),

                        // 3. HABIT DASHBOARD (If applicable)
                        if (_task.isHabit) ...[
                          const SizedBox(height: 24),
                          Divider(color: colors.textSecondary.withOpacity(0.1)),
                          HabitDashboard(
                            task: _task,
                            colors: colors,
                            // All logic delegated to HabitController
                            onDateToggled: (d) => setState(
                                () => _habitController.toggleHistoryDate(d)),
                            onReset: () => setState(
                                () => _habitController.resetProgress()),
                            onRevert: () => setState(
                                () => _habitController.revertProgress()),
                            onUndo: () => setState(
                                () => _habitController.undoLastAction()),
                            onForward: () =>
                                setState(() => _habitController.addProgress()),
                            onGoalChanged: (val) {
                              setState(() {
                                _task.habitGoal = val;
                                _task.save();
                              });
                            },
                            onStreakModeChanged: (val) {
                              setState(() {
                                _task.isStreakCount = val;
                                _task.save();
                              });
                            },
                          ),
                        ],

                        // 4. SUBTASKS
                        if (_subtasks.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Divider(color: colors.textSecondary.withOpacity(0.1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              "Subtasks",
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          ..._subtasks.map((sub) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: SmartTaskCard(
                                  task: sub,
                                  colors: colors,
                                  onCheck: () async {
                                    await _repo.toggleTask(sub);
                                    _loadSubtasks();
                                  },
                                  onLongPress: () {},
                                  onBodyTap: () {
                                    Navigator.pop(context);
                                    TaskEditSheet.show(context, sub);
                                  },
                                  onUpdate: _loadSubtasks,
                                ),
                              )),
                        ],

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                  _buildBottomBar(colors, bottomInset),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- HEADER & TOOLBAR ---

  Widget _buildHeader(AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () async {
              await _repo.toggleTask(_task);
              setState(() {});
            },
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _task.isDone ? colors.done : _getPriorityColor(colors),
                  width: 2,
                ),
                color: _task.isDone ? colors.done : Colors.transparent,
              ),
              child: _task.isDone
                  ? Icon(Icons.check, size: 18, color: colors.bgMain)
                  : null,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(child: Container()),
          IconButton(
            icon: Icon(
              _task.importance == TaskImportance.high
                  ? Icons.flag
                  : Icons.outlined_flag,
              color: _getPriorityColor(colors),
            ),
            onPressed: () {
              setState(() {
                int next =
                    (_task.importance.index + 1) % TaskImportance.values.length;
                _task.importance = TaskImportance.values[next];
                _task.save();
              });
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_horiz, color: colors.textMain),
            color: colors.bgMiddle,
            onSelected: (val) {
              if (val == 'delete') _deleteTask();
              if (val == 'move_folder') _moveToFolder(colors);
              if (val == 'move_section') _moveToSection(colors);
              if (val == 'pin') {
                _repo.togglePin(_task);
                setState(() {});
              }
              if (val == 'subtask') _addSubtask();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                  value: 'subtask',
                  child: _buildMenuItem(
                      Icons.subdirectory_arrow_right, "Add Subtask", colors)),
              PopupMenuItem(
                  value: 'pin',
                  child: _buildMenuItem(Icons.push_pin,
                      _task.isPinned ? "Unpin" : "Pin", colors)),
              PopupMenuItem(
                  value: 'move_section',
                  child: _buildMenuItem(
                      Icons.low_priority, "Move Section", colors)),
              PopupMenuItem(
                  value: 'move_folder',
                  child: _buildMenuItem(Icons.folder, "Move Folder", colors)),
              const PopupMenuDivider(),
              PopupMenuItem(
                  value: 'delete',
                  child: _buildMenuItem(Icons.delete, "Delete", colors,
                      isDestructive: true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, AppColors colors,
      {bool isDestructive = false}) {
    final color = isDestructive ? Colors.red : colors.textMain;
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }

  Widget _buildBottomBar(AppColors colors, double bottomInset) {
    return Container(
      padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : 20),
      decoration: BoxDecoration(
        color: colors.bgMiddle,
        border: Border(top: BorderSide(color: colors.bgBottom, width: 1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isNoteMode ? Icons.text_fields : Icons.check_circle_outline,
                  color: colors.highlight,
                ),
                onPressed: () => setState(() => _isNoteMode = !_isNoteMode),
              ),
              Container(
                  width: 1,
                  height: 24,
                  color: colors.textSecondary.withOpacity(0.2)),
              Expanded(
                child: _isNoteMode
                    ? EditorToolbar(
                        colors: colors,
                        controller: _quillCtrl,
                        onAlignPressed: () => _showAlignmentSheet(colors),
                        onColorPressed: () => _showColorSheet(colors),
                        onSizePressed: () => _showSizeSheet(colors),
                      )
                    : TaskToolbar(
                        colors: colors,
                        importance: _task.importance,
                        isEvent: _task.taskType == TaskType.event,
                        isHabit: _task.isHabit,
                        hasLocation: _task.location != null,
                        showSaveButton: false,
                        onSaveTap: () => Navigator.pop(context),
                        onDateTap: () async {
                          final initialDate = _task.startTime ?? DateTime.now();
                          final result = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            initialDateRange:
                                _task.startTime != null && _task.endDate != null
                                    ? DateTimeRange(
                                        start: _task.startTime!,
                                        end: _task.endDate!)
                                    : DateTimeRange(
                                        start: initialDate, end: initialDate),
                            builder: (ctx, child) => Theme(
                              data: Theme.of(ctx).copyWith(
                                colorScheme: ColorScheme.dark(
                                  primary: colors.highlight,
                                  onPrimary: colors.textHighlighted,
                                  surface: colors.bgMiddle,
                                  onSurface: colors.textMain,
                                ),
                              ),
                              child: child!,
                            ),
                          );

                          if (result != null) {
                            setState(() {
                              _task.startTime = result.start;
                              _task.endDate = result.end;
                              _task.save();
                            });
                          }
                        },
                        // Unified Time Dialog
                        onTimeTap: () async {
                          final result = await showDialog<Map<String, dynamic>>(
                            context: context,
                            builder: (ctx) => TimeConfigurationDialog(
                              colors: colors,
                              initialReminder: _task.reminderTime,
                              initialPeriodStart: _task.activePeriodStart,
                              initialPeriodEnd: _task.activePeriodEnd,
                              initialDuration: _task.durationMinutes,
                            ),
                          );

                          if (result != null) {
                            setState(() {
                              _task.reminderTime = result['reminder'];
                              _task.activePeriodStart = result['periodStart'];
                              _task.activePeriodEnd = result['periodEnd'];
                              _task.durationMinutes = result['duration'];
                              _task.save();
                            });
                            await _rescheduleNotification();
                          }
                        },
                        onFlagTap: () {
                          int next = (_task.importance.index + 1) %
                              TaskImportance.values.length;
                          _task.importance = TaskImportance.values[next];
                          _task.save();
                          setState(() {});
                        },
                        onHabitTap: () {
                          setState(() {
                            _task.isHabit = !_task.isHabit;
                            _task.save();
                          });
                        },
                        onLocationTap: () {},
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- FORMATTING HELPERS ---

  void _showColorSheet(AppColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SimpleColorPalette(
        colors: colors,
        onColorSelected: (color) {
          _currentEditorColor = color;
          _quillCtrl.formatSelection(quill.ColorAttribute(
              '#${color.value.toRadixString(16).substring(2)}'));
        },
        onCustomColorPressed: () {
          Navigator.pop(context);
          _showAdvancedColorPicker(colors);
        },
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  void _showAdvancedColorPicker(AppColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ColorPickerSheet(
        colors: colors,
        currentColor: _currentEditorColor,
        onColorSelected: (color) {
          _quillCtrl.formatSelection(quill.ColorAttribute(
              '#${color.value.toRadixString(16).substring(2)}'));
        },
      ),
    );
  }

  void _showSizeSheet(AppColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => FontSizeSheet(
        colors: colors,
        currentSize: _currentEditorSize,
        onSizeSelected: (size) => _currentEditorSize = size,
      ),
    );
  }

  void _showAlignmentSheet(AppColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => AlignmentSheet(
        colors: colors,
        onAlignSelected: (align) {
          quill.Attribute? attr;
          if (align == TextAlign.left) attr = quill.Attribute.leftAlignment;
          if (align == TextAlign.center) attr = quill.Attribute.centerAlignment;
          if (align == TextAlign.right) attr = quill.Attribute.rightAlignment;
          if (align == TextAlign.justify) {
            attr = quill.Attribute.justifyAlignment;
          }
          if (attr != null) _quillCtrl.formatSelection(attr);
        },
      ),
    );
  }

  Color _getPriorityColor(AppColors colors) {
    switch (_task.importance) {
      case TaskImportance.high:
        return colors.priorityHigh;
      case TaskImportance.medium:
        return colors.priorityMedium;
      case TaskImportance.low:
        return colors.priorityLow;
      default:
        return colors.textSecondary.withOpacity(0.3);
    }
  }
}
