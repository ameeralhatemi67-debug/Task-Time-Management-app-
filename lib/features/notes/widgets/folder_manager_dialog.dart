import 'package:flutter/material.dart';
import '../models/note_folder_model.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';

class FolderManagerDialog extends StatefulWidget {
  final AppColors colors;
  final NoteFolder rootFolder;
  final Function(NoteFolder) onFolderOpened;

  const FolderManagerDialog({
    super.key,
    required this.colors,
    required this.rootFolder,
    required this.onFolderOpened,
  });

  @override
  State<FolderManagerDialog> createState() => _FolderManagerDialogState();
}

class _FolderManagerDialogState extends State<FolderManagerDialog> {
  late NoteFolder _selectedFolder;
  final Set<String> _expandedIds = {'root'};

  @override
  void initState() {
    super.initState();
    _selectedFolder = widget.rootFolder;
  }

  void _toggleExpansion(NoteFolder folder) {
    setState(() {
      if (_expandedIds.contains(folder.id)) {
        _expandedIds.remove(folder.id);
      } else {
        _expandedIds.add(folder.id);
      }
    });
  }

  void _deleteSubFolder(NoteFolder parent, NoteFolder child) {
    setState(() {
      parent.subFolders.remove(child);
      if (_selectedFolder == child) {
        _selectedFolder = widget.rootFolder; // Reset selection if deleted
      }
    });
  }

  void _showNameInputDialog() {
    String newName = "";
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.colors.bgMiddle,
        title: Text(
          "New Folder under '${_selectedFolder.name}'",
          style: TextStyle(color: widget.colors.textMain, fontSize: 16),
        ),
        content: TextField(
          autofocus: true,
          style: TextStyle(color: widget.colors.textMain),
          decoration: InputDecoration(
            hintText: "Folder Name",
            hintStyle: TextStyle(color: widget.colors.textSecondary),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: widget.colors.highlight),
            ),
          ),
          onChanged: (val) => newName = val,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: TextStyle(color: widget.colors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              if (newName.isNotEmpty) {
                setState(() {
                  // FIX: Create a proper NoteFolder object instead of passing a String
                  final newFolder = NoteFolder(
                    id: DateTime.now()
                        .millisecondsSinceEpoch
                        .toString(), // Simple ID
                    name: newName,
                    dateCreated: DateTime.now(),
                  );

                  _selectedFolder.addSubFolder(newFolder);
                  _expandedIds.add(_selectedFolder.id);
                });
                Navigator.pop(ctx);
              }
            },
            child: Text(
              "Create",
              style: TextStyle(
                color: widget.colors.highlight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: widget.colors.bgMiddle,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        height: 500,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.folder_special, color: widget.colors.textMain),
                const SizedBox(width: 10),
                Text(
                  "Manage Folders",
                  style: TextStyle(
                    color: widget.colors.textMain,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  color: widget.colors.textSecondary,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: _buildRecursiveTile(widget.rootFolder, null, 0),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.colors.highlight,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: Icon(
                  Icons.create_new_folder,
                  color: widget.colors.textHighlighted,
                ),
                label: Text(
                  "New Subfolder",
                  style: TextStyle(
                    color: widget.colors.textHighlighted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: _showNameInputDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecursiveTile(NoteFolder folder, NoteFolder? parent, int depth) {
    final bool isSelected = _selectedFolder.id == folder.id;
    final bool isExpanded = _expandedIds.contains(folder.id);
    final bool hasChildren = folder.subFolders.isNotEmpty;
    final bool isRoot = parent == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _selectedFolder = folder),
          onDoubleTap: () {
            widget.onFolderOpened(folder);
            Navigator.pop(context);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? widget.colors.highlight.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(color: widget.colors.highlight)
                  : null,
            ),
            child: Row(
              children: [
                SizedBox(width: depth * 20.0),

                if (hasChildren)
                  GestureDetector(
                    onTap: () => _toggleExpansion(folder),
                    child: Icon(
                      isExpanded ? Icons.arrow_drop_down : Icons.arrow_right,
                      color: widget.colors.textSecondary,
                    ),
                  )
                else
                  const SizedBox(width: 24),

                Icon(
                  isSelected ? Icons.folder_open : Icons.folder,
                  color: isSelected
                      ? widget.colors.highlight
                      : widget.colors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    folder.name,
                    style: TextStyle(
                      color: isSelected
                          ? widget.colors.textMain
                          : widget.colors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),

                // Delete Button (Only if not root)
                if (!isRoot)
                  IconButton(
                    // FIXED: Changed widget.colors.error to Colors.red
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.red.withOpacity(0.7),
                    ),
                    onPressed: () => _deleteSubFolder(parent, folder),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        ),
        if (isExpanded && hasChildren)
          ...folder.subFolders.map(
            (sub) => _buildRecursiveTile(sub, folder, depth + 1),
          ),
      ],
    );
  }
}
