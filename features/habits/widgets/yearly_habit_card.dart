import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import 'package:task_manager_app/data/repositories/habit_repository.dart';
import '../models/habit_model.dart';
import 'habit_progress_grid.dart';
import 'habit_checkbox.dart';

class YearlyHabitCard extends StatelessWidget {
  final HabitModel habit;
  final AppColors colors;
  final VoidCallback onTap;
  final VoidCallback onCheckToggle;
  final VoidCallback? onUpdate;

  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelectionToggle;

  const YearlyHabitCard({
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
    final bool isCompletedToday = habit.isCompletedOn(DateTime.now());
    final bool hasDescription = habit.description.isNotEmpty;
    final now = DateTime.now();

    final bool isScheduledToday = habit.isScheduledOn(now);
    final bool isTimeLocked = habit.isLocked;
    final bool isVisualLocked = !isScheduledToday || isTimeLocked;

    // Grid Dimensions Calculation
    const double squareSize = 14.0;
    const double spacing = 4.0;
    const double gridHeight = (squareSize * 7) + (spacing * 6);

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

    return ValueListenableBuilder(
      valueListenable: HabitRepository().prefsBox.listenable(),
      builder: (context, box, _) {
        final bool showBadges = HabitRepository().getShowHabitBadges();

        // --- ALIGNMENT LOGIC ---
        // If we have extra content (badges or description), we align to TOP (start).
        // If we ONLY have a title, we align to CENTER.
        final bool hasExtraContent =
            hasDescription || (showBadges && _hasBadges(habit));
        final CrossAxisAlignment rowAlignment = hasExtraContent
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center;

        // Only add top padding to checkbox if we are Top Aligned
        final EdgeInsets checkboxPadding =
            hasExtraContent ? const EdgeInsets.only(top: 2) : EdgeInsets.zero;

        Widget content = GestureDetector(
          onTap: isSelectionMode ? onSelectionToggle : onTap,
          onLongPress: isSelectionMode ? null : onSelectionToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.highlight.withOpacity(0.1)
                  : colors.bgMiddle,
              borderRadius: BorderRadius.circular(24),
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
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -------------------------------------------------------------
                // ROW 1: Checkbox (Left) | Title & Metadata (Right)
                // -------------------------------------------------------------
                Row(
                  crossAxisAlignment: rowAlignment, // <--- DYNAMIC ALIGNMENT
                  children: [
                    // LEFT: Checkbox
                    Padding(
                      padding: checkboxPadding, // <--- DYNAMIC PADDING
                      child: isSelectionMode
                          ? Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: isSelected
                                  ? colors.highlight
                                  : colors.textSecondary,
                              size: 24,
                            )
                          : IgnorePointer(
                              ignoring: isSelectionMode,
                              child: HabitCheckbox(
                                status: habit.status,
                                isCompletedToday: isCompletedToday,
                                isLocked: isVisualLocked,
                                colors: colors,
                                priorityColor: getPriorityColor(),
                                onTap: () {
                                  if (isVisualLocked) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text("Locked: Not active now"),
                                          backgroundColor: colors.bgTop),
                                    );
                                  } else {
                                    onCheckToggle();
                                  }
                                },
                              ),
                            ),
                    ),

                    const SizedBox(width: 12),

                    // RIGHT: Title, Desc, Badges
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // TITLE
                          Text(
                            habit.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textMain,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                              decoration: habit.status == HabitStatus.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),

                          // DESCRIPTION
                          if (hasDescription) ...[
                            const SizedBox(height: 2),
                            Text(
                              habit.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],

                          // BADGES
                          if (showBadges) ...[
                            if (_hasBadges(habit)) const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                // Focus Badge
                                if (habit.durationMode ==
                                    HabitDurationMode.focusTimer)
                                  _buildFocusBadge(habit.durationMinutes ?? 0),

                                // Schedule Badge
                                if (habit.durationMode ==
                                        HabitDurationMode.fixedWindow &&
                                    habit.activePeriodStart != null)
                                  _buildMetaTag(
                                    icon: Icons.access_time,
                                    label:
                                        "${habit.activePeriodStartString} - ${habit.activePeriodEndString}",
                                    color: isTimeLocked
                                        ? colors.priorityHigh
                                        : colors.textSecondary,
                                  ),

                                // Reminder Badge
                                if (habit.reminderTime != null)
                                  _buildMetaTag(
                                    icon: Icons.notifications_none,
                                    label: habit.reminderTimeString ?? "",
                                    color: colors.highlight,
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // -------------------------------------------------------------
                // ROW 2: The Grid (Full Width)
                // -------------------------------------------------------------
                SizedBox(
                  height: gridHeight,
                  child: HabitProgressGrid(
                    habit: habit,
                    colors: colors,
                    isInteractive: false,
                    barWidth: squareSize,
                    barHeight: squareSize,
                    spacing: spacing,
                  ),
                ),
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
                    const BorderRadius.horizontal(left: Radius.circular(24)),
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
                icon: habit.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
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
                    const BorderRadius.horizontal(right: Radius.circular(24)),
              ),
            ],
          ),
          child: content,
        );
      },
    );
  }

  bool _hasBadges(HabitModel h) {
    return (h.durationMode == HabitDurationMode.focusTimer) ||
        (h.durationMode == HabitDurationMode.fixedWindow &&
            h.activePeriodStart != null) ||
        (h.reminderTime != null);
  }

  Widget _buildMetaTag(
      {required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: colors.focusLink.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.focusLink.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.filter_center_focus, size: 10, color: colors.focusLink),
          const SizedBox(width: 4),
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
