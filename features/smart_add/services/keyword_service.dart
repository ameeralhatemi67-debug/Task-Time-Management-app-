import 'package:hive/hive.dart';
import 'package:task_manager_app/core/services/storage_service.dart';

// -----------------------------------------------------------------------------
// 1. DATA MODEL (The Output)
// -----------------------------------------------------------------------------

class PredictionResult {
  final String? folderId;
  final String? folderName; // Optional, can be resolved by UI if needed
  final double confidence; // 0.0 to 1.0
  final bool isAmbiguous;
  final List<String> ambiguousOptions;

  PredictionResult({
    this.folderId,
    this.folderName,
    required this.confidence,
    this.isAmbiguous = false,
    this.ambiguousOptions = const [],
  });
}

// -----------------------------------------------------------------------------
// 2. THE SERVICE (The Brain)
// -----------------------------------------------------------------------------

class KeywordService {
  // Singleton Pattern
  static final KeywordService instance = KeywordService._();
  KeywordService._();

  // Access the persistent memory (Brain) via StorageService
  // Ensure StorageService has 'associationsBox' initialized!
  Box get _box => StorageService.instance.associationsBox;

  // "Stop Words" to ignore (Noise filter)
  // These words add no semantic value to folder prediction.
  final Set<String> _stopWords = {
    'the',
    'at',
    'on',
    'in',
    'to',
    'for',
    'a',
    'an',
    'is',
    'of',
    'and',
    'with',
    'tomorrow',
    'today',
    'yesterday',
    'next',
    'week',
    'month',
    'year',
    'daily',
    'weekly',
    'every',
    'task',
    'note',
    'reminder',
    'entry',
    'habit',
    'focus',
    'session',
    'do',
    'make',
    'create',
    'update'
  };

  // ---------------------------------------------------------------------------
  // A. THE LEARNING ENGINE (Input)
  // ---------------------------------------------------------------------------

  /// Learns from user corrections or manual saves.
  /// [text] is the Task/Habit/Focus title.
  /// [folderId] is the folder the user selected.
  Future<void> learnCorrection(String text, String folderId) async {
    // 1. Validation: Don't learn 'default' as a specific preference, it dilutes the data.
    if (folderId == 'default' || folderId.isEmpty) return;

    // 2. Tokenize: Break sentence into meaningful words
    final tokens = _tokenize(text);

    for (var token in tokens) {
      // Structure: "word" -> Map<String, int> { "folderId": score }
      // We use a dynamic map because Hive stores JSON-like maps.
      final Map<dynamic, dynamic> folderScores =
          _box.get(token, defaultValue: <dynamic, dynamic>{});

      // 3. Increment score for this specific folder
      // We cast to int safely
      int currentScore = (folderScores[folderId] ?? 0) as int;
      folderScores[folderId] =
          currentScore + 1; // +1 Point for this association

      // 4. Save back to Hive (Persistent Memory)
      await _box.put(token, folderScores);
    }
  }

  // ---------------------------------------------------------------------------
  // B. THE PREDICTION ENGINE (Output)
  // ---------------------------------------------------------------------------

  /// Predicts the folder based on the accumulated weights in Hive.
  PredictionResult predictFolder(String text) {
    final tokens = _tokenize(text);
    if (tokens.isEmpty) return PredictionResult(confidence: 0);

    // Map to hold Total Score per Folder across all tokens in the phrase
    final Map<String, int> folderTotals = {};

    for (var token in tokens) {
      // Retrieve learned scores for this word
      final Map<dynamic, dynamic>? scores = _box.get(token);

      if (scores != null) {
        scores.forEach((key, value) {
          final fId = key as String;
          final score = value as int;
          // Sum up the scores
          folderTotals[fId] = (folderTotals[fId] ?? 0) + score;
        });
      }
    }

    // If no associations found
    if (folderTotals.isEmpty) {
      return PredictionResult(confidence: 0);
    }

    // Sort to find the winner (Descending order of score)
    var sortedEntries = folderTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final bestEntry = sortedEntries.first;
    final bestId = bestEntry.key;
    final bestScore = bestEntry.value;

    // Calculate Confidence
    // Logic: How dominant is this folder compared to the total noise?
    int totalSystemScore = folderTotals.values.fold(0, (sum, v) => sum + v);

    double confidence =
        totalSystemScore == 0 ? 0.0 : (bestScore / totalSystemScore);

    // Boost confidence if we have strong repeated evidence (raw score)
    // This helps differentiate "1 lucky guess" vs "20 confirmed saves"
    if (bestScore > 5) confidence += 0.2;
    if (bestScore > 20) confidence += 0.1;

    // Check Ambiguity (if the runner-up is close)
    bool isAmbiguous = false;
    List<String> ambiguousIds = [];

    if (sortedEntries.length > 1) {
      final secondEntry = sortedEntries[1];
      // If the winner is less than 20% better than second place, it's ambiguous
      // e.g. Winner=10, RunnerUp=9. 10 < (9*1.2=10.8) -> True (Ambiguous)
      if (bestScore < (secondEntry.value * 1.2)) {
        isAmbiguous = true;
        ambiguousIds = [bestId, secondEntry.key];
      }
    }

    // Cap confidence at 1.0 (100%)
    if (confidence > 1.0) confidence = 1.0;

    return PredictionResult(
      folderId: bestId,
      folderName: null,
      confidence: confidence,
      isAmbiguous: isAmbiguous,
      ambiguousOptions: ambiguousIds,
    );
  }

  // ---------------------------------------------------------------------------
  // C. UTILITIES
  // ---------------------------------------------------------------------------

  List<String> _tokenize(String text) {
    // lowercase -> remove special chars -> split by space
    final clean = text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    final rawTokens = clean.split(' ');

    return rawTokens
        .where((t) =>
                t.isNotEmpty &&
                t.length > 2 && // Skip short words like 'go'
                !_stopWords.contains(t) // Skip stop words
            )
        .toList();
  }
}
