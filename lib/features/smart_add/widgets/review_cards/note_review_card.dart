import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:uuid/uuid.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import 'package:task_manager_app/features/notes/widgets/note_editor/editor_toolbar.dart';
import 'package:task_manager_app/features/notes/models/note_folder_model.dart';
import 'package:task_manager_app/data/repositories/note_repository.dart';
import 'package:task_manager_app/features/notes/models/note_model.dart';

class NoteReviewCard extends StatefulWidget {
  final String text;
  const NoteReviewCard({super.key, required this.text});

  @override
  State<NoteReviewCard> createState() => NoteReviewCardState();
}

class NoteReviewCardState extends State<NoteReviewCard> {
  late QuillController _controller;
  final TextEditingController _titleController = TextEditingController();

  NoteFolder? _selectedFolder;
  final NoteRepository _repo = NoteRepository();

  @override
  void initState() {
    super.initState();
    // 1. Initialize Content
    _controller = QuillController(
      document: Document()..insert(0, widget.text),
      selection: const TextSelection.collapsed(offset: 0),
    );

    // 2. Initialize Folder (Default to Root) to prevent null errors
    _selectedFolder = _repo.loadRootFolder();
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    super.dispose();
  }

  // --- PUBLIC SAVE METHOD (Called by Overlay) ---
  // RESTORED NAME: saveNoteToRepo
  Future<void> saveNoteToRepo() async {
    String content = _controller.document.toPlainText().trim();
    String jsonContent = jsonEncode(_controller.document.toDelta().toJson());
    String title = _titleController.text.trim();

    if (title.isEmpty) {
      // Auto-generate title from first line
      title = content.split('\n').first;
      if (title.length > 20) title = "${title.substring(0, 20)}...";
    }

    final newNote = NoteModel(
      id: const Uuid().v4(),
      title: title.isEmpty ? "New Note" : title,
      content: content,
      jsonContent: jsonContent,
      dateModified: DateTime.now(),
      dateCreated: DateTime.now(),
    );

    // FIX: Use named parameter 'folderId'
    await _repo.saveNote(
      newNote,
      folderId: _selectedFolder?.id ?? 'root',
    );
  }

  // --- FOLDER SELECTION DIALOG ---
  void _pickFolder(AppColors colors) {
    showDialog(
      context: context,
      builder: (context) {
        final root = _repo.loadRootFolder();
        return AlertDialog(
          backgroundColor: colors.bgMiddle,
          title:
              Text("Select Folder", style: TextStyle(color: colors.textMain)),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView(
              children: [
                _buildFolderTile(root, colors, 0),
                ..._buildSubFolders(root, colors, 1),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildSubFolders(
      NoteFolder parent, AppColors colors, int depth) {
    List<Widget> tiles = [];
    for (var sub in parent.subFolders) {
      tiles.add(_buildFolderTile(sub, colors, depth));
      tiles.addAll(_buildSubFolders(sub, colors, depth + 1));
    }
    return tiles;
  }

  Widget _buildFolderTile(NoteFolder folder, AppColors colors, int depth) {
    final isSelected = _selectedFolder?.id == folder.id;
    return ListTile(
      contentPadding: EdgeInsets.only(left: 16.0 + (depth * 10), right: 16),
      leading: Icon(isSelected ? Icons.folder : Icons.folder_open,
          color: isSelected ? colors.highlight : colors.textSecondary,
          size: 20),
      title: Text(folder.name,
          style: TextStyle(
              color: isSelected ? colors.highlight : colors.textMain,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      onTap: () {
        setState(() => _selectedFolder = folder);
        Navigator.pop(context);
      },
    );
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: colors.bgMiddle,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: colors.bgBottom, width: 2),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),

          // HEADER: Title + Folder Picker
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    style: TextStyle(
                      color: colors.textMain,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: "Title",
                      hintStyle: TextStyle(
                          color: colors.textSecondary.withOpacity(0.5)),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                // FOLDER CHIP
                GestureDetector(
                  onTap: () => _pickFolder(colors),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: colors.bgBottom,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.folder_open,
                            size: 14, color: colors.textSecondary),
                        const SizedBox(width: 5),
                        Text(
                          _selectedFolder?.name ?? "Root",
                          style: TextStyle(
                              color: colors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // CONTENT EDITOR
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: QuillEditor.basic(
                controller: _controller,
                config: const QuillEditorConfig(
                  placeholder: "Scanning content...",
                  scrollable: true,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ),

          // TOOLBAR (Reusing the same toolbar from Note Editor!)
          EditorToolbar(
            colors: colors,
            controller: _controller,
            onColorPressed: () {}, // Simplified for overlay (no popups yet)
            onSizePressed: () {},
            onAlignPressed: () {},
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
