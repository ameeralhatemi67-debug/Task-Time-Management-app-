import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import 'package:task_manager_app/data/repositories/habit_repository.dart';
import '../models/habit_model.dart';
import 'habit_progress_grid.dart';
import 'habit_checkbox.dart';

class MonthlyHabitCard extends StatelessWidget {
  final HabitModel habit;
  final AppColors colors;
  final VoidCallback onTap;
  final VoidCallback onCheckToggle;
  final VoidCallback? onUpdate;

  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelectionToggle;

  const MonthlyHabitCard({
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
    final int totalCount = habit.completedDaysList.length;
    final bool hasDescription = habit.description.isNotEmpty;
    final now = DateTime.now();

    final bool isScheduledToday = habit.isScheduledOn(now);
    final bool isTimeLocked = habit.isLocked;
    final bool isVisualLocked = !isScheduledToday || isTimeLocked;
    final bool isFinished = habit.status == HabitStatus.completed;

    // Ordinal suffix logic
    String suffix = "th";
    if (totalCount % 100 < 11 || totalCount % 100 > 13) {
      switch (totalCount % 10) {
        case 1:
          suffix = "st";
          break;
        case 2:
          suffix = "nd";
          break;
        case 3:
          suffix = "rd";
          break;
      }
    }
    final String countString = "$totalCount$suffix";

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

        Widget content = GestureDetector(
          onTap: isSelectionMode ? onSelectionToggle : onTap,
          onLongPress: isSelectionMode ? null : onSelectionToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.highlight.withOpacity(0.1)
                  : colors.bgMiddle,

              // -------------------------------------------------------------
              // [EDIT HERE] CARD ROUNDED CORNERS
              // Change '32.0' to make the card more or less rounded.
              // -------------------------------------------------------------
              borderRadius: BorderRadius.circular(14.0),

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
                // --- TOP ROW ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (isSelectionMode) ...[
                      Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isSelected
                            ? colors.highlight
                            : colors.textSecondary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                    ] else ...[
                      IgnorePointer(
                        ignoring: isSelectionMode,
                        child: HabitCheckbox(
                          status: habit.status,
                          isCompletedToday: isCompletedToday,
                          isLocked: isVisualLocked,
                          colors: colors,
                          priorityColor: getPriorityColor(),
                          onTap: () {
                            if (isVisualLocked) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text("Locked"),
                                backgroundColor: colors.bgTop,
                              ));
                            } else {
                              onCheckToggle();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.title,
                            style: TextStyle(
                              color: colors.textMain,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              decoration: habit.status == HabitStatus.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (hasDescription) ...[
                            const SizedBox(height: 4),
                            Text(
                              habit.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (showBadges)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (habit.durationMode ==
                              HabitDurationMode.focusTimer) ...[
                            _buildFocusBadge(habit.durationMinutes ?? 0),
                            const SizedBox(height: 4),
                          ],
                          if (habit.durationMode ==
                                  HabitDurationMode.fixedWindow &&
                              habit.activePeriodStart != null) ...[
                            _buildMetaTag(
                              icon: Icons.access_time,
                              label:
                                  "${habit.activePeriodStartString}-${habit.activePeriodEndString}",
                              color: isTimeLocked
                                  ? colors.priorityHigh
                                  : colors.textSecondary,
                            ),
                            const SizedBox(height: 4),
                          ],
                          if (habit.reminderTime != null)
                            _buildMetaTag(
                              icon: Icons.notifications_none,
                              label: habit.reminderTimeString ?? "",
                              color: colors.highlight,
                            ),
                        ],
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                // --- BOTTOM ROW: Grid (Fixed Squares) ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 90, // Container height for grid
                        child: FittedBox(
                          fit: BoxFit.contain,
                          alignment: Alignment.centerLeft,
                          child: HabitProgressGrid(
                            habit: habit,
                            colors: colors,
                            isInteractive: false,

                            // -----------------------------------------------------------
                            // [EDIT HERE] GRID SHAPE
                            // 1. To make Squares: Set width equal to height (e.g. 24, 24)
                            // 2. To make Pills:   Set height > width (e.g. 10, 24)
                            // 3. To make Bars:    Set width > height (e.g. 40, 10)
                            // -----------------------------------------------------------
                            barWidth: 24.0,
                            barHeight: 24.0,
                            spacing: 4.0, // Space between squares
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (isFinished)
                          Icon(Icons.flag, size: 18, color: colors.done),
                        Text(
                          countString,
                          style: TextStyle(
                            color: isFinished
                                ? colors.done
                                : colors.textSecondary.withOpacity(0.5),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
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
                // Match borderRadius with Card
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(32)),
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
                // Match borderRadius with Card
                borderRadius:
                    const BorderRadius.horizontal(right: Radius.circular(32)),
              ),
            ],
          ),
          child: content,
        );
      },
    );
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
