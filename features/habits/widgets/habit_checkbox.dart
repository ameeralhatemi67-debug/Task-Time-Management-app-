import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import '../models/habit_model.dart'; // Needed for HabitStatus enum

class HabitCheckbox extends StatelessWidget {
  final HabitStatus status;
  final bool isLocked;
  final bool isCompletedToday; // For daily tracking
  final VoidCallback onTap;
  final AppColors colors;
  final double size;
  final double borderRadius;
  final Color? priorityColor;

  const HabitCheckbox({
    super.key,
    required this.status,
    this.isLocked = false,
    this.isCompletedToday = false,
    required this.onTap,
    required this.colors,
    this.size = 40,
    this.borderRadius = 10,
    this.priorityColor,
  });

  @override
  Widget build(BuildContext context) {
    // 1. DETERMINE STATE
    final bool isFinished = status == HabitStatus.completed;
    final bool isFailed = status == HabitStatus.failed;
    final bool isChecked = isCompletedToday || isFinished;

    // 2. DETERMINE COLOR
    Color getBackgroundColor() {
      if (isLocked) return colors.bgMiddle; // Greyed out
      if (isFinished) return colors.completedWork; // #8A9A5B
      if (isFailed) return colors.priorityHigh.withOpacity(0.1); // Red tint
      if (isChecked) return colors.highlight; // Standard check
      return colors.bgTop; // Default empty
    }

    Color getBorderColor() {
      if (isLocked) return colors.textSecondary.withOpacity(0.1);
      if (isFinished) return colors.completedWork;
      if (isFailed) return colors.priorityHigh;
      if (isChecked) return colors.highlight;
      // Default priority border or grey
      return priorityColor ?? colors.textSecondary.withOpacity(0.3);
    }

    // 3. DETERMINE ICON
    IconData? getIcon() {
      if (isLocked) return Icons.lock;
      if (isFinished) return Icons.check_circle; // Double check or similar
      if (isFailed) return Icons.close;
      if (isChecked) return Icons.check;
      return null;
    }

    return GestureDetector(
      onTap: isLocked ? null : onTap, // Disable tap if locked
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: getBackgroundColor(),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: getBorderColor(),
            width: 2,
          ),
        ),
        child: Center(
          child: Icon(
            getIcon(),
            size: size * 0.6,
            color: (isLocked || !isChecked) && !isFailed
                ? colors.textSecondary.withOpacity(0.5) // Lock icon color
                : colors.textHighlighted, // Check/X icon color
          ),
        ),
      ),
    );
  }
}
