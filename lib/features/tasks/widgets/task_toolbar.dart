import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import '../models/task_model.dart';
import '../../../core/widgets/app_toolbar_container.dart';

class TaskToolbar extends StatelessWidget {
  final AppColors colors;
  final TaskImportance importance;
  final bool isEvent, isHabit, hasLocation;
  final bool showSaveButton;

  final VoidCallback onSaveTap,
      onTimeTap,
      onDateTap,
      onFlagTap,
      onLocationTap,
      onHabitTap;

  const TaskToolbar({
    super.key,
    required this.colors,
    required this.importance,
    required this.isEvent,
    required this.isHabit,
    required this.hasLocation,
    required this.onSaveTap,
    required this.onTimeTap,
    required this.onDateTap,
    required this.onFlagTap,
    required this.onLocationTap,
    required this.onHabitTap,
    this.showSaveButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppToolbarContainer(
      colors: colors,
      child: Row(
        children: [
          // SCROLLABLE ICON AREA
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildIcon(Icons.access_time, onTimeTap),
                  _buildIcon(Icons.calendar_today, onDateTap),

                  // Flag
                  IconButton(
                    icon: Icon(
                        importance != TaskImportance.none
                            ? Icons.flag
                            : Icons.outlined_flag,
                        size: 24),
                    color: _getFlagColor(),
                    onPressed: onFlagTap,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),

                  // Location
                  _buildIcon(Icons.place, onLocationTap, isActive: hasLocation),

                  // Habit
                  _buildIcon(Icons.repeat, onHabitTap, isActive: isHabit),
                ],
              ),
            ),
          ),

          if (showSaveButton) ...[
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onSaveTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.textMain,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.send, color: colors.bgMain, size: 20),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getFlagColor() {
    switch (importance) {
      case TaskImportance.high:
        return colors.priorityHigh;
      case TaskImportance.medium:
        return colors.priorityMedium;
      case TaskImportance.low:
        return colors.priorityLow;
      default:
        return colors.textMain;
    }
  }

  Widget _buildIcon(IconData icon, VoidCallback onTap,
      {bool isActive = false}) {
    return IconButton(
      icon: Icon(icon, size: 24),
      color: isActive ? colors.highlight : colors.textMain,
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }
}
