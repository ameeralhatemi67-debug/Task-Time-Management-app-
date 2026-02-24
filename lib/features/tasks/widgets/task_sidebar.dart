import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import 'package:task_manager_app/core/services/storage_service.dart';

// UI COMPONENT
import 'package:task_manager_app/core/widgets/sidebar_ui.dart';

// DATA & MODELS
import 'package:task_manager_app/data/repositories/task_repository.dart';
import 'package:task_manager_app/features/tasks/models/task_folder_model.dart';

class TaskSidebar extends StatefulWidget {
  final AppColors colors;
  final String currentFolderId;
  final VoidCallback onUpdate;
  final Function(bool isOpen)? onDrawerChanged;
  // Callback: Passes 'all_folders', 'archived', or a Folder UUID
  final Function(String folderId, TaskFolder? folder)? onFolderSelected;

  const TaskSidebar({
    super.key,
    required this.colors,
    required this.currentFolderId,
    required this.onUpdate,
    this.onDrawerChanged,
    this.onFolderSelected,
  });

  @override
  State<TaskSidebar> createState() => _TaskSidebarState();
}

class _TaskSidebarState extends State<TaskSidebar> {
  final TaskRepository _repo = TaskRepository();

  late String _defaultFolderId;
  List<TaskFolder> _folders = [];
  Map<String, int> _folderCounts = {};

  @override
  void initState() {
    super.initState();
    _loadPin();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant TaskSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onUpdate != widget.onUpdate) {
      _loadData();
    }
  }

  // --- DATA LOADING ---

  void _loadPin() {
    final prefs = StorageService.instance.prefsBox;
    setState(() {
      _defaultFolderId =
          prefs.get('pinned_task_folder_id', defaultValue: 'all_folders');
    });
  }

  void _loadData() {
    final folders = _repo.getFolders();
    final allTasks = _repo.getAll();

    final Map<String, int> counts = {};

    // 1. Count per folder (Active Only)
    for (var f in folders) {
      counts[f.id] = allTasks
          .where((t) => t.folderId == f.id && !t.isDone && !t.isArchived)
          .length;
    }

    // 2. Count All Active (Global)
    counts['all_folders'] =
        allTasks.where((t) => !t.isDone && !t.isArchived).length;

    // 3. Count Archived (Global)
    counts['archived'] = allTasks.where((t) => t.isArchived).length;

    if (mounted) {
      setState(() {
        _folders = folders;
        _folderCounts = counts;
      });
    }
  }

  // --- LOGIC ACTIONS ---

  void _handleSelect(SidebarItem item) {
    if (widget.onFolderSelected != null) {
      if (item.isCore) {
        // Pass null folder for core items
        widget.onFolderSelected!(item.id, null);
      } else {
        // Find the original TaskFolder object
        try {
          final folder = _folders.firstWhere((f) => f.id == item.id);
          widget.onFolderSelected!(item.id, folder);
        } catch (e) {
          print("TaskSidebar: Error finding folder: $e");
        }
      }
    }
  }

  void _handlePin(SidebarItem item) {
    StorageService.instance.prefsBox.put('pinned_task_folder_id', item.id);
    setState(() => _defaultFolderId = item.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Set as startup folder",
            style: TextStyle(color: widget.colors.textMain)),
        duration: const Duration(seconds: 1),
        backgroundColor: widget.colors.bgMiddle,
      ),
    );
  }

  Future<void> _handleAddNew(String name, bool isSubFolder) async {
    if (isSubFolder) {
      // Add as SECTION to current folder
      try {
        final currentFolder =
            _folders.firstWhere((f) => f.id == widget.currentFolderId);
        await _repo.addSection(currentFolder, name);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Section '$name' added to '${currentFolder.name}'",
                style: TextStyle(color: widget.colors.textMain)),
            backgroundColor: widget.colors.bgMiddle,
          ),
        );
      } catch (e) {
        // Current selection is likely 'all_folders' or 'archived'
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Select a specific folder to add sections.",
                style: TextStyle(color: widget.colors.textMain)),
            backgroundColor: widget.colors.priorityHigh,
          ),
        );
      }
    } else {
      // Create new FOLDER
      final newFolder = TaskFolder.create(name);
      await _repo.saveFolder(newFolder);
    }

    _loadData();
    widget.onUpdate();
  }

  Future<void> _handleRename(SidebarItem item, String newName) async {
    try {
      final folder = _folders.firstWhere((f) => f.id == item.id);
      folder.name = newName;
      await _repo.saveFolder(folder);
      _loadData();
      widget.onUpdate();
    } catch (e) {
      print("TaskSidebar: Error renaming folder: $e");
    }
  }

  Future<void> _handleDelete(SidebarItem item) async {
    if (_defaultFolderId == item.id) {
      _handlePin(const SidebarItem(
          id: 'all_folders', name: '', icon: Icons.folder)); // Reset to default
    }

    await _repo.deleteFolder(item.id);

    // If we deleted the current folder, notify parent to switch to All
    if (widget.currentFolderId == item.id) {
      widget.onFolderSelected!('all_folders', null);
    }

    _loadData();
    widget.onUpdate();
  }

  // --- BUILD ---

  @override
  Widget build(BuildContext context) {
    // 1. Group Data
    final List<SidebarItem> coreItems = [
      const SidebarItem(
        id: 'all_folders',
        name: 'All Tasks',
        icon: Icons.folder_copy_outlined,
        isCore: true,
      ),
      const SidebarItem(
        id: 'archived',
        name: 'Archived',
        icon: Icons.archive_outlined,
        isCore: true,
      ),
    ];

    final List<SidebarItem> userItems = _folders
        .map((f) => SidebarItem(
              id: f.id,
              name: f.name,
              icon: Icons.folder_outlined,
              isCore: false,
            ))
        .toList();

    // 2. Return the Adaptive UI
    return SidebarUI(
      colors: widget.colors,
      currentFolderId: widget.currentFolderId,
      pinnedFolderId: _defaultFolderId,
      folderCounts: _folderCounts,

      // CONFIGURATION: ORIGINAL TASK LAYOUT (2-Section)
      headerFlex: 2, // 10%
      bottomFlex: 2, // 10%
      sections: [
        SidebarSection(title: "LIBRARY", items: coreItems, flex: 4), // 20%
        SidebarSection(title: "FOLDERS", items: userItems, flex: 11), // 55%
      ],

      onSelect: _handleSelect,
      onPin: _handlePin,
      onDelete: _handleDelete,
      onRename: _handleRename,
      onAdd: _handleAddNew,
    );
  }
}
