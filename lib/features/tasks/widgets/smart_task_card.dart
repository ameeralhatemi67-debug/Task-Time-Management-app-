import 'dart:convert'; // <--- REQUIRED: For jsonDecode
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_quill/flutter_quill.dart'
    as quill; // <--- REQUIRED: For Document parsing
import 'package:task_manager_app/core/theme/colorsettings.dart';
import '../models/task_model.dart';
import '../../../data/repositories/task_repository.dart';

// --- HABIT IMPORTS ---
import 'package:task_manager_app/features/habits/models/habit_model.dart';
import 'package:task_manager_app/features/habits/widgets/habit_progress_grid.dart';
import 'package:task_manager_app/features/habits/widgets/habit_checkbox.dart';

class SmartTaskCard extends StatefulWidget {
  final TaskModel task;
  final AppColors colors;
  final VoidCallback onLongPress;
  final VoidCallback onCheck;
  final VoidCallback? onBodyTap;
  final VoidCallback? onUpdate;

  const SmartTaskCard({
    super.key,
    required this.task,
    required this.colors,
    required this.onLongPress,
    required this.onCheck,
    this.onBodyTap,
    this.onUpdate,
  });

  @override
  State<SmartTaskCard> createState() => _SmartTaskCardState();
}

class _SmartTaskCardState extends State<SmartTaskCard>
    with SingleTickerProviderStateMixin {
  final TaskRepository _repo = TaskRepository();

  // --- STATE VARIABLES ---
  bool _isExpanded = false;
  bool _isEditing = false;
  late TextEditingController _titleCtrl;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task.title);

    // Auto-save title when focus is lost
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _saveTitle();
      }
    });
  }

  @override
  void didUpdateWidget(SmartTaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.title != widget.task.title && !_isEditing) {
      _titleCtrl.text = widget.task.title;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _saveTitle() {
    if (_titleCtrl.text.trim().isNotEmpty) {
      widget.task.title = _titleCtrl.text.trim();
      widget.task.save();
    } else {
      _titleCtrl.text = widget.task.title; // Revert if empty
    }
    setState(() => _isEditing = false);
    if (widget.onUpdate != null) widget.onUpdate!();
  }

  // --- NEW: DESCRIPTION PARSER ---
  String _getCleanDescription() {
    final raw = widget.task.description;
    if (raw == null || raw.isEmpty) return "";
    try {
      // 1. Try decoding as JSON (Quill Format)
      final json = jsonDecode(raw);
      // 2. Convert to Document
      final doc = quill.Document.fromJson(json);
      // 3. Extract human-readable text
      return doc.toPlainText().trim();
    } catch (e) {
      // Fallback: If it's not JSON (old data), just show it as is
      return raw;
    }
  }

  // --- UI BUILDING ---

  @override
  Widget build(BuildContext context) {
    final bool isPinned = widget.task.isPinned;
    final bool isCompleted = widget.task.isDone;

    // Check if task is "Locked" by time (Phase 3 Rule)
    final bool isLocked = widget.task.isLocked;

    // Determine Priority Color
    Color? priorityBorderColor;
    if (!isCompleted && !isLocked) {
      switch (widget.task.importance) {
        case TaskImportance.high:
          priorityBorderColor = widget.colors.priorityHigh;
          break;
        case TaskImportance.medium:
          priorityBorderColor = widget.colors.priorityMedium;
          break;
        case TaskImportance.low:
          priorityBorderColor = widget.colors.priorityLow;
          break;
        case TaskImportance.none:
          priorityBorderColor = null;
          break;
      }
    }

    return Slidable(
      key: ValueKey(widget.task.id),
      // ACTIONS: Left -> Delete
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        dismissible: DismissiblePane(onDismissed: () {
          _repo.delete(widget.task.id);
          if (widget.onUpdate != null) widget.onUpdate!();
        }),
        children: [
          SlidableAction(
            onPressed: (ctx) {
              _repo.delete(widget.task.id);
              if (widget.onUpdate != null) widget.onUpdate!();
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(20)),
          ),
        ],
      ),
      // ACTIONS: Right -> Pin, Archive
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (ctx) {
              widget.task.isPinned = !widget.task.isPinned;
              widget.task.save();
              if (widget.onUpdate != null) widget.onUpdate!();
            },
            backgroundColor: widget.colors.highlight,
            foregroundColor: widget.colors.textHighlighted,
            icon: isPinned ? Icons.push_pin_outlined : Icons.push_pin,
            label: isPinned ? 'Unpin' : 'Pin',
          ),
          SlidableAction(
            onPressed: (ctx) {
              widget.task.isArchived = true;
              widget.task.save();
              if (widget.onUpdate != null) widget.onUpdate!();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("Task archived"),
                  backgroundColor: widget.colors.bgMiddle,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            backgroundColor: widget.colors.textSecondary,
            foregroundColor: widget.colors.bgMain,
            icon: Icons.archive,
            label: 'Archive',
            borderRadius:
                const BorderRadius.horizontal(right: Radius.circular(20)),
          ),
        ],
      ),
      child: GestureDetector(
        onLongPress: widget.onLongPress,
        onTap: widget.onBodyTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isLocked
                ? widget.colors.bgMiddle.withOpacity(0.5) // Dim if locked
                : widget.colors.bgMiddle,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPinned
                  ? widget.colors.highlight.withOpacity(0.5)
                  : widget.colors.bgBottom,
              width: isPinned ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP ROW (Checkbox + Title + Expand)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CHECKBOX
                  GestureDetector(
                    onTap: isLocked
                        ? _showLockedMessage
                        : () {
                            HapticFeedback.lightImpact();
                            widget.onCheck();
                          },
                    child: HabitCheckbox(
                      status: isCompleted
                          ? HabitStatus.completed
                          : HabitStatus.active,
                      isLocked: isLocked,
                      onTap: isLocked ? () {} : widget.onCheck,
                      colors: widget.colors,
                      size: 28,
                      borderRadius: 8,
                      priorityColor: priorityBorderColor,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // TITLE & META
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // INLINE EDITING TITLE
                        _isEditing
                            ? TextField(
                                controller: _titleCtrl,
                                focusNode: _focusNode,
                                autofocus: true,
                                style: TextStyle(
                                  color: widget.colors.textMain,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onSubmitted: (_) => _saveTitle(),
                              )
                            : GestureDetector(
                                onTap: () {
                                  // Tap to edit if not done
                                  if (!isCompleted)
                                    setState(() => _isEditing = true);
                                },
                                child: Text(
                                  widget.task.title,
                                  style: TextStyle(
                                    color: isCompleted
                                        ? widget.colors.textSecondary
                                            .withOpacity(0.5)
                                        : (isLocked
                                            ? widget.colors.textSecondary
                                            : widget.colors.textMain),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    decoration: isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                              ),

                        const SizedBox(height: 6),
                        _buildMetaRow(isLocked),
                      ],
                    ),
                  ),

                  // EXPAND / LOCK ICON
                  if (isLocked)
                    Icon(Icons.lock_outline,
                        size: 20, color: widget.colors.textSecondary)
                  else if (_hasExpandableContent())
                    GestureDetector(
                      onTap: _toggleExpansion,
                      child: Container(
                        color: Colors.transparent, // Hitbox
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: widget.colors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),

              // 2. EXPANDED CONTENT
              if (_isExpanded && !isLocked) ...[
                const SizedBox(height: 15),
                const Divider(height: 1),
                const SizedBox(height: 15),

                // Description (FIXED: Using parser)
                if (widget.task.description != null &&
                    widget.task.description!.isNotEmpty)
                  Text(
                    _getCleanDescription(),
                    style: TextStyle(
                        color: widget.colors.textSecondary, height: 1.5),
                  ),

                // Checklist
                if (widget.task.checklist != null &&
                    widget.task.checklist!.isNotEmpty) ...[
                  const SizedBox(height: 15),
                  _buildChecklist(),
                ],

                // Habit Grid
                if (widget.task.isHabit) ...[
                  const SizedBox(height: 15),
                  _buildHabitMiniGrid(),
                ]
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showLockedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            "Task is locked until ${DateFormat.jm().format(widget.task.activePeriodStart!)}"),
        backgroundColor: widget.colors.bgMiddle,
      ),
    );
  }

  bool _hasExpandableContent() {
    return (widget.task.description != null &&
            widget.task.description!.isNotEmpty) ||
        (widget.task.checklist != null && widget.task.checklist!.isNotEmpty) ||
        widget.task.isHabit;
  }

  // --- RICH META ROW ---
  Widget _buildMetaRow(bool isLocked) {
    List<Widget> metaItems = [];

    // 1. Time / Active Period
    if (widget.task.activePeriodStart != null) {
      // "Locked" Time style
      metaItems.add(_buildMetaTag(Icons.timelapse,
          "${DateFormat.jm().format(widget.task.activePeriodStart!)} - ${DateFormat.jm().format(widget.task.activePeriodEnd!)}",
          isInteractive: true, onTap: _editTime));
    } else if (widget.task.startTime != null) {
      final timeStr = DateFormat.Hm().format(widget.task.startTime!);
      metaItems.add(_buildMetaTag(Icons.access_time, timeStr,
          isInteractive: true, onTap: _editTime));
    }

    // 2. Location
    if (widget.task.location != null && widget.task.location!.isNotEmpty) {
      metaItems.add(_buildMetaTag(Icons.place, widget.task.location!,
          isInteractive: true, onTap: _editLocation));
    }

    // 3. Focus Duration
    if (widget.task.durationMinutes != null) {
      metaItems
          .add(_buildMetaTag(Icons.timer, "${widget.task.durationMinutes}m"));
    }

    // 4. Recurrence Rule (e.g. "Weekly")
    if (widget.task.recurrenceRule != null) {
      String rule = widget.task.recurrenceRule!.split(':').first; // "WEEKLY"
      metaItems
          .add(_buildMetaTag(Icons.repeat, rule.toLowerCase().capitalize()));
    }

    // 5. Streak (For Habits)
    if (widget.task.isHabit && (widget.task.habitStreak ?? 0) > 0) {
      metaItems.add(_buildMetaTag(
          Icons.local_fire_department, "${widget.task.habitStreak}",
          colorOverride: Colors.orangeAccent));
    }

    // 6. Checklist Progress (When collapsed)
    if (!_isExpanded &&
        widget.task.checklist != null &&
        widget.task.checklist!.isNotEmpty) {
      int total = widget.task.checklist!.length;
      int done =
          widget.task.checklist!.where((s) => s.startsWith('[x]')).length;
      if (done < total) {
        metaItems.add(_buildMetaTag(Icons.checklist, "$done/$total"));
      }
    }

    // 7. Focus Badge
    if (widget.task.requiresFocusMode) {
      metaItems.add(_buildMetaTag(Icons.filter_center_focus, "Focus",
          colorOverride: widget.colors.highlight));
    }

    if (metaItems.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 10,
      runSpacing: 5,
      children: metaItems,
    );
  }

  Widget _buildMetaTag(IconData icon, String label,
      {bool isInteractive = false, VoidCallback? onTap, Color? colorOverride}) {
    Color contentColor = colorOverride ?? widget.colors.textSecondary;

    Widget tag = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: contentColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: contentColor,
            fontSize: 12,
            fontWeight: isInteractive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );

    if (isInteractive) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: widget.colors.bgTop,
            borderRadius: BorderRadius.circular(4),
          ),
          child: tag,
        ),
      );
    }
    return tag;
  }

  // --- EDIT ACTIONS ---

  void _editTime() async {
    final now = DateTime.now();
    final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(widget.task.startTime ?? now));
    if (time != null) {
      final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      widget.task.startTime = dt;
      widget.task.save();
      setState(() {});
    }
  }

  void _editLocation() async {
    String? newLoc;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.colors.bgMiddle,
        title: Text("Edit Location",
            style: TextStyle(color: widget.colors.textMain)),
        content: TextField(
          autofocus: true,
          style: TextStyle(color: widget.colors.textMain),
          controller: TextEditingController(text: widget.task.location),
          onChanged: (v) => newLoc = v,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
              onPressed: () {
                if (newLoc != null) {
                  widget.task.location = newLoc;
                  widget.task.save();
                  setState(() {});
                }
                Navigator.pop(ctx);
              },
              child: Text("Save",
                  style: TextStyle(color: widget.colors.highlight))),
        ],
      ),
    );
  }

  // --- SUB-WIDGETS ---

  Widget _buildChecklist() {
    if (widget.task.checklist == null) return const SizedBox.shrink();
    return Column(
      children: widget.task.checklist!.map((line) {
        bool isChecked = line.trim().startsWith('[x]');
        String text = line.replaceAll('[x]', '').replaceAll('[]', '').trim();

        return GestureDetector(
          onTap: () => _toggleChecklistItem(line),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    isChecked ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 18,
                    color: isChecked
                        ? widget.colors.highlight
                        : widget.colors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                        color: isChecked
                            ? widget.colors.textSecondary.withOpacity(0.5)
                            : widget.colors.textMain,
                        decoration:
                            isChecked ? TextDecoration.lineThrough : null,
                        height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _toggleChecklistItem(String rawLine) {
    final isChecked = rawLine.trim().startsWith('[x]');
    String newLine;
    if (isChecked) {
      newLine = rawLine.replaceFirst('[x]', '[]');
    } else {
      newLine = rawLine.replaceFirst('[]', '[x]');
      if (!newLine.contains('[x]')) newLine = "[x] $rawLine";
    }

    final List<String> newList = List.from(widget.task.checklist!);
    final index = newList.indexOf(rawLine);
    if (index != -1) {
      newList[index] = newLine;
      widget.task.checklist = newList;
      widget.task.save();
      setState(() {});
    }
  }

  void _toggleExpansion() {
    setState(() => _isExpanded = !_isExpanded);
  }

  Widget _buildHabitMiniGrid() {
    final tempHabit = HabitModel(
      id: widget.task.id,
      title: widget.task.title,
      description: "",
      typeString: 'weekly', // Forces the weekly pill design
      streakGoal: widget.task.habitGoal ?? 1,
      completedDaysList: widget.task.completedHistory ?? [],
      scheduledWeekdays: [],
      startDate: widget.task.dateCreated,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: widget.colors.bgBottom,
        borderRadius: BorderRadius.circular(12),
      ),
      // CHANGED: Column -> Row (1 Row, 2 Columns layout)
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Column 1: Info (Title + Streak)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Habit History",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: widget.colors.textSecondary,
                ),
              ),
              if (widget.task.habitStreak != null &&
                  widget.task.habitStreak! > 0) ...[
                const SizedBox(height: 4),
                Text(
                  "${widget.task.habitStreak} Day Streak",
                  style: TextStyle(
                      fontSize: 10,
                      color: widget.colors.highlight,
                      fontWeight: FontWeight.bold),
                )
              ],
            ],
          ),

          // Column 2: The Grid (Pills)
          HabitProgressGrid(
            habit: tempHabit,
            colors: widget.colors,
            isInteractive: false,
            barWidth: 18,
            barHeight: 25,
            spacing: 7,
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
