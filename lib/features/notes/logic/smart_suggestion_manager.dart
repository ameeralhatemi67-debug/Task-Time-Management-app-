import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';

// --- SERVICES ---
import 'package:task_manager_app/features/smart_add/services/smart_content_parser.dart';
import 'package:task_manager_app/features/smart_add/services/keyword_service.dart';
import 'package:task_manager_app/data/repositories/note_repository.dart';

// --- WIDGETS ---
import 'package:task_manager_app/features/smart_add/widgets/smart_add_chips.dart';

class SmartSuggestionManager extends ChangeNotifier {
  final QuillController controller;
  Timer? _debounceTimer;

  // Repositories
  final NoteRepository _noteRepo = NoteRepository();

  // Track active chips
  List<ChipCandidate> _activeChips = [];
  List<ChipCandidate> get activeChips => _activeChips;

  // We need colors for chip generation; set by the View
  AppColors? currentColors;

  SmartSuggestionManager(this.controller) {
    controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    controller.removeListener(_onTextChanged);
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _analyzeCurrentSentence();
    });
  }

  Future<void> _analyzeCurrentSentence() async {
    final text = _getCurrentSentence();
    if (text.trim().isEmpty) {
      _clearSuggestions();
      return;
    }

    try {
      // 1. LEFT BRAIN: Regex Parser (Explicit Commands)
      // We use try-catch here just in case the Isolate fails
      final parseResult = await SmartContentParser.parseAsync(text);

      // 2. RIGHT BRAIN: AI Prediction (Safe Mode)
      PredictionResult? aiPrediction;
      try {
        if (parseResult.potentialFolder == null && text.length > 3) {
          // Only call AI if we don't have an explicit tag
          aiPrediction = KeywordService.instance.predictFolder(text);
        }
      } catch (e) {
        print("AI Prediction Failed: $e");
        // We continue without AI, so the basic chips still work
      }

      // 3. GENERATE CHIPS
      List<ChipCandidate> finalChips =
          SmartContentParser.generateChips(parseResult, currentColors);

      // 4. THE JUDGE (AI Integration)
      if (parseResult.potentialFolder == null &&
          aiPrediction != null &&
          aiPrediction.folderId != null) {
        if (aiPrediction.confidence > 0.3) {
          // Resolve Name safely
          String folderName = "Folder";
          try {
            final folders = _noteRepo.getFolders();
            final match = folders.cast().firstWhere(
                  (f) => f.id == aiPrediction!.folderId,
                  orElse: () => null,
                );
            if (match != null) folderName = match.name;
          } catch (e) {
            print("Folder Lookup Failed: $e");
          }

          final label = aiPrediction.isAmbiguous ? "$folderName?" : folderName;

          final aiChip = ChipCandidate(
            id: "ai_suggestion_${aiPrediction.folderId}",
            type: ChipType.folder,
            label: label,
            icon: Icons.auto_awesome,
            value: aiPrediction.folderId,
            state: ChipVisualState.suggested,
            confidence: aiPrediction.confidence,
          );

          finalChips.insert(0, aiChip);
        }
      }

      _updateChips(finalChips);
    } catch (e) {
      print("CRITICAL SUGGESTION ERROR: $e");
      _clearSuggestions();
    }
  }

  String _getCurrentSentence() {
    final text = controller.document.toPlainText();
    final selection = controller.selection;
    if (selection.baseOffset < 0) return "";

    try {
      int start = text.lastIndexOf('\n', selection.baseOffset - 1);
      if (start == -1) start = 0;

      int end = text.indexOf('\n', selection.baseOffset);
      if (end == -1) end = text.length;

      if (start >= end) return "";
      return text.substring(start, end).trim();
    } catch (e) {
      return "";
    }
  }

  void _updateChips(List<ChipCandidate> newChips) {
    _activeChips = newChips;
    notifyListeners();

    for (var chip in _activeChips) {
      _startDismissTimer(chip);
    }
  }

  void _startDismissTimer(ChipCandidate chip) {
    Timer(const Duration(seconds: 3), () {
      if (_activeChips.contains(chip) &&
          chip.state == ChipVisualState.suggested) {
        chip.state = ChipVisualState.dismissible;
        notifyListeners();
      }
    });
  }

  void _clearSuggestions() {
    if (_activeChips.isNotEmpty) {
      _activeChips = [];
      notifyListeners();
    }
  }

  void removeChip(ChipCandidate chip) {
    _activeChips.remove(chip);
    notifyListeners();
  }

  void confirmChip(ChipCandidate chip) {
    chip.state = ChipVisualState.confirmed;

    // Insert text logic
    final index = controller.selection.baseOffset;
    String textToInsert = "";

    switch (chip.type) {
      case ChipType.folder:
        textToInsert = " #${chip.label.replaceAll('?', '')} ";
        break;
      case ChipType.split:
        textToInsert = " [SPLIT] ";
        break;
      default:
        textToInsert = " [${chip.label}] ";
    }

    if (textToInsert.isNotEmpty) {
      controller.document.insert(index, textToInsert);
      controller.updateSelection(
          TextSelection.collapsed(offset: index + textToInsert.length),
          ChangeSource.local);
    }

    // Feedback Loop
    if (chip.type == ChipType.folder && chip.icon == Icons.auto_awesome) {
      try {
        final sentence = _getCurrentSentence();
        KeywordService.instance.learnCorrection(sentence, chip.value);
      } catch (e) {
        print("Learning failed: $e");
      }
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      removeChip(chip);
    });

    notifyListeners();
  }
}
