import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import 'package:task_manager_app/features/tasks/models/task_model.dart';
import 'package:task_manager_app/features/tasks/widgets/task_toolbar.dart';

class SmartAddToolbar extends StatelessWidget {
  final bool isHabitMode;
  final AppColors colors;

  // --- TASK STATE ---
  final TaskImportance importance;
  final bool showCategory;
  final bool hasLocation;
  final bool showSmartPopup;

  // --- ACTIONS ---
  final VoidCallback onSaveTap;
  final VoidCallback onFlagTap;
  final VoidCallback onLocationTap;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;
  final VoidCallback onCategoryTap;
  final VoidCallback onChecklistTap;
  final VoidCallback onSmartPopupTap;

  const SmartAddToolbar({
    super.key,
    required this.isHabitMode,
    required this.colors,
    // State
    required this.importance,
    required this.showCategory,
    required this.hasLocation,
    required this.showSmartPopup,
    // Actions
    required this.onSaveTap,
    required this.onFlagTap,
    required this.onLocationTap,
    required this.onDateTap,
    required this.onTimeTap,
    required this.onCategoryTap,
    required this.onChecklistTap,
    required this.onSmartPopupTap,
  });

  @override
  Widget build(BuildContext context) {
    // 1. HABIT MODE LAYOUT
    if (isHabitMode) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text("Creating Habit",
              style: TextStyle(
                  color: colors.completedWork,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onSaveTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: colors.completedWork,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.check, color: colors.bgMain, size: 20),
            ),
          ),
        ],
      );
    }

    // 2. TASK MODE LAYOUT (Standard Toolbar)
    return TaskToolbar(
      colors: colors,
      importance: importance,
      isEvent: false,
      isHabit: false,
      hasLocation: hasLocation,
      showSaveButton: true,
      onSaveTap: onSaveTap,
      onFlagTap: onFlagTap,
      onHabitTap: () {}, // Not used here, handled by parser/chips
      onLocationTap: onLocationTap,
      onDateTap: onDateTap,
      onTimeTap: onTimeTap,
    );
  }
}
