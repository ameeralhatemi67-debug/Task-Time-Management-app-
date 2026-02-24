import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color bgMain;
  final Color bgBottom;
  final Color bgMiddle;
  final Color bgTop;
  final Color highlight;
  final Color done;
  final Color undone;
  final Color textMain;
  final Color textSecondary;
  final Color textHighlighted;

  // Priority Colors
  final Color priorityHigh;
  final Color priorityMedium;
  final Color priorityLow;

  // NEW: Completed Work & Focus Link
  final Color completedWork;
  final Color focusLink; // <--- NEW PINK COLOR (#FFC1CC)

  const AppColors({
    required this.bgMain,
    required this.bgBottom,
    required this.bgMiddle,
    required this.bgTop,
    required this.highlight,
    required this.done,
    required this.undone,
    required this.textMain,
    required this.textSecondary,
    required this.textHighlighted,
    this.priorityHigh = const Color(0xFFE13E38),
    this.priorityMedium = const Color(0xFFFFB001),
    this.priorityLow = const Color(0xFF4773FA),
    this.completedWork = const Color(0xFF8A9A5B),
    this.focusLink = const Color.fromARGB(255, 212, 134, 148), // Default Pink
  });

  @override
  AppColors copyWith({
    Color? bgMain,
    Color? bgBottom,
    Color? bgMiddle,
    Color? bgTop,
    Color? highlight,
    Color? done,
    Color? undone,
    Color? textMain,
    Color? textSecondary,
    Color? textHighlighted,
    Color? priorityHigh,
    Color? priorityMedium,
    Color? priorityLow,
    Color? completedWork,
    Color? focusLink, // NEW
  }) {
    return AppColors(
      bgMain: bgMain ?? this.bgMain,
      bgBottom: bgBottom ?? this.bgBottom,
      bgMiddle: bgMiddle ?? this.bgMiddle,
      bgTop: bgTop ?? this.bgTop,
      highlight: highlight ?? this.highlight,
      done: done ?? this.done,
      undone: undone ?? this.undone,
      textMain: textMain ?? this.textMain,
      textSecondary: textSecondary ?? this.textSecondary,
      textHighlighted: textHighlighted ?? this.textHighlighted,
      priorityHigh: priorityHigh ?? this.priorityHigh,
      priorityMedium: priorityMedium ?? this.priorityMedium,
      priorityLow: priorityLow ?? this.priorityLow,
      completedWork: completedWork ?? this.completedWork,
      focusLink: focusLink ?? this.focusLink, // NEW
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bgMain: Color.lerp(bgMain, other.bgMain, t)!,
      bgBottom: Color.lerp(bgBottom, other.bgBottom, t)!,
      bgMiddle: Color.lerp(bgMiddle, other.bgMiddle, t)!,
      bgTop: Color.lerp(bgTop, other.bgTop, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      done: Color.lerp(done, other.done, t)!,
      undone: Color.lerp(undone, other.undone, t)!,
      textMain: Color.lerp(textMain, other.textMain, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHighlighted: Color.lerp(textHighlighted, other.textHighlighted, t)!,
      priorityHigh: Color.lerp(priorityHigh, other.priorityHigh, t)!,
      priorityMedium: Color.lerp(priorityMedium, other.priorityMedium, t)!,
      priorityLow: Color.lerp(priorityLow, other.priorityLow, t)!,
      completedWork: Color.lerp(completedWork, other.completedWork, t)!,
      focusLink: Color.lerp(focusLink, other.focusLink, t)!, // NEW
    );
  }

  // --- Defaults ---
  static const light = AppColors(
    bgMain: Color(0xFFD9D9D9),
    bgBottom: Color(0xFFE6E6E6),
    bgMiddle: Color(0xFFF2F2F2),
    bgTop: Color(0xFFFFFFFF),
    highlight: Color(0xFF333333),
    textMain: Color(0xFF0D0D0D),
    textSecondary: Color(0xFF4D4D4D),
    textHighlighted: Color(0xFFF2F2F2),
    done: Color(0xFF333333),
    undone: Color(0xFFCCCCCC),
    completedWork: Color(0xFF8A9A5B),
    focusLink: Color(0xFFFFC1CC), // Pink
  );

  static const dark = AppColors(
    bgMain: Color(0xFF0D0D0D),
    bgBottom: Color(0xFF1A1A1A),
    bgMiddle: Color(0xFF262626),
    bgTop: Color(0xFFF2F2F2),
    highlight: Color(0xFFCCCCCC),
    textMain: Color(0xFFF2F2F2),
    textSecondary: Color(0xFFB3B3B3),
    textHighlighted: Color(0xFF0D0D0D),
    done: Color(0xFFCCCCCC),
    undone: Color(0xFF333333),
    completedWork: Color(0xFF8A9A5B),
    focusLink: Color(0xFFFFC1CC), // Pink
  );
}

// ... ThemePreset class ...
class ThemePreset {
  final String id;
  String name;
  bool isLocked;
  AppColors lightColors;
  AppColors darkColors;

  ThemePreset({
    required this.id,
    required this.name,
    required this.lightColors,
    required this.darkColors,
    this.isLocked = false,
  });

  static ThemePreset original() {
    return ThemePreset(
      id: 'original',
      name: 'Original (Default)',
      isLocked: true,
      lightColors: AppColors.light,
      darkColors: AppColors.dark,
    );
  }

  ThemePreset clone(String newId, String newName) {
    return ThemePreset(
      id: newId,
      name: newName,
      isLocked: false,
      lightColors: lightColors.copyWith(),
      darkColors: darkColors.copyWith(),
    );
  }
}
