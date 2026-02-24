import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import '../models/focus_task_model.dart';
import '../../../data/repositories/focus_repository.dart';

class FocusTaskCreationSheet extends StatefulWidget {
  final AppColors colors;

  const FocusTaskCreationSheet({super.key, required this.colors});

  static void show(BuildContext context, AppColors colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => FocusTaskCreationSheet(colors: colors),
    );
  }

  @override
  State<FocusTaskCreationSheet> createState() => _FocusTaskCreationSheetState();
}

class _FocusTaskCreationSheetState extends State<FocusTaskCreationSheet> {
  final TextEditingController _titleController = TextEditingController();
  final FocusRepository _repo = FocusRepository();

  int _selectedDurationSeconds = 1500; // Default 25 minutes

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final newTask = FocusTaskModel.create(
      title: title,
      targetDuration: _selectedDurationSeconds,
    );

    await _repo.addFocusTask(newTask);

    if (mounted) Navigator.pop(context);
  }

  void _adjustTime(double delta) {
    // Threshold to prevent jitter (must drag at least a bit)
    if (delta.abs() < 2) return;

    setState(() {
      // Drag Up (Negative) -> Increase Time
      // Drag Down (Positive) -> Decrease Time
      if (delta < 0) {
        _selectedDurationSeconds += 60; // +1 min
      } else {
        _selectedDurationSeconds -= 60; // -1 min
      }
      // Clamp between 1 min and 6 hours
      _selectedDurationSeconds = _selectedDurationSeconds.clamp(60, 21600);
    });
    HapticFeedback.selectionClick();
  }

  void _showTimeDialog() {
    String value = (_selectedDurationSeconds ~/ 60).toString();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.colors.bgMiddle,
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
    if (mins != null) {
      setState(() {
        _selectedDurationSeconds = (mins * 60).clamp(60, 21600);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: widget.colors.bgMain,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          border: Border(
            top: BorderSide(color: widget.colors.bgBottom, width: 1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: widget.colors.textSecondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "New Focus Task",
              style: TextStyle(
                color: widget.colors.textMain,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                // DRAGGABLE TIME WIDGET
                GestureDetector(
                  onTap: _showTimeDialog,
                  onVerticalDragUpdate: (details) =>
                      _adjustTime(details.primaryDelta!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: widget.colors.bgMiddle,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: widget.colors.textSecondary.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.unfold_more, // Changed icon to indicate drag
                            size: 16,
                            color: widget.colors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          "${_selectedDurationSeconds ~/ 60}m",
                          style: TextStyle(
                            color: widget.colors.highlight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: widget.colors.bgMiddle,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: _titleController,
                      autofocus: true,
                      style: TextStyle(color: widget.colors.textMain),
                      decoration: InputDecoration(
                        hintText: "What do you want to focus on?",
                        hintStyle: TextStyle(
                            color:
                                widget.colors.textSecondary.withOpacity(0.5)),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _save(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.colors.highlight,
                  foregroundColor: widget.colors.textHighlighted,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Add Task",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
