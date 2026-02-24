import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import '../models/task_model.dart';
import 'package:task_manager_app/features/habits/models/habit_model.dart';
import 'package:task_manager_app/features/habits/widgets/habit_progress_grid.dart';
import 'package:task_manager_app/features/habits/widgets/habit_form_components.dart';

// --- CONFIGURATION ---
// Edit these values to change the grid layout manually
const double kGridPillWidth = 30.0;
const double kGridPillHeight = 65.0;
const double kGridSpacing = 7.0;

class HabitDashboard extends StatelessWidget {
  final TaskModel task;
  final AppColors colors;

  // Logic Callbacks
  final Function(DateTime) onDateToggled;
  final VoidCallback onReset;
  final VoidCallback onRevert;
  final VoidCallback onUndo;
  final VoidCallback onForward;
  final Function(int) onGoalChanged;
  final Function(bool) onStreakModeChanged;

  const HabitDashboard({
    super.key,
    required this.task,
    required this.colors,
    required this.onDateToggled,
    required this.onReset,
    required this.onRevert,
    required this.onUndo,
    required this.onForward,
    required this.onGoalChanged,
    required this.onStreakModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    // 1. CALCULATE PROGRESS & LIMITS
    final int goal = (task.habitGoal != null && task.habitGoal! > 0)
        ? task.habitGoal!
        : 7; // Default to 7

    final int currentProgress = task.isStreakCount
        ? (task.habitStreak ?? 0)
        : (task.completedHistory?.length ?? 0);

    // Create a temporary HabitModel to reuse the Grid visualization
    final tempHabit = HabitModel(
      id: task.id,
      title: task.title,
      description: "",
      typeString: 'weekly',
      streakGoal: goal,
      completedDaysList: task.completedHistory ?? [],
      scheduledWeekdays: [],
      startDate: task.dateCreated,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- HEADER ---
        Row(
          children: [
            Icon(Icons.repeat, size: 16, color: colors.priorityLow),
            const SizedBox(width: 8),
            Text(
              "Habit Settings",
              style: TextStyle(
                color: colors.priorityLow,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),

        // --- SETTINGS ROW ---
        Row(
          children: [
            // GOAL CARD
            Expanded(
              child: GestureDetector(
                onTap: () => _showGoalDialog(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.bgBottom,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text("Goal (Days)",
                          style: TextStyle(
                              color: colors.textSecondary, fontSize: 10)),
                      const SizedBox(height: 4),
                      Text("${task.habitGoal ?? 'None'}",
                          style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // MODE CARD
            Expanded(
              child: GestureDetector(
                onTap: () => onStreakModeChanged(!task.isStreakCount),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.bgBottom,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: task.isStreakCount
                            ? colors.highlight
                            : Colors.transparent),
                  ),
                  child: Column(
                    children: [
                      Text(
                        task.isStreakCount ? "Streak Mode" : "Total Mode",
                        style: TextStyle(
                            color: colors.textSecondary, fontSize: 10),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        task.isStreakCount
                            ? Icons.local_fire_department
                            : Icons.functions,
                        color: colors.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // --- PROGRESS & HISTORY ---
        Text("Progress & History",
            style: TextStyle(color: colors.textSecondary, fontSize: 12)),
        const SizedBox(height: 10),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.bgBottom,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              // 1. ORIGINAL GRID DESIGN (Preserved, now editable via consts)
              HabitProgressGrid(
                habit: tempHabit,
                colors: colors,
                isInteractive: true, // Allow tapping days directly
                // Pass editable dimensions here:
                barWidth: kGridPillWidth,
                barHeight: kGridPillHeight,
                spacing: kGridSpacing,

                onDateToggled: (date) {
                  // CAP LOGIC FOR DIRECT DATE TAPPING
                  bool isDateSelected = task.completedHistory?.any((d) =>
                          d.year == date.year &&
                          d.month == date.month &&
                          d.day == date.day) ??
                      false;

                  if (!isDateSelected && currentProgress >= goal) {
                    _showCapReachedMessage(context, colors);
                  } else {
                    onDateToggled(date);
                  }
                },
              ),

              const SizedBox(height: 25),

              // 2. CONTROLS WITH CAP LOGIC
              HabitHistoryControls(
                colors: colors,
                onReset: onReset,
                onRevert: onRevert,
                onUndo: onUndo,
                // CAP LOGIC: Only allow forward if goal not met
                onForward: () {
                  if (currentProgress < goal) {
                    onForward();
                  } else {
                    _showCapReachedMessage(context, colors);
                  }
                },
              ),

              const SizedBox(height: 10),

              // 3. COUNTER TEXT
              Text(
                task.isStreakCount
                    ? "Current Streak: $currentProgress / $goal"
                    : "Total Completions: $currentProgress / $goal",
                style: TextStyle(
                  color: colors.textMain,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCapReachedMessage(BuildContext context, AppColors colors) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Goal Reached! Good job."),
      backgroundColor: colors.priorityLow,
      duration: const Duration(milliseconds: 1000),
    ));
  }

  void _showGoalDialog(BuildContext context) {
    String val = task.habitGoal?.toString() ?? "";
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgMiddle,
        title: Text("Set Goal", style: TextStyle(color: colors.textMain)),
        content: TextField(
          keyboardType: TextInputType.number,
          style: TextStyle(color: colors.textMain),
          controller: TextEditingController(text: val),
          decoration: InputDecoration(
              hintText: "Number of days",
              hintStyle: TextStyle(color: colors.textSecondary)),
          onChanged: (v) => val = v,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              onGoalChanged(int.tryParse(val) ?? 0);
              Navigator.pop(ctx);
            },
            child: Text("Save", style: TextStyle(color: colors.highlight)),
          ),
        ],
      ),
    );
  }
}
