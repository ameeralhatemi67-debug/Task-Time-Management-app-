import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:task_manager_app/core/theme/colorsettings.dart';
import '../models/task_model.dart';
import 'smart_task_card.dart';
import '../pages/task_edit_sheet.dart';

class TasksListView extends StatelessWidget {
  final List<TaskModel> activeTasks;
  final List<TaskModel> overdueTasks;
  final List<TaskModel> doneTasks;
  final AppColors colors;
  final Function(TaskModel) onTaskCheck;
  final Function(int, int) onReorder;
  final VoidCallback onUpdate;

  const TasksListView({
    super.key,
    required this.activeTasks,
    required this.overdueTasks,
    required this.doneTasks,
    required this.colors,
    required this.onTaskCheck,
    required this.onReorder,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    if (activeTasks.isEmpty && overdueTasks.isEmpty && doneTasks.isEmpty) {
      return _buildEmptyState();
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 20),
      // Animation proxy for drag items
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, Widget? child) {
            return ShakeTarget(child: child!);
          },
          child: child,
        );
      },
      itemCount: overdueTasks.length +
          (overdueTasks.isNotEmpty ? 1 : 0) +
          activeTasks.length +
          (doneTasks.isNotEmpty ? 1 : 0) +
          doneTasks.length,
      onReorder: (oldIndex, newIndex) {
        // Calculate offsets to map the flat list index back to the active list index
        int activeStartIndex =
            overdueTasks.isEmpty ? 0 : overdueTasks.length + 1;
        int activeEndIndex = activeStartIndex + activeTasks.length;

        // Only allow reordering within the "Active" section
        if (oldIndex >= activeStartIndex &&
            oldIndex < activeEndIndex &&
            newIndex >= activeStartIndex &&
            newIndex <= activeEndIndex) {
          onReorder(oldIndex - activeStartIndex, newIndex - activeStartIndex);
        }
      },
      itemBuilder: (context, index) {
        // --- 1. OVERDUE SECTION ---
        if (index < overdueTasks.length) {
          final t = overdueTasks[index];
          return Container(
            key: ValueKey(t.id),
            child: SmartTaskCard(
              task: t,
              colors: colors,
              onCheck: () => onTaskCheck(t),
              onLongPress: () {},
              onBodyTap: () => TaskEditSheet.show(context, t),
              onUpdate: onUpdate,
            ),
          );
        }

        int currentIndex = index - overdueTasks.length;

        // Overdue Divider
        if (overdueTasks.isNotEmpty) {
          if (currentIndex == 0) {
            return Container(
              key: const ValueKey('divider_overdue'),
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(children: [
                const Text("Overdue",
                    style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
                const SizedBox(width: 8),
                Expanded(
                    child: Divider(
                        color: Colors.red.withOpacity(0.3), thickness: 1)),
              ]),
            );
          }
          currentIndex--;
        }

        // --- 2. ACTIVE SECTION ---
        if (currentIndex < activeTasks.length) {
          final t = activeTasks[currentIndex];
          return Container(
            key: ValueKey(t.id),
            child: SmartTaskCard(
              task: t,
              colors: colors,
              onCheck: () => onTaskCheck(t),
              onLongPress: () {
                HapticFeedback.selectionClick();
              },
              onBodyTap: () => TaskEditSheet.show(context, t),
              onUpdate: onUpdate,
            ),
          );
        }

        currentIndex -= activeTasks.length;

        // --- 3. DONE SECTION ---
        if (doneTasks.isNotEmpty) {
          if (currentIndex == 0) {
            return Container(
              key: const ValueKey('divider_done'),
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Divider(
                  color: colors.textSecondary.withOpacity(0.2), thickness: 1),
            );
          }
          currentIndex--;
        }

        final t = doneTasks[currentIndex];
        return Container(
          key: ValueKey(t.id),
          child: SmartTaskCard(
            task: t,
            colors: colors,
            onCheck: () => onTaskCheck(t),
            onLongPress: () {},
            onBodyTap: () => TaskEditSheet.show(context, t),
            onUpdate: onUpdate,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined,
              size: 48, color: colors.textSecondary.withOpacity(0.2)),
          const SizedBox(height: 10),
          Text("No tasks for this day",
              style: TextStyle(color: colors.textSecondary.withOpacity(0.4))),
        ],
      ),
    );
  }
}

/// Helper Animation for Drag & Drop
class ShakeTarget extends StatefulWidget {
  final Widget child;
  const ShakeTarget({super.key, required this.child});
  @override
  State<ShakeTarget> createState() => _ShakeTargetState();
}

class _ShakeTargetState extends State<ShakeTarget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 120), vsync: this)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final angle = 0.015 * math.sin(_controller.value * math.pi * 2);
        return Transform.rotate(
            angle: angle, child: Opacity(opacity: 0.85, child: widget.child));
      },
    );
  }
}
