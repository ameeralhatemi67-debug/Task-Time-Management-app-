import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import '../models/habit_model.dart';
import '../widgets/habit_progress_grid.dart';

class HabitHistoryPanel extends StatelessWidget {
  final AppColors colors;
  final HabitModel previewHabit;
  final int completionCount;
  final DateTime startDate;

  // Goals
  final int streakGoal;
  final List<int> scheduledWeekdays;
  final int? totalGoalOverride; // Accept calculated goal from parent

  // Callbacks
  final Function(DateTime) onDateToggled;
  final VoidCallback onUndo;
  final VoidCallback onReset;
  final Function(int) onRemove;
  final Function(int) onAdd;

  const HabitHistoryPanel({
    super.key,
    required this.colors,
    required this.previewHabit,
    required this.completionCount,
    required this.startDate,
    required this.streakGoal,
    required this.scheduledWeekdays,
    this.totalGoalOverride,
    required this.onDateToggled,
    required this.onUndo,
    required this.onReset,
    required this.onRemove,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    // --- 1. DETERMINE LOGIC BASED ON TYPE ---
    int addAmount = 7;
    String addLabel = "+7 Days";
    int totalGoal = totalGoalOverride ?? 0;

    // Fallback calculation if override not provided (Safety)
    if (totalGoalOverride == null) {
      final now = DateTime.now();
      final daysActive = now.difference(startDate).inDays;
      switch (previewHabit.type) {
        case HabitType.weekly:
          final weeks = (daysActive / 7).ceil().clamp(1, 99999);
          totalGoal = weeks * streakGoal;
          break;
        case HabitType.monthly:
          final months = (daysActive / 30).ceil().clamp(1, 99999);
          totalGoal = months * streakGoal;
          break;
        case HabitType.yearly:
          final years = (daysActive / 365).ceil().clamp(1, 99999);
          totalGoal = years * streakGoal;
          break;
      }
    }

    // Set Labels
    switch (previewHabit.type) {
      case HabitType.weekly:
        addAmount = 7;
        addLabel = "+7 Days";
        break;
      case HabitType.monthly:
        addAmount = 20;
        addLabel = "+20 Days";
        break;
      case HabitType.yearly:
        addAmount = 90;
        addLabel = "+90 Days";
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 4),
          child: Text(
            "Preview & History",
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),

        // --- UNIFIED CONTAINER ---
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colors.bgMiddle,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // -----------------------------------------------------------
              // 1. TOP HALF: VISUAL GRID
              // -----------------------------------------------------------
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: _buildVisuals(),
              ),

              // -----------------------------------------------------------
              // 2. MIDDLE: DIVIDER WITH TOTAL TEXT
              // -----------------------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: colors.textSecondary.withOpacity(0.1),
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        "Total: $completionCount / $totalGoal days",
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: colors.textSecondary.withOpacity(0.1),
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
              ),

              // -----------------------------------------------------------
              // 3. BOTTOM HALF: ACTION BUTTONS (2x2)
              // -----------------------------------------------------------
              Padding(
                padding: const EdgeInsets.all(10), // Padding for buttons area
                child: Column(
                  children: [
                    // Row 1: Add/Remove
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.add_circle_outline,
                          label: addLabel,
                          onTap: () => onAdd(addAmount),
                        ),
                        Container(
                            width: 1,
                            height: 30,
                            color: colors.textSecondary.withOpacity(0.1)),
                        _buildActionButton(
                          icon: Icons.remove_circle_outline,
                          label: "-$addAmount Days",
                          onTap: () => onRemove(addAmount),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Divider(
                        color: colors.textSecondary.withOpacity(0.05),
                        indent: 40,
                        endIndent: 40),
                    const SizedBox(height: 10),
                    // Row 2: Reset/Undo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.refresh,
                          label: "Reset",
                          onTap: onReset,
                        ),
                        Container(
                            width: 1,
                            height: 30,
                            color: colors.textSecondary.withOpacity(0.1)),
                        _buildActionButton(
                          icon: Icons.undo,
                          label: "Undo",
                          onTap: onUndo,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- VISUALS ---
  Widget _buildVisuals() {
    // 1. WEEKLY VISUAL
    if (previewHabit.type == HabitType.weekly) {
      return SizedBox(
        // [EDIT HERE] Adjust height for Weekly Grid
        height: 80,
        child: FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.center,
          child: HabitProgressGrid(
            habit: previewHabit,
            colors: colors,
            isInteractive: true,
            onDateToggled: onDateToggled,
            barWidth: 24.0,
            barHeight: 40.0,
            spacing: 4.0,
          ),
        ),
      );
    }

    // 2. MONTHLY VISUAL
    if (previewHabit.type == HabitType.monthly) {
      return SizedBox(
        // [EDIT HERE] Adjust height for Monthly Grid
        height: 110,
        child: FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.center,
          child: HabitProgressGrid(
            habit: previewHabit,
            colors: colors,
            isInteractive: true,
            onDateToggled: onDateToggled,
            barWidth: 24.0,
            barHeight: 24.0,
            spacing: 4.0,
          ),
        ),
      );
    }

    // 3. YEARLY VISUAL
    return SizedBox(
      // [EDIT HERE] Adjust height for Yearly Grid
      height: 140,
      child: HabitProgressGrid(
        habit: previewHabit,
        colors: colors,
        isInteractive: true,
        onDateToggled: onDateToggled,
        barWidth: 12.0,
        barHeight: 12.0,
        spacing: 3.0,
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Icon(icon, color: colors.textMain, size: 24),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
