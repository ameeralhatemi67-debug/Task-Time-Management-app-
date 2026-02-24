import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Needed for ValueListenable
import 'package:task_manager_app/core/theme/colorsettings.dart';
import 'package:task_manager_app/data/repositories/habit_repository.dart'; // Needed for Settings
import '../models/habit_model.dart';
import 'habit_checkbox.dart';
import 'habit_progress_grid.dart';

class WeeklyHabitCard extends StatelessWidget {
  final HabitModel habit;
  final AppColors colors;
  final VoidCallback onTap;
  final VoidCallback onCheckToggle;
  final VoidCallback? onUpdate;

  // --- SELECTION MODE PROPS ---
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelectionToggle;

  const WeeklyHabitCard({
    super.key,
    required this.habit,
    required this.colors,
    required this.onTap,
    required this.onCheckToggle,
    this.onUpdate,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectionToggle,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final bool isScheduledToday = habit.isScheduledOn(now);
    final bool isTimeLocked = habit.isLocked;
    final bool isVisualLocked = !isScheduledToday || isTimeLocked;

    Color? getPriorityColor() {
      switch (habit.importance) {
        case HabitImportance.high:
          return colors.priorityHigh;
        case HabitImportance.medium:
          return colors.priorityMedium;
        case HabitImportance.low:
          return colors.priorityLow;
        default:
          return null;
      }
    }

    // Wrap in ValueListenableBuilder to listen to Settings (Show/Hide Badges)
    return ValueListenableBuilder(
        valueListenable: HabitRepository().prefsBox.listenable(),
        builder: (context, box, _) {
          final bool showBadges = HabitRepository().getShowHabitBadges();

          // --- WRAPPER: Disable Slidable in Selection Mode ---
          Widget content = GestureDetector(
            onTap: isSelectionMode ? onSelectionToggle : onTap,
            onLongPress: isSelectionMode ? null : onSelectionToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.highlight.withOpacity(0.1)
                    : colors.bgMiddle,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? colors.highlight
                      : (habit.isPinned
                          ? colors.highlight.withOpacity(0.5)
                          : Colors.transparent),
                  width: isSelected ? 2.5 : (habit.isPinned ? 1.5 : 0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 1. LEFT: Checkbox / Selection
                  if (isSelectionMode) ...[
                    Icon(
                      isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color:
                          isSelected ? colors.highlight : colors.textSecondary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                  ] else ...[
                    IgnorePointer(
                      ignoring: isSelectionMode,
                      child: HabitCheckbox(
                        status: habit.status,
                        isCompletedToday: habit.isCompletedOn(now),
                        isLocked: isVisualLocked,
                        colors: colors,
                        priorityColor: getPriorityColor(),
                        onTap: () {
                          if (isVisualLocked) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text("Locked"),
                              backgroundColor: colors.bgTop,
                            ));
                          } else {
                            onCheckToggle();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],

                  // 2. CENTER: Content (Max 2 Rows)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ROW 1: Title
                        Text(
                          habit.title,
                          style: TextStyle(
                            color: habit.status == HabitStatus.completed
                                ? colors.textSecondary
                                : colors.textMain,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            decoration: habit.status == HabitStatus.completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // ROW 2: Badges + Description
                        if (showBadges || habit.description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              // A. BADGES (Left Side)
                              if (showBadges)
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    // Focus Badge
                                    if (habit.durationMode ==
                                        HabitDurationMode.focusTimer)
                                      _buildFocusBadge(
                                          habit.durationMinutes ?? 0),

                                    // Schedule Badge
                                    if (habit.durationMode ==
                                            HabitDurationMode.fixedWindow &&
                                        habit.activePeriodStart != null)
                                      _buildMetaTag(
                                        icon: Icons.access_time,
                                        label:
                                            "${habit.activePeriodStartString}-${habit.activePeriodEndString}",
                                        color: isTimeLocked
                                            ? colors.priorityHigh
                                            : colors.textSecondary,
                                      ),

                                    // Reminder Badge (NEW)
                                    if (habit.reminderTime != null)
                                      _buildMetaTag(
                                        icon: Icons.notifications_none,
                                        label: habit.reminderTimeString ?? "",
                                        color: colors.highlight,
                                      ),
                                  ],
                                ),

                              // Spacing if both exist
                              if (showBadges &&
                                  _hasBadges() &&
                                  habit.description.isNotEmpty)
                                const SizedBox(width: 8),

                              // B. DESCRIPTION (Right Side - Truncated)
                              if (habit.description.isNotEmpty)
                                Expanded(
                                  child: Text(
                                    habit.description,
                                    maxLines: 1,
                                    overflow:
                                        TextOverflow.ellipsis, // Ends with ...
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ]
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 3. RIGHT: Progress Grid
                  if (!isSelectionMode) ...[
                    HabitProgressGrid(
                      habit: habit,
                      colors: colors,
                      isInteractive: false,
                      barWidth: 8.0,
                      barHeight: 32.0,
                      spacing: 3.0,
                    ),
                  ],
                ],
              ),
            ),
          );

          if (isSelectionMode) return content;

          return Slidable(
            key: ValueKey(habit.id),
            startActionPane: ActionPane(
              motion: const ScrollMotion(),
              dismissible: DismissiblePane(onDismissed: () {
                habit.delete();
                if (onUpdate != null) onUpdate!();
              }),
              children: [
                SlidableAction(
                  onPressed: (_) {
                    habit.delete();
                    if (onUpdate != null) onUpdate!();
                  },
                  backgroundColor: Colors.red,
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
                  onPressed: (_) {
                    habit.isPinned = !habit.isPinned;
                    habit.save();
                    if (onUpdate != null) onUpdate!();
                  },
                  backgroundColor: colors.highlight,
                  foregroundColor: colors.textHighlighted,
                  icon:
                      habit.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                  label: habit.isPinned ? 'Unpin' : 'Pin',
                ),
                SlidableAction(
                  onPressed: (_) {
                    habit.isArchived = !habit.archived;
                    habit.save();
                    if (onUpdate != null) onUpdate!();
                  },
                  backgroundColor: colors.textSecondary,
                  foregroundColor: colors.bgMain,
                  icon: Icons.archive,
                  label: 'Archive',
                  borderRadius:
                      const BorderRadius.horizontal(right: Radius.circular(16)),
                ),
              ],
            ),
            child: content,
          );
        });
  }

  // Helper to check if any badges will be rendered
  bool _hasBadges() {
    return (habit.durationMode == HabitDurationMode.focusTimer) ||
        (habit.durationMode == HabitDurationMode.fixedWindow &&
            habit.activePeriodStart != null) ||
        (habit.reminderTime != null);
  }

  Widget _buildMetaTag(
      {required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFocusBadge(int minutes) {
    final String label = minutes > 0 ? "$minutes m" : "Focus";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: colors.focusLink.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colors.focusLink.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_center_focus, size: 10, color: colors.focusLink),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  color: colors.focusLink,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
