import 'dart:async';
import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import 'package:task_manager_app/features/smart_add/services/smart_content_parser.dart';
import 'package:task_manager_app/features/smart_add/widgets/smart_add_chips.dart';

// REPOSITORIES & MODELS
import 'package:task_manager_app/data/repositories/task_repository.dart';
import 'package:task_manager_app/features/tasks/models/task_model.dart';
import 'package:task_manager_app/data/repositories/habit_repository.dart';
import 'package:task_manager_app/features/habits/models/habit_model.dart';
import 'package:task_manager_app/data/repositories/focus_repository.dart';
import 'package:task_manager_app/features/focus/models/focus_task_model.dart';

class StructuredReviewCard extends StatefulWidget {
  final String text;
  const StructuredReviewCard({super.key, required this.text});

  @override
  State<StructuredReviewCard> createState() => StructuredReviewCardState();
}

class StructuredReviewCardState extends State<StructuredReviewCard> {
  bool _isLoading = true;
  // We keep the raw items to maintain order and base text
  List<SmartParseResult> _rawItems = [];

  // Mapped Data: Index -> List of Active Chips
  Map<int, List<ChipCandidate>> _itemChips = {};

  final TaskRepository _taskRepo = TaskRepository();
  final HabitRepository _habitRepo = HabitRepository();
  final FocusRepository _focusRepo = FocusRepository();

  @override
  void initState() {
    super.initState();
    _processText();
  }

  Future<void> _processText() async {
    final results = await SmartContentParser.parseBatchAsync(widget.text);

    if (!mounted) return;

    setState(() {
      _rawItems = results;
      _isLoading = false;

      // Initialize chips for each item
      for (int i = 0; i < results.length; i++) {
        _itemChips[i] = SmartContentParser.generateChips(results[i], null);
      }
    });
  }

  // --- ACTIONS ---

  void _deleteChip(int itemIndex, ChipCandidate chip) {
    setState(() {
      _itemChips[itemIndex]?.remove(chip);
    });
  }

  void _toggleChip(int itemIndex, ChipCandidate chip) {
    setState(() {
      // Toggle state: Suggested -> Confirmed -> Suggested
      if (chip.state == ChipVisualState.suggested) {
        chip.state = ChipVisualState.confirmed;
      } else {
        chip.state = ChipVisualState.suggested;
      }
    });
  }

  // FIX: Renamed from handleSaveAll to match what smart_review_overlay.dart expects
  Future<void> saveAllToRepo() async {
    for (int i = 0; i < _rawItems.length; i++) {
      final raw = _rawItems[i];
      final chips = _itemChips[i] ?? [];

      // Extract Final Data from confirmed chips
      TaskImportance importance = TaskImportance.none;
      DateTime? startTime = raw.startTime;
      String folderId = "default";
      bool isHabit = false;
      bool isFocus = false;

      for (var chip in chips) {
        if (chip.state != ChipVisualState.confirmed &&
            chip.state != ChipVisualState.suggested) continue;

        if (chip.type == ChipType.priority)
          importance = chip.value as TaskImportance;
        if (chip.type == ChipType.time) startTime = chip.value as DateTime?;
        if (chip.type == ChipType.folder) folderId = chip.value as String;
        if (chip.type == ChipType.habit) isHabit = true;
        if (chip.type == ChipType.focus) isFocus = true;
      }

      // SAVE LOGIC
      if (isHabit) {
        // Create Habit
        final habit = HabitModel.create(
          title: raw.cleanTitle,
          startDate: startTime ?? DateTime.now(),
          type: HabitType.weekly, // Default
        );
        await _habitRepo.saveHabit(habit);
      } else if (isFocus) {
        // Create Focus
        final focus = FocusTaskModel.create(
            title: raw.cleanTitle, targetDuration: 25 * 60);
        await _focusRepo.addFocusTask(focus);
      } else {
        // Create Task
        // Resolve Default Folder safely
        String finalFolderId = folderId;
        if (folderId == "default") {
          final folders = await _taskRepo.getFolders();
          if (folders.isNotEmpty) finalFolderId = folders.first.id;
        }

        final task = TaskModel.create(
                title: raw.cleanTitle,
                folderId: finalFolderId,
                // FIX: Added required parameter sectionName
                sectionName: "To Do",
                type: TaskType.normal)
            .copyWith(importance: importance, startTime: startTime);
        await _taskRepo.addTask(task);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_rawItems.isEmpty) {
      return Center(
          child: Text("No tasks found",
              style: TextStyle(color: colors.textSecondary)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _rawItems.length,
      itemBuilder: (context, index) {
        final item = _rawItems[index];
        final chips = _itemChips[index] ?? [];

        return Card(
          color: colors.bgMiddle,
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Input (Editable)
                Text(
                  item.cleanTitle,
                  style: TextStyle(
                      color: colors.textMain,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                // Chips Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: chips.map((chip) {
                      // Color Mapping for specific chip types
                      Color chipColor = colors.textSecondary;

                      if (chip.type == ChipType.priority) {
                        if (chip.label.contains("HIGH"))
                          chipColor = colors.priorityHigh;
                        else if (chip.label.contains("MED"))
                          chipColor = colors.priorityMedium;
                        else
                          chipColor = colors.priorityLow;
                      } else if (chip.type == ChipType.focus)
                        chipColor = colors.focusLink;
                      else if (chip.type == ChipType.habit)
                        chipColor = colors.completedWork;
                      else if (chip.type == ChipType.folder)
                        chipColor = colors.highlight;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: UniversalSmartChip(
                          label: chip.label,
                          icon: chip.icon,
                          color: chipColor,
                          state: chip.state,
                          onTap: () => _toggleChip(index, chip),
                          onDelete: () => _deleteChip(index, chip),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
