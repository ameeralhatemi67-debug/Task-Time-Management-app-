import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import '../models/habit_model.dart'; // Needed for HabitType enum

// -----------------------------------------------------------------------------
// 1. SIMPLE LABEL
// -----------------------------------------------------------------------------
class HabitFormLabel extends StatelessWidget {
  final String text;
  final AppColors colors;

  const HabitFormLabel(this.text, {super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: colors.textMain,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 2. TEXT FIELD
// -----------------------------------------------------------------------------
class HabitFormTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final AppColors colors;

  const HabitFormTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bgTop,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: colors.textMain),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: colors.textSecondary.withOpacity(0.5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 15,
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 3. TYPE SELECTOR (Weekly / Monthly / Yearly)
// -----------------------------------------------------------------------------
class HabitTypeSelector extends StatelessWidget {
  final HabitType selectedType;
  final Function(HabitType) onTypeChanged;
  final AppColors colors;

  const HabitTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildChip(HabitType.weekly, "Weekly"),
        const SizedBox(width: 10),
        _buildChip(HabitType.monthly, "Monthly"),
        const SizedBox(width: 10),
        _buildChip(HabitType.yearly, "Yearly"),
      ],
    );
  }

  Widget _buildChip(HabitType type, String label) {
    final bool isSelected = selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTypeChanged(type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? colors.highlight : colors.bgTop,
            borderRadius: BorderRadius.circular(10),
            border: isSelected ? null : Border.all(color: colors.bgBottom),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? colors.textHighlighted : colors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 4. STREAK GOAL COUNTER
// -----------------------------------------------------------------------------
class HabitStreakCounter extends StatelessWidget {
  final int streakGoal;
  final Function(int) onChanged;
  final AppColors colors;

  const HabitStreakCounter({
    super.key,
    required this.streakGoal,
    required this.onChanged,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        HabitFormLabel("Streak Goal", colors: colors),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colors.bgTop,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (streakGoal > 1) onChanged(streakGoal - 1);
                },
                child: Icon(Icons.remove, size: 18, color: colors.textMain),
              ),
              const SizedBox(width: 15),
              Text(
                "$streakGoal",
                style: TextStyle(
                  color: colors.textMain,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 15),
              GestureDetector(
                onTap: () => onChanged(streakGoal + 1),
                child: Icon(Icons.add, size: 18, color: colors.textMain),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 5. HISTORY CONTROLS (Reset, Revert, Undo, Forward)
// -----------------------------------------------------------------------------
class HabitHistoryControls extends StatelessWidget {
  final VoidCallback onReset;
  final VoidCallback onRevert;
  final VoidCallback onUndo;
  final VoidCallback onForward;
  final AppColors colors;

  const HabitHistoryControls({
    super.key,
    required this.onReset,
    required this.onRevert,
    required this.onUndo,
    required this.onForward,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Left Group (Destructive)
        _buildCircleBtn(Icons.replay, Colors.red, "Reset", onReset),
        const SizedBox(width: 15),
        _buildCircleBtn(Icons.remove, Colors.orange, "Revert", onRevert),

        const SizedBox(width: 40), // Gap
        // Right Group (Constructive)
        _buildCircleBtn(Icons.undo, colors.textSecondary, "Undo", onUndo),
        const SizedBox(width: 15),
        _buildCircleBtn(
          Icons.fast_forward,
          colors.highlight,
          "Forward",
          onForward,
        ),
      ],
    );
  }

  Widget _buildCircleBtn(
    IconData icon,
    Color color,
    String tooltip,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
