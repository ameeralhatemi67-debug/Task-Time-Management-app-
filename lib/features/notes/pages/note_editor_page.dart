import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import '../models/note_model.dart';
import '../widgets/note_editor/editor_toolbar.dart';
import '../widgets/note_editor/color_picker_sheet.dart';
import '../widgets/note_editor/font_size_sheet.dart';
import '../widgets/note_editor/alignment_sheet.dart';
import '../../../data/repositories/note_repository.dart';

// --- NEW SMART WRITER IMPORTS ---
import 'package:task_manager_app/features/notes/logic/smart_suggestion_manager.dart';
import 'package:task_manager_app/features/notes/widgets/note_editor/ghost_chip_stack.dart';

// Enum to track which anchored popup is open
enum ActiveEditorTool { none, color, size, align }

class NoteEditorPage extends StatefulWidget {
  final NoteModel? existingNote;
  final String? initialFolderId;

  const NoteEditorPage({
    super.key,
    this.existingNote,
    this.initialFolderId,
  });

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  // Core Controllers
  late QuillController _controller;
  late TextEditingController _titleController;
  final NoteRepository _repo = NoteRepository();
  final FocusNode _focusNode = FocusNode();

  // --- SMART BRAIN ---
  late SmartSuggestionManager _smartManager;
  bool _showChips = true; // Toggle for the feature visibility

  // State for Anchored Popups
  ActiveEditorTool _activeTool = ActiveEditorTool.none;
  Color _currentColor = Colors.black;
  double _currentSize = 16.0;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.existingNote?.title ?? "");

    // 1. Initialize Quill Controller
    if (widget.existingNote != null &&
        widget.existingNote!.jsonContent.isNotEmpty) {
      try {
        final json = jsonDecode(widget.existingNote!.jsonContent);
        _controller = QuillController(
          document: Document.fromJson(json),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (e) {
        _controller = QuillController.basic();
      }
    } else {
      _controller = QuillController.basic();
      // If plain content exists but no JSON, insert it
      if (widget.existingNote != null &&
          widget.existingNote!.content.isNotEmpty) {
        _controller.document.insert(0, widget.existingNote!.content);
      }
    }

    // 2. Initialize Smart Manager (The Brain)
    _smartManager = SmartSuggestionManager(_controller);
  }

  @override
  void dispose() {
    _smartManager.dispose(); // Dispose the brain
    _controller.dispose();
    _titleController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // --- SAVE LOGIC ---

  Future<void> _saveNote() async {
    String content = _controller.document.toPlainText().trim();
    String json = jsonEncode(_controller.document.toDelta().toJson());
    String title = _titleController.text.trim();

    // If completely empty, don't save
    if (title.isEmpty && content.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }

    if (title.isEmpty) {
      title = content.split('\n').first;
      if (title.length > 20) title = "${title.substring(0, 20)}...";
    }

    final note = NoteModel.create(
      title: title,
      content: content,
      jsonContent: json,
      folderId: widget.initialFolderId, // Using the fixed Factory
    );

    // If we are editing an existing note, preserve its ID and dates
    if (widget.existingNote != null) {
      final updatedNote = widget.existingNote!.copyWith(
        title: title,
        content: content,
        jsonContent: json,
        dateModified: DateTime.now(),
        // We do NOT overwrite folderId here unless we strictly want to move it,
        // but typically the editor stays in the same folder.
      );
      await _repo.saveNote(updatedNote);
    } else {
      // Create NEW note in the specific folder
      await _repo.saveNote(note, folderId: widget.initialFolderId);
    }

    if (mounted) Navigator.pop(context);
  }

  // --- ACTIONS ---

  Future<void> _handleScanNote() async {
    // Phase 4 Implementation Placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("Scanning entire note... (Coming in Step 4.2)")),
    );
  }

  void _toggleTool(ActiveEditorTool tool) {
    setState(() {
      if (_activeTool == tool) {
        _activeTool = ActiveEditorTool.none;
      } else {
        _activeTool = tool;
      }
    });
  }

  void _closeTools() {
    setState(() {
      _activeTool = ActiveEditorTool.none;
    });
  }

  // --- UI CONSTRUCTION ---

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    // Crucial: Get keyboard height to position toolbar/chips
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    const double toolbarHeight = 50.0;
    const double chipsHeight = 50.0;

    // --- LAYOUT FIX: Calculate safe bottom position for chips ---
    // If keyboard is OPEN: Position above Keyboard + Toolbar
    // If keyboard is CLOSED: Position above Safe Area + Toolbar
    final double chipsBottomPos = bottomInset > 0
        ? bottomInset + toolbarHeight
        : MediaQuery.of(context).padding.bottom + toolbarHeight;

    return Scaffold(
      backgroundColor: colors.bgMain,
      // We handle layout manually with Stack to allow floating elements
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            // -----------------------------------------------------------------
            // LAYER 1: MAIN CONTENT (Header + Editor)
            // -----------------------------------------------------------------
            Column(
              children: [
                _buildHeader(colors),
                Divider(
                    height: 1, color: colors.textSecondary.withOpacity(0.1)),
                Expanded(
                  child: QuillEditor.basic(
                    controller: _controller,
                    focusNode: _focusNode,
                    config: QuillEditorConfig(
                      placeholder: "Start typing...",
                      padding: EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 20,
                        // Dynamic bottom padding ensures text scrolls ABOVE the toolbar/chips
                        // Formula: Keyboard + Toolbar + Chips + Buffer
                        bottom: bottomInset + toolbarHeight + chipsHeight + 20,
                      ),
                      autoFocus: true,
                    ),
                  ),
                ),
              ],
            ),

            // -----------------------------------------------------------------
            // LAYER 2: GHOST CHIPS (Smart Suggestions)
            // -----------------------------------------------------------------
            if (_showChips)
              AnimatedBuilder(
                animation: _smartManager,
                builder: (context, child) {
                  // Only show if there are active chips
                  if (_smartManager.activeChips.isEmpty)
                    return const SizedBox.shrink();

                  return Positioned(
                    left: 20,
                    right: 20,
                    // FIX: Use the calculated safe position
                    bottom: chipsBottomPos,
                    child: GhostChipStack(
                      manager: _smartManager,
                      colors: colors,
                    ),
                  );
                },
              ),

            // -----------------------------------------------------------------
            // LAYER 3: TOOLBAR & POPUP SHEETS
            // -----------------------------------------------------------------
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomInset, // Float exactly on top of keyboard
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // A. ACTIVE TOOL POPUP (Floats above toolbar)
                  if (_activeTool != ActiveEditorTool.none)
                    _buildActiveToolSheet(colors),

                  // B. THE MAIN TOOLBAR
                  EditorToolbar(
                    colors: colors,
                    controller: _controller,
                    onColorPressed: () => _toggleTool(ActiveEditorTool.color),
                    onSizePressed: () => _toggleTool(ActiveEditorTool.size),
                    onAlignPressed: () => _toggleTool(ActiveEditorTool.align),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildHeader(AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      color: colors.bgMain,
      child: Row(
        children: [
          // BACK / SAVE BUTTON
          IconButton(
            icon: Icon(Icons.arrow_back, color: colors.textMain),
            onPressed: () {
              // Always save on back (unless user discarded, but simplistic for now)
              _saveNote();
            },
          ),
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
                hintStyle:
                    TextStyle(color: colors.textSecondary.withOpacity(0.5)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
          ),

          // KEBAB MENU
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: colors.textMain),
            color: colors.bgMiddle,
            onSelected: (val) {
              if (val == 'scan') _handleScanNote();
              if (val == 'toggle_chips')
                setState(() => _showChips = !_showChips);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'scan',
                child: Row(
                  children: [
                    Icon(Icons.document_scanner,
                        size: 18, color: colors.textMain),
                    const SizedBox(width: 8),
                    Text("Scan Note for Tasks",
                        style: TextStyle(color: colors.textMain)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle_chips',
                child: Row(
                  children: [
                    Icon(_showChips ? Icons.visibility : Icons.visibility_off,
                        size: 18, color: colors.textMain),
                    const SizedBox(width: 8),
                    Text(_showChips ? "Hide Suggestions" : "Show Suggestions",
                        style: TextStyle(color: colors.textMain)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveToolSheet(AppColors colors) {
    switch (_activeTool) {
      case ActiveEditorTool.size:
        return FontSizeSheet(
          colors: colors,
          currentSize: _currentSize,
          onSizeSelected: (size) {
            setState(() => _currentSize = size);
            if (size > 24) {
              _controller.formatSelection(Attribute.h1);
            } else if (size > 18) {
              _controller.formatSelection(Attribute.h2);
            } else {
              _controller.formatSelection(Attribute.header); // Reset/Normal
            }
          },
        );

      case ActiveEditorTool.align:
        return Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(bottom: 10, right: 20),
          child: AlignmentSheet(
            colors: colors,
            onAlignSelected: (align) {
              if (align == TextAlign.left)
                _controller.formatSelection(Attribute.leftAlignment);
              if (align == TextAlign.center)
                _controller.formatSelection(Attribute.centerAlignment);
              if (align == TextAlign.right)
                _controller.formatSelection(Attribute.rightAlignment);
              if (align == TextAlign.justify)
                _controller.formatSelection(Attribute.justifyAlignment);
              _closeTools();
            },
          ),
        );

      case ActiveEditorTool.color:
        return Container(
          height: 320,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: colors.bgMiddle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ColorPickerSheet(
            colors: colors,
            currentColor: _currentColor,
            onColorSelected: (color) {
              setState(() => _currentColor = color);
              // Convert Color to Hex String for Quill
              _controller.formatSelection(ColorAttribute(
                  ('#${color.value.toRadixString(16).substring(2)}')));
              _closeTools();
            },
          ),
        );

      case ActiveEditorTool.none:
        return const SizedBox.shrink();
    }
  }
}
