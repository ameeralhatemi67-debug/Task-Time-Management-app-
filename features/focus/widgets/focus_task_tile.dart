import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import '../models/focus_task_model.dart';
// REMOVED HabitCheckbox import as we build a custom one for specific color control

class FocusTaskTile extends StatefulWidget {
  final FocusTaskModel task;
  final AppColors colors;
  final VoidCallback onUpdate;
  final VoidCallback onCheck;
  final Function(FocusTaskModel) onPlay;
  final Function(int) onDurationChanged;
  final int stepMinutes;

  final Function(FocusTaskModel) onPin;
  final Function(FocusTaskModel) onArchive;
  final Function(FocusTaskModel) onDelete;

  const FocusTaskTile({
    super.key,
    required this.task,
    required this.colors,
    required this.onUpdate,
    required this.onCheck,
    required this.onPlay,
    required this.onDurationChanged,
    required this.onPin,
    required this.onArchive,
    required this.onDelete,
    this.stepMinutes = 1,
  });

  @override
  State<FocusTaskTile> createState() => _FocusTaskTileState();
}

class _FocusTaskTileState extends State<FocusTaskTile> {
  late TextEditingController _titleCtrl;
  final FocusNode _focusNode = FocusNode();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task.title);

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _saveTitle();
      }
    });
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
      _titleCtrl.text = widget.task.title;
    }
    setState(() => _isEditing = false);
    widget.onUpdate();
  }

  void _adjustTime(double delta) {
    if (delta.abs() < 2) return;

    int currentSeconds = widget.task.targetDurationSeconds;
    // Drag Up (Negative) -> Increase
    // Drag Down (Positive) -> Decrease
    if (delta < 0) {
      currentSeconds += 60;
    } else {
      currentSeconds -= 60;
    }
    // Clamp
    currentSeconds = currentSeconds.clamp(60, 21600);

    // Save & Notify
    widget.task.targetDurationSeconds = currentSeconds;
    widget.task.save();

    widget.onDurationChanged(currentSeconds);
    widget.onUpdate();
    HapticFeedback.selectionClick();
  }

  void _showTimeDialog() {
    int currentMins = widget.task.targetDurationSeconds ~/ 60;
    String value = currentMins.toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.colors.bgMiddle,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Set Duration (min)",
            style: TextStyle(color: widget.colors.textMain)),
        content: TextField(
          autofocus: true,
          keyboardType: TextInputType.number,
          style: TextStyle(color: widget.colors.textMain, fontSize: 24),
          textAlign: TextAlign.center,
          controller: TextEditingController(text: value),
          onChanged: (v) => value = v,
          onSubmitted: (_) {
            _updateDuration(value);
            Navigator.pop(ctx);
          },
          decoration: InputDecoration(
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: widget.colors.highlight)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: widget.colors.textMain)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel",
                style: TextStyle(color: widget.colors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              _updateDuration(value);
              Navigator.pop(ctx);
            },
            child:
                Text("Set", style: TextStyle(color: widget.colors.highlight)),
          ),
        ],
      ),
    );
  }

  void _updateDuration(String value) {
    int? mins = int.tryParse(value);
    if (mins != null && mins > 0) {
      int seconds = mins * 60;
      widget.task.targetDurationSeconds = seconds;
      widget.task.save();

      widget.onDurationChanged(seconds);
      widget.onUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final int seconds = widget.task.targetDurationSeconds;
    final int minutes = seconds ~/ 60;
    final String timeStr = "${minutes}m";

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        key: ValueKey(widget.task.id),
        startActionPane: ActionPane(
          motion: const ScrollMotion(),
          dismissible:
              DismissiblePane(onDismissed: () => widget.onDelete(widget.task)),
          children: [
            SlidableAction(
              onPressed: (_) => widget.onDelete(widget.task),
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => widget.onPin(widget.task),
              backgroundColor: Colors.orangeAccent,
              foregroundColor: Colors.white,
              icon: widget.task.isPinned
                  ? Icons.push_pin
                  : Icons.push_pin_outlined,
              label: 'Pin',
            ),
            SlidableAction(
              onPressed: (_) => widget.onArchive(widget.task),
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
              icon: Icons.archive,
              label: 'Archive',
              borderRadius:
                  const BorderRadius.horizontal(right: Radius.circular(16)),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.colors.bgMiddle,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: widget.task.isPinned
                    ? widget.colors.highlight
                    : widget.colors.bgBottom,
                width: widget.task.isPinned ? 1.5 : 1),
          ),
          child: Row(
            children: [
              // DRAGGABLE TIME BADGE
              GestureDetector(
                onTap: _showTimeDialog,
                onVerticalDragUpdate: (details) =>
                    _adjustTime(details.primaryDelta!),
                child: Container(
                  width: 50,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: widget.colors.bgTop,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    timeStr,
                    style: TextStyle(
                      color: widget.colors.highlight,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              GestureDetector(
                onTap: () => widget.onPlay(widget.task),
                child: Icon(Icons.play_circle_outline,
                    color: widget.colors.textSecondary, size: 20),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: _isEditing
                    ? TextField(
                        controller: _titleCtrl,
                        focusNode: _focusNode,
                        autofocus: true,
                        style: TextStyle(
                            color: widget.colors.textMain, fontSize: 16),
                        onSubmitted: (_) => _saveTitle(),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                    : GestureDetector(
                        onTap: () => setState(() => _isEditing = true),
                        child: Text(
                          widget.task.title,
                          style: TextStyle(
                              color: widget.colors.textMain,
                              fontSize: 16,
                              fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
              ),
              const SizedBox(width: 12),

              // CUSTOM CHECKBOX (Done/Undone Colors)
              GestureDetector(
                onTap: widget.onCheck,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: widget.task.isDone
                        ? widget.colors.done // Completed Color
                        : Colors.transparent, // Active Color
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: widget.task.isDone
                          ? widget.colors.done
                          : widget.colors.undone, // Undone Border
                      width: 2,
                    ),
                  ),
                  child: widget.task.isDone
                      ? Icon(Icons.check,
                          size: 18, color: widget.colors.textHighlighted)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
