import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import 'package:task_manager_app/features/tasks/models/task_model.dart';
import 'package:task_manager_app/data/repositories/task_repository.dart';
// FIX: Imports pointing to the correct Smart Add services
import 'package:task_manager_app/features/smart_add/services/smart_content_parser.dart';
import 'package:task_manager_app/features/smart_add/services/keyword_service.dart';

class SmartTaskInputSheet extends StatefulWidget {
  const SmartTaskInputSheet({super.key});

  @override
  State<SmartTaskInputSheet> createState() => _SmartTaskInputSheetState();
}

class _SmartTaskInputSheetState extends State<SmartTaskInputSheet> {
  final TextEditingController _controller = TextEditingController();
  final TaskRepository _repository = TaskRepository();

  // Stores the live parsing result
  SmartParseResult? _parsedResult;

  // Stores the AI Prediction
  PredictionResult? _prediction;
  String? _suggestedFolderName;

  // FIX: Make this async to wait for the parser
  Future<void> _onTextChanged(String text) async {
    // 1. Standard Explicit Parsing (!high, #work)
    // We await the result because parse() is async (returns Future<SmartParseResult>)
    final result = await SmartContentParser.parse(text);

    // 2. AI Context Parsing (Only if no explicit tag exists)
    // We check result.potentialFolder (which is now available since we awaited)
    if (result.potentialFolder == null && text.length > 3) {
      final prediction = KeywordService.instance.predictFolder(text);

      // Threshold: Only suggest if confidence is > 40%
      if (prediction.confidence > 0.4 && prediction.folderId != null) {
        // Resolve Name for UI
        final allFolders = _repository.getFolders();
        final folder = allFolders.firstWhere((f) => f.id == prediction.folderId,
            orElse: () => allFolders.first);

        if (mounted) {
          setState(() {
            _prediction = prediction;
            _suggestedFolderName = folder.name;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _prediction = null;
            _suggestedFolderName = null;
          });
        }
      }
    } else {
      // Clear AI if user manually typed a #tag
      if (mounted) {
        setState(() {
          _prediction = null;
          _suggestedFolderName = null;
        });
      }
    }

    if (!mounted) return;

    setState(() {
      _parsedResult = result;
    });
  }

  Future<void> _handleSubmit() async {
    if (_parsedResult == null || _parsedResult!.cleanTitle.isEmpty) return;

    // 1. Resolve Folder
    String folderId = "default";
    String sectionName = "To Do";
    final allFolders = _repository.getFolders();

    if (_parsedResult!.potentialFolder != null) {
      // CASE A: User typed #Tag explicitly
      final match = allFolders.firstWhere(
        (f) =>
            f.name.toLowerCase() ==
            _parsedResult!.potentialFolder!.toLowerCase(),
        orElse: () => allFolders.first,
      );
      folderId = match.id;
    } else if (_prediction != null && _prediction!.folderId != null) {
      // CASE B: AI Suggested a folder (and user didn't override it)
      folderId = _prediction!.folderId!;
    } else if (allFolders.isNotEmpty) {
      // CASE C: Default
      folderId = allFolders.first.id;
    }

    // 2. Create the Task Model
    final newTask = TaskModel.create(
      title: _parsedResult!.cleanTitle,
      folderId: folderId,
      sectionName: sectionName,
      type: TaskType.normal,
    ).copyWith(
      startTime: _parsedResult!.startTime,
      importance: _parsedResult!.importance ?? TaskImportance.medium,
      isDone: false,
    );

    // 3. Save to Database
    await _repository.addTask(newTask);

    // 4. Close Sheet
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    String? dateString;
    if (_parsedResult?.startTime != null) {
      final d = _parsedResult!.startTime!;
      dateString =
          "${d.day}/${d.month} ${d.hour}:${d.minute.toString().padLeft(2, '0')}";
    }

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: BoxDecoration(
        color: colors.bgMiddle,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quick Add",
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            autofocus: true,
            style: TextStyle(color: colors.textMain, fontSize: 18),
            decoration: InputDecoration(
              hintText: "e.g. Call Mom !high tomorrow",
              hintStyle:
                  TextStyle(color: colors.textSecondary.withOpacity(0.5)),
              border: InputBorder.none,
            ),
            onChanged: _onTextChanged,
            onSubmitted: (_) => _handleSubmit(),
          ),
          if (_parsedResult != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // 1. EXPLICIT FOLDER CHIP
                if (_parsedResult!.potentialFolder != null)
                  _buildChip(
                      icon: Icons.folder_open,
                      label: _parsedResult!.potentialFolder!,
                      color: colors.highlight,
                      colors: colors),

                // 2. MAGIC PREDICTION CHIP (The AI Feature)
                if (_parsedResult!.potentialFolder == null &&
                    _suggestedFolderName != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colors.highlight.withOpacity(0.2),
                          colors.highlight.withOpacity(0.05)
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: colors.highlight.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome,
                            size: 14, color: colors.highlight),
                        const SizedBox(width: 5),
                        Text(
                          "$_suggestedFolderName?", // Question mark indicates it's a guess
                          style: TextStyle(
                              color: colors.highlight,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                        if (_prediction!.isAmbiguous) ...[
                          const SizedBox(width: 5),
                          // If ambiguous, show a small warning icon
                          Icon(Icons.help_outline,
                              size: 12, color: colors.textSecondary),
                        ]
                      ],
                    ),
                  ),

                // 3. PRIORITY CHIP
                if (_parsedResult!.importance != null)
                  _buildChip(
                      icon: Icons.priority_high,
                      label: _parsedResult!.importance!.name.toUpperCase(),
                      color:
                          _getPriorityColor(_parsedResult!.importance!, colors),
                      colors: colors),

                // 4. DATE CHIP
                if (dateString != null)
                  _buildChip(
                      icon: Icons.calendar_today,
                      label: dateString,
                      color: Colors.blueAccent,
                      colors: colors),
              ],
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: _handleSubmit,
                  icon: Icon(Icons.send_rounded, color: colors.highlight),
                  style: IconButton.styleFrom(
                    backgroundColor: colors.bgMain,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
    required AppColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(TaskImportance imp, AppColors colors) {
    switch (imp) {
      case TaskImportance.high:
        return colors.priorityHigh;
      case TaskImportance.medium:
        return Colors.orange;
      case TaskImportance.low:
        return Colors.green;
      case TaskImportance.none:
        return colors.textSecondary;
    }
  }
}
