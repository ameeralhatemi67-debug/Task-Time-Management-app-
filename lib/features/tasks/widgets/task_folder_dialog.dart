import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import '../models/task_folder_model.dart';
import '../../../data/repositories/task_repository.dart';

class TaskFolderDialog extends StatefulWidget {
  final AppColors colors;
  final List<TaskFolder> folders;
  final Function(TaskFolder) onFolderSelected;
  final VoidCallback onUpdate;

  const TaskFolderDialog({
    super.key,
    required this.colors,
    required this.folders,
    required this.onFolderSelected,
    required this.onUpdate,
  });

  @override
  State<TaskFolderDialog> createState() => _TaskFolderDialogState();
}

class _TaskFolderDialogState extends State<TaskFolderDialog> {
  final TaskRepository _repo = TaskRepository();
  bool _isDeleteMode = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: widget.colors.bgMiddle,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Folders",
                  style: TextStyle(
                    color: widget.colors.textMain,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: widget.colors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ...widget.folders.map((folder) => _buildFolderTile(folder)),
                  _buildActionTile(
                    icon: Icons.add,
                    label: "New",
                    onTap: () {
                      Navigator.pop(context);
                      _showAddFolderDialog();
                    },
                  ),
                  _buildActionTile(
                    icon: Icons.remove,
                    label: "Delete",
                    isActive: _isDeleteMode,
                    isDestructive: true,
                    onTap: () => setState(() => _isDeleteMode = !_isDeleteMode),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderTile(TaskFolder folder) {
    bool isTargeted = _isDeleteMode;
    return GestureDetector(
      onTap: () => _handleFolderTap(folder),
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isTargeted ? Colors.red.withOpacity(0.1) : widget.colors.bgTop,
          borderRadius: BorderRadius.circular(16),
          border: isTargeted ? Border.all(color: Colors.red, width: 2) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder,
              size: 32,
              color: isTargeted ? Colors.red : widget.colors.textMain,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                folder.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isTargeted ? Colors.red : widget.colors.textMain,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    bool isDestructive = false,
  }) {
    Color bgColor = isActive
        ? (isDestructive ? Colors.red : widget.colors.highlight)
        : widget.colors.bgBottom;
    Color iconColor = isActive
        ? widget.colors.textHighlighted
        : (isDestructive ? Colors.red : widget.colors.textMain);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.colors.textSecondary.withOpacity(0.1),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: iconColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: iconColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleFolderTap(TaskFolder folder) {
    if (_isDeleteMode) {
      _deleteFolder(folder);
    } else {
      widget.onFolderSelected(folder);
      Navigator.pop(context);
    }
  }

  Future<void> _deleteFolder(TaskFolder folder) async {
    // FIXED: Use getAllTasksInFolder to check all sections safely
    final tasks = _repo.getAllTasksInFolder(folder.id);
    bool confirm = true;

    // FIXED: Use the 'tasks' variable
    if (tasks.isNotEmpty) {
      confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: widget.colors.bgMiddle,
              title: Text(
                "Delete '${folder.name}'?",
                style: TextStyle(color: widget.colors.textMain),
              ),
              content: Text(
                "This folder contains ${tasks.length} tasks.",
                style: TextStyle(color: widget.colors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: widget.colors.textSecondary),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(
                    "Delete",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ) ??
          false;
    }

    if (confirm) {
      await _repo.deleteFolder(folder.id);
      widget.onUpdate();
      setState(() {});
    }
  }

  void _showAddFolderDialog() {
    String name = "";
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.colors.bgMiddle,
        title: Text(
          "New Folder",
          style: TextStyle(color: widget.colors.textMain),
        ),
        content: TextField(
          autofocus: true,
          style: TextStyle(color: widget.colors.textMain),
          onChanged: (v) => name = v,
          decoration: InputDecoration(
            hintText: "Name",
            hintStyle: TextStyle(color: widget.colors.textSecondary),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: widget.colors.highlight),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (name.isNotEmpty) {
                _repo.saveFolder(TaskFolder.create(name));
                widget.onUpdate();
              }
              Navigator.pop(ctx);
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
}
