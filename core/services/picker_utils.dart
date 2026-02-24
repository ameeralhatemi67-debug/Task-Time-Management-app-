import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';

class PickerUtils {
  /// Shows a standardized DatePicker styled with the app's theme
  static Future<DateTime?> pickDate({
    required BuildContext context,
    required AppColors colors,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    return await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          // 1. Set the background and primary colors of the dialog
          colorScheme: ColorScheme.light(
            primary: colors.highlight, // Header background & selected day
            onPrimary: colors.textHighlighted, // Header text
            surface: colors.bgMiddle, // Dialog background
            onSurface: colors.textMain, // Calendar numbers
          ),
          // 2. FIX: Corrected from .fromStyle to .styleFrom
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor:
                  colors.highlight, // Buttons like "OK" and "CANCEL"
            ),
          ),
          dialogTheme: DialogThemeData(backgroundColor: colors.bgMiddle),
        ),
        child: child!,
      ),
    );
  }

  /// Shows a standardized TimePicker styled with the app's theme
  static Future<TimeOfDay?> pickTime({
    required BuildContext context,
    required AppColors colors,
    TimeOfDay? initialTime,
  }) async {
    return await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: colors.highlight,
            onPrimary: colors.textHighlighted,
            surface: colors.bgMiddle,
            onSurface: colors.textMain,
          ),
          // 2. FIX: Corrected from .fromStyle to .styleFrom
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: colors.highlight),
          ),
        ),
        child: child!,
      ),
    );
  }
}
