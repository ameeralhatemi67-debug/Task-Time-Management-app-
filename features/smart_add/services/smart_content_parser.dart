import 'package:flutter/foundation.dart'; // For compute
import 'package:chrono_dart/chrono_dart.dart';
import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart'; // Required for AppColors signature
import 'package:task_manager_app/features/tasks/models/task_model.dart';
import 'package:task_manager_app/features/habits/models/habit_model.dart';
import 'package:task_manager_app/features/smart_add/widgets/smart_add_chips.dart';
import 'keyword_dictionary.dart';

// -----------------------------------------------------------------------------
// 1. DATA CLASSES
// -----------------------------------------------------------------------------

class HabitParsingConfig {
  final HabitType type;
  final List<int> scheduledDays;
  final int streakGoal;

  HabitParsingConfig({
    required this.type,
    this.scheduledDays = const [],
    this.streakGoal = 3,
  });
}

class SmartParseResult {
  final String originalText;
  final String cleanTitle;

  // Task Basics
  final DateTime? startTime;
  final TimeOfDay? reminderTime;
  final TaskImportance? importance;
  final String? potentialFolder;
  final String? recurrenceRule;
  final String? location;

  // Focus Specifics
  final int? durationMinutes;
  final int pomodoroCount;

  // INTENT FLAGS
  final bool isFocusIntent;
  final bool isPotentialFocus;

  // HABIT FLAGS
  final HabitParsingConfig? habitConfig;
  final HabitDurationMode? habitDurationMode;

  // SUGGESTIONS
  final bool suggestFocus;
  final bool suggestHabit;
  final TaskImportance? suggestedImportance;

  // FUSION: Restored Split Intent
  final bool isSplitPotential;

  SmartParseResult({
    required this.originalText,
    required this.cleanTitle,
    this.startTime,
    this.reminderTime,
    this.importance,
    this.potentialFolder,
    this.recurrenceRule,
    this.location,
    this.durationMinutes,
    this.pomodoroCount = 1,
    this.isFocusIntent = false,
    this.isPotentialFocus = false,
    this.habitConfig,
    this.habitDurationMode,
    this.suggestFocus = false,
    this.suggestHabit = false,
    this.suggestedImportance,
    this.isSplitPotential = false,
  });
}

// -----------------------------------------------------------------------------
// 2. ISOLATED LOGIC (The "Brain")
// -----------------------------------------------------------------------------

// BATCH PROCESSOR (Multi-Line for Camera)
List<SmartParseResult> _parseBatchIsolated(String rawText) {
  String refinedText = rawText;

  // A. PRE-PROCESSING (Fix OCR Blobs)
  refinedText = refinedText.replaceAll(
      RegExp(r'(?<=\s)O\s+'), '\n'); // "O Item" -> Bullet
  refinedText = refinedText.replaceAll(RegExp(r'(?<=\s)[-•*]\s+'), '\n');
  refinedText = refinedText
      .replaceAll(RegExp(r'[|]'), 'I') // "|" -> "I"
      .replaceAll(RegExp(r'\b0\b'), 'O') // "0" -> "O"
      .replaceAll(RegExp(r'\b5(?=[a-z])'), 'S'); // "5tart" -> "Start"

  // B. MULTI-LINE SPLITTING
  List<String> lines = refinedText
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  // C. PROCESS EACH LINE
  List<SmartParseResult> results = [];
  for (String line in lines) {
    if (line.length < 2) continue;
    results.add(_parseSingleLine(line));
  }
  return results;
}

// SINGLE LINE PARSER (The Core Fusion Logic)
SmartParseResult _parseSingleLine(String text) {
  String workingText = text;
  String lowerText = text.toLowerCase();

  // ---------------------------------------------------------------------------
  // 0. TYPO CORRECTION & SYNONYM MATCHING
  // ---------------------------------------------------------------------------
  bool detectedTypoFocus = false;
  bool detectedTypoHabit = false;
  String? detectedTypoImportanceKey;

  KeywordDictionary.typoMap.forEach((typo, actual) {
    if (lowerText.contains(typo)) {
      if (KeywordDictionary.focusSynonyms.contains(actual) ||
          actual == 'focus') {
        detectedTypoFocus = true;
      }
      if (KeywordDictionary.habitSynonyms.contains(actual)) {
        detectedTypoHabit = true;
      }
      if (KeywordDictionary.importanceMap.containsKey(actual)) {
        detectedTypoImportanceKey = actual;
      }
    }
  });

  bool detectedFocusIntent = false;
  bool suggestFocus = detectedTypoFocus;

  // ---------------------------------------------------------------------------
  // 1. FOCUS & DURATION DETECTION
  // ---------------------------------------------------------------------------
  final durationRegex = RegExp(
      r'\b(\d+(?:\.\d+)?)\s*(m|min|mins|minutes?|h|hr|hours?)\b',
      caseSensitive: false);

  final pomodoroRegex =
      RegExp(r'\b(\d+)\s*(?:pomo|pomodoro(?:s)?)\b', caseSensitive: false);

  int? extractedDuration;
  int extractedCount = 1;

  if (pomodoroRegex.hasMatch(workingText)) {
    final match = pomodoroRegex.firstMatch(workingText)!;
    extractedCount = int.tryParse(match.group(1)!) ?? 1;
    extractedDuration = 25;
    detectedFocusIntent = true;
    workingText = workingText.replaceAll(match.group(0)!, '');
  } else if (durationRegex.hasMatch(workingText)) {
    final match = durationRegex.firstMatch(workingText)!;
    final val = double.tryParse(match.group(1)!) ?? 0;
    final unit = match.group(2)!.toLowerCase();

    if (unit.startsWith('h')) {
      extractedDuration = (val * 60).round();
    } else {
      extractedDuration = val.round();
    }
    suggestFocus = true;
    workingText = workingText.replaceAll(match.group(0)!, '');
  }

  for (var word in KeywordDictionary.focusSynonyms) {
    if (lowerText.contains(word)) {
      if (['focus', 'concentrate', 'deep work', 'session', 'pomo']
          .contains(word)) {
        detectedFocusIntent = true;
      } else {
        suggestFocus = true;
      }
      if (word == 'focus' || word == 'pomodoro') {
        final regex = RegExp('\\b$word\\b', caseSensitive: false);
        workingText = workingText.replaceAll(regex, '');
      }
    }
  }

  final rangeRegex = RegExp(
      r'\b(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\s*(?:-|to)\s*(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\b',
      caseSensitive: false);
  if (rangeRegex.hasMatch(workingText)) {
    detectedFocusIntent = true;
  }

  // ---------------------------------------------------------------------------
  // 2. IMPORTANCE DETECTION
  // ---------------------------------------------------------------------------
  TaskImportance? extractedImportance;
  TaskImportance? suggestedImportance;

  KeywordDictionary.importanceMap.forEach((key, value) {
    if (lowerText.contains(key)) {
      extractedImportance = value;
      final regex = RegExp('\\b${RegExp.escape(key)}\\b', caseSensitive: false);
      workingText = workingText.replaceAll(regex, '');
    }
  });

  if (extractedImportance == null && detectedTypoImportanceKey != null) {
    suggestedImportance =
        KeywordDictionary.importanceMap[detectedTypoImportanceKey];
  }

  // ---------------------------------------------------------------------------
  // 3. FOLDER & LOCATION DETECTION
  // ---------------------------------------------------------------------------
  String? extractedFolder;
  final tagRegex = RegExp(r'#(\w+)', caseSensitive: false);
  final tagMatch = tagRegex.firstMatch(workingText);
  if (tagMatch != null) {
    extractedFolder = tagMatch.group(1);
    workingText = workingText.replaceAll(tagMatch.group(0)!, '');
  }

  String? extractedLocation;
  for (var loc in KeywordDictionary.locationKeywords) {
    if (loc.length > 2 && lowerText.contains(loc)) {
      extractedLocation = loc;
      break;
    }
  }

  if (extractedLocation == null) {
    final prepositionLocRegex =
        RegExp(r'\b(?:at|in|near|by)\s+([A-Za-z0-9\s]+)', caseSensitive: false);
    final match = prepositionLocRegex.firstMatch(workingText);
    if (match != null) {
      String potential = match.group(1)!;
      if (!potential.contains(RegExp(r'\d'))) {
        extractedLocation = potential;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 4. HABIT DETECTION
  // ---------------------------------------------------------------------------
  HabitParsingConfig? extractedHabitConfig;
  String? recurrenceDisplayString;
  bool explicitHabitKeyword = false;

  if (lowerText.contains("everyday")) {
    workingText = workingText.replaceAll(
        RegExp(r'everyday', caseSensitive: false), 'daily');
    lowerText = workingText.toLowerCase();
  }

  if (lowerText.contains("habit") ||
      lowerText.contains("routine") ||
      lowerText.contains("every")) {
    explicitHabitKeyword = true;
    workingText = workingText.replaceAll(
        RegExp(r'\b(habit|routine)\b', caseSensitive: false), '');
  }

  final dailyRegex = RegExp(r'\b(daily|every day)\b', caseSensitive: false);
  final weeklyRegex = RegExp(r'\b(weekly|every week)\b', caseSensitive: false);
  final monthlyRegex = RegExp(
      r'\b(?:every|on the)\s+(\d{1,2})(?:st|nd|rd|th)\b',
      caseSensitive: false);
  final yearlyRegex = RegExp(r'\b(yearly|every year)\b', caseSensitive: false);

  if (dailyRegex.hasMatch(workingText)) {
    extractedHabitConfig = HabitParsingConfig(
        type: HabitType.weekly, scheduledDays: [1, 2, 3, 4, 5, 6, 7]);
    recurrenceDisplayString = "Daily";
    workingText = workingText.replaceAll(dailyRegex, '');
  } else if (yearlyRegex.hasMatch(workingText)) {
    extractedHabitConfig =
        HabitParsingConfig(type: HabitType.yearly, streakGoal: 1);
    recurrenceDisplayString = "Yearly";
    workingText = workingText.replaceAll(yearlyRegex, '');
  } else if (monthlyRegex.hasMatch(workingText)) {
    final match = monthlyRegex.firstMatch(workingText)!;
    int day = int.tryParse(match.group(1)!) ?? 1;
    extractedHabitConfig = HabitParsingConfig(
        type: HabitType.monthly, scheduledDays: [day], streakGoal: 3);
    recurrenceDisplayString = "Monthly: $day";
    workingText = workingText.replaceAll(match.group(0)!, '');
  } else if (weeklyRegex.hasMatch(workingText)) {
    extractedHabitConfig = HabitParsingConfig(
        type: HabitType.weekly, scheduledDays: [DateTime.now().weekday]);
    recurrenceDisplayString = "Weekly";
    workingText = workingText.replaceAll(weeklyRegex, '');
  } else {
    List<int> days = _parseWeekdaysIsolated(lowerText);
    if (days.isNotEmpty) {
      extractedHabitConfig =
          HabitParsingConfig(type: HabitType.weekly, scheduledDays: days);
      recurrenceDisplayString = "Weekly: ${days.length} days";
    }
  }

  // ---------------------------------------------------------------------------
  // 5. CHRONO TIME PARSING
  // ---------------------------------------------------------------------------
  DateTime? extractedDate;
  TimeOfDay? extractedTime;

  KeywordDictionary.timeKeywords.forEach((key, time) {
    if (lowerText.contains(key)) {
      extractedTime = time;
      workingText = workingText.replaceAll(
          RegExp('\\b$key\\b', caseSensitive: false), '');
    }
  });

  final results = Chrono.parse(workingText);
  if (results.isNotEmpty) {
    final result = results.first;
    final dt = result.date();

    final timeIndicatorsRegex = RegExp(
        r'(\d{1,2}:\d{2})|am|pm|noon|night|evening|morning|midnight',
        caseSensitive: false);

    if (timeIndicatorsRegex.hasMatch(result.text)) {
      extractedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
      extractedDate = dt;
    } else {
      extractedDate = DateTime(dt.year, dt.month, dt.day);
    }

    final int startIndex = result.index.toInt();
    final int length = result.text.length;
    if (startIndex >= 0 && startIndex + length <= workingText.length) {
      workingText =
          workingText.replaceRange(startIndex, startIndex + length, '');
    }
  }

  // ---------------------------------------------------------------------------
  // 6. FUSION: SPLIT INTENT DETECTION
  // ---------------------------------------------------------------------------
  bool isSplit = false;
  // If we found a Habit Config AND (Importance OR a specific Date/Time)
  // This implies the user might want a Task ("Do X Now") AND a Habit ("Do X Daily")
  if (extractedHabitConfig != null) {
    bool hasStrongTaskSignal = (extractedImportance == TaskImportance.high) ||
        (extractedDate != null && extractedTime != null);

    if (hasStrongTaskSignal) {
      // Check for connector words like "and", "also", "plus"
      // We check the original lowerText for these connectors
      if (lowerText.contains(' and ') ||
          lowerText.contains(' also ') ||
          lowerText.contains(' plus ')) {
        isSplit = true;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 7. FINAL BUILD
  // ---------------------------------------------------------------------------
  workingText = workingText.trim();
  final verbRegex =
      RegExp(r'^(do|make|create|need to|must)\s+', caseSensitive: false);
  if (verbRegex.hasMatch(workingText)) {
    workingText = workingText.replaceFirst(verbRegex, '');
  }

  String finalTitle = workingText.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (finalTitle.isNotEmpty) {
    // Capitalize first letter
    finalTitle = "${finalTitle[0].toUpperCase()}${finalTitle.substring(1)}";
  }

  bool isHabit = (extractedHabitConfig != null) || explicitHabitKeyword;
  HabitDurationMode finalDurationMode = HabitDurationMode.anyTime;

  if (isHabit) {
    if (extractedDuration != null || detectedFocusIntent) {
      finalDurationMode = HabitDurationMode.focusTimer;
    }
  }

  return SmartParseResult(
    originalText: text,
    cleanTitle: finalTitle.isEmpty ? "New Session" : finalTitle,
    startTime: extractedDate,
    reminderTime: extractedTime,
    importance: extractedImportance,
    potentialFolder: extractedFolder,
    recurrenceRule: recurrenceDisplayString,
    location: extractedLocation,
    durationMinutes: extractedDuration,
    pomodoroCount: extractedCount,
    isFocusIntent: detectedFocusIntent,
    isPotentialFocus: suggestFocus,
    habitConfig: extractedHabitConfig,
    habitDurationMode: isHabit ? finalDurationMode : null,
    suggestHabit: !isHabit && (explicitHabitKeyword || detectedTypoHabit),
    suggestedImportance: suggestedImportance,
    isSplitPotential: isSplit, // <--- FUSION FLAG
  );
}

// Helper
List<int> _parseWeekdaysIsolated(String text) {
  Set<int> days = {};
  String lower = text.toLowerCase();
  if (lower.contains('mon')) days.add(1);
  if (lower.contains('tue')) days.add(2);
  if (lower.contains('wed')) days.add(3);
  if (lower.contains('thu')) days.add(4);
  if (lower.contains('fri')) days.add(5);
  if (lower.contains('sat')) days.add(6);
  if (lower.contains('sun')) days.add(7);
  return days.toList()..sort();
}

// -----------------------------------------------------------------------------
// 3. MAIN CLASS WRAPPER
// -----------------------------------------------------------------------------

class SmartContentParser {
  // Private constructor
  SmartContentParser._();

  /// Parse BATCH text (Async) for Camera/Notes
  static Future<List<SmartParseResult>> parseBatchAsync(String text) async {
    return compute(_parseBatchIsolated, text);
  }

  /// SYNCHRONOUS SINGLE ITEM PARSER (For UI Typing)
  static SmartParseResult parse(String text) {
    return _parseSingleLine(text);
  }

  /// ASYNC SINGLE ITEM PARSER (Backward Compatibility)
  static Future<SmartParseResult> parseAsync(String text) async {
    return compute(_parseSingleLine, text);
  }

  /// BRIDGE: CONVERT RESULT TO INTERACTIVE CHIPS
  /// [colors] is optional and kept for backward compatibility with UI calls
  static List<ChipCandidate> generateChips(
      SmartParseResult result, AppColors? colors) {
    List<ChipCandidate> chips = [];
    int idCounter = 0;
    String getId() => "${result.cleanTitle}_${idCounter++}";

    // 0. SPLIT INTENT (FUSION SPECIAL) - Highest Priority
    if (result.isSplitPotential) {
      chips.add(ChipCandidate(
        id: getId(),
        type: ChipType.split,
        label: "Task + Habit?",
        icon: Icons.call_split,
        value: true,
        state: ChipVisualState.suggested,
        confidence: 0.95,
      ));
    }

    // 1. PRIORITY
    if (result.importance != null || result.suggestedImportance != null) {
      final imp = result.importance ?? result.suggestedImportance!;
      chips.add(ChipCandidate(
        id: getId(),
        type: ChipType.priority,
        label: imp.name.toUpperCase(),
        icon: Icons.flag,
        value: imp,
        state: result.importance != null
            ? ChipVisualState.confirmed
            : ChipVisualState.suggested,
      ));
    }

    // 2. TIME
    if (result.startTime != null || result.reminderTime != null) {
      final time = result.reminderTime ??
          TimeOfDay(
              hour: result.startTime!.hour, minute: result.startTime!.minute);
      chips.add(ChipCandidate(
        id: getId(),
        type: ChipType.time,
        label: "${time.hour}:${time.minute.toString().padLeft(2, '0')}",
        icon: Icons.access_time,
        value: result.startTime,
        state: ChipVisualState.confirmed,
      ));
    }

    // 3. LOCATION
    if (result.location != null) {
      chips.add(ChipCandidate(
        id: getId(),
        type: ChipType.location,
        label: result.location!,
        icon: Icons.location_on,
        value: result.location,
        state: ChipVisualState.confirmed,
      ));
    }

    // 4. FOLDER
    if (result.potentialFolder != null) {
      chips.add(ChipCandidate(
        id: getId(),
        type: ChipType.folder,
        label: result.potentialFolder!,
        icon: Icons.folder_open,
        value: result.potentialFolder,
        state: ChipVisualState.suggested,
      ));
    }

    // 5. HABIT
    if (result.habitConfig != null || result.suggestHabit) {
      chips.add(ChipCandidate(
        id: getId(),
        type: ChipType.habit,
        label: result.recurrenceRule ?? "Habit",
        icon: Icons.cached,
        value: result.habitConfig,
        state: result.habitConfig != null
            ? ChipVisualState.confirmed
            : ChipVisualState.suggested,
      ));
    }

    // 6. FOCUS
    if (result.isFocusIntent || result.suggestFocus) {
      chips.add(ChipCandidate(
        id: getId(),
        type: ChipType.focus,
        label: result.durationMinutes != null
            ? "${result.durationMinutes}m Focus"
            : "Focus",
        icon: Icons.filter_center_focus,
        value: result.durationMinutes,
        state: result.isFocusIntent
            ? ChipVisualState.confirmed
            : ChipVisualState.suggested,
      ));
    }

    return chips;
  }
}
