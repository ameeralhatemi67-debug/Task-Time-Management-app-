import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';

class TaskCountIndicator extends StatelessWidget {
  final int count;
  final bool hasHighPriority;
  final AppColors colors;
  final bool isSelected;

  const TaskCountIndicator({
    super.key,
    required this.count,
    required this.hasHighPriority,
    required this.colors,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox(height: 4);

    // Color Logic: High Priority takes precedence, then Selection, then Default
    Color color;
    if (hasHighPriority) {
      color = colors.priorityHigh;
    } else if (isSelected) {
      color = colors.textHighlighted;
    } else {
      color = colors.textSecondary.withOpacity(0.5);
    }

    // "Busy" Line Mode (> 5 tasks)
    if (count > 5) {
      return Container(
        margin: const EdgeInsets.only(top: 4),
        width: 20,
        height: 3,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    }

    // Dot Mode (1-5 tasks)
    return Container(
      margin: const EdgeInsets.only(top: 4),
      height: 4,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }
}
