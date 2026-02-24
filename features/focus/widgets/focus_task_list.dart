import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import '../models/focus_task_model.dart';
import '../../../data/repositories/focus_repository.dart';
import 'focus_task_tile.dart';

class FocusTaskList extends StatefulWidget {
  final AppColors colors;
  final Function(FocusTaskModel) onPlay;
  final Function(FocusTaskModel, int) onTaskDurationChanged;
  final int stepMinutes;

  const FocusTaskList({
    super.key,
    required this.colors,
    required this.onPlay,
    required this.onTaskDurationChanged,
    required this.stepMinutes,
  });

  @override
  State<FocusTaskList> createState() => _FocusTaskListState();
}

class _FocusTaskListState extends State<FocusTaskList> {
  final FocusRepository _repo = FocusRepository();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<FocusTaskModel>>(
      valueListenable: _repo.box.listenable(),
      builder: (context, box, _) {
        // Use repo method if available, otherwise filter manually for Active tasks
        // Assuming we want active tasks here (not archived)
        final tasks = _repo.getActiveTasks();

        // Sort: Pinned first, then by date created (newest first)
        tasks.sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          return b.dateCreated.compareTo(a.dateCreated);
        });

        if (tasks.isEmpty) {
          return Center(
            child: Text(
              "No active focus tasks",
              style: TextStyle(
                color: widget.colors.textSecondary.withOpacity(0.3),
                fontSize: 14,
              ),
            ),
          );
        }

        return ShaderMask(
          shaderCallback: (Rect rect) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black,
                Colors.black,
                Colors.transparent
              ],
              stops: [0.0, 0.1, 0.9, 1.0],
            ).createShader(rect);
          },
          blendMode: BlendMode.dstIn,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return FocusTaskTile(
                key: ValueKey(task.id),
                task: task,
                colors: widget.colors,
                stepMinutes: widget.stepMinutes,
                onUpdate: () {
                  setState(() {});
                },
                onCheck: () async {
                  task.isDone = true;
                  task.save();
                },
                onPlay: widget.onPlay,
                onDurationChanged: (newDuration) {
                  widget.onTaskDurationChanged(task, newDuration);
                },
                // --- ADDED REQUIRED ARGUMENTS ---
                onPin: (t) async {
                  await _repo.togglePin(t);
                },
                onArchive: (t) async {
                  await _repo.toggleArchive(t);
                },
                onDelete: (t) async {
                  await _repo.deleteFocusTask(t.id);
                },
              );
            },
          ),
        );
      },
    );
  }
}
