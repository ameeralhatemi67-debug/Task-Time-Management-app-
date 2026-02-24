import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import 'package:task_manager_app/core/services/storage_service.dart';

// UI COMPONENT
import 'package:task_manager_app/core/widgets/sidebar_ui.dart';

// DATA & MODELS
import 'package:task_manager_app/data/repositories/task_repository.dart';
import 'package:task_manager_app/features/tasks/models/task_folder_model.dart';

class Sidebar extends StatefulWidget {
  final AppColors colors;
  final String currentFolderId;
  final VoidCallback onUpdate;
  final Function(bool isOpen)? onDrawerChanged;
  final Function(String folderId, TaskFolder? folder)? onFolderSelected;

  const Sidebar({
    super.key,
    required this.colors,
    required this.currentFolderId,
    required this.onUpdate,
    this.onDrawerChanged,
    this.onFolderSelected,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
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

    for (var f in folders) {
      counts[f.id] = allTasks
          .where((t) => t.folderId == f.id && !t.isDone && !t.isArchived)
          .length;
    }
    counts['all_folders'] =
        allTasks.where((t) => !t.isDone && !t.isArchived).length;
    counts['archived'] = allTasks.where((t) => t.isArchived).length;

    setState(() {
      _folders = folders;
      _folderCounts = counts;
    });
  }

  void _handleSelect(SidebarItem item) {
    if (widget.onFolderSelected != null) {
      if (item.isCore) {
        widget.onFolderSelected!(item.id, null);
      } else {
        try {
          final folder = _folders.firstWhere((f) => f.id == item.id);
          widget.onFolderSelected!(item.id, folder);
        } catch (e) {
          print("Error finding folder: $e");
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
    // Tasks support sections, but UI adds Folders here.
    // Sub-folder logic can be handled in logic if needed, but standard logic adds folder.
    final newFolder = TaskFolder.create(name);
    await _repo.saveFolder(newFolder);
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
      print("Error renaming folder: $e");
    }
  }

  Future<void> _handleDelete(SidebarItem item) async {
    if (_defaultFolderId == item.id) {
      _handlePin(
          const SidebarItem(id: 'all_folders', name: '', icon: Icons.folder));
    }
    await _repo.deleteFolder(item.id);
    _loadData();
    widget.onUpdate();
  }

  @override
  Widget build(BuildContext context) {
    // Define Groups
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

    return SidebarUI(
      colors: widget.colors,
      currentFolderId: widget.currentFolderId,
      pinnedFolderId: _defaultFolderId,
      folderCounts: _folderCounts,

      // CONFIGURATION: ORIGINAL 2-SECTION LAYOUT
      headerFlex: 2, // 15% (Approx 2/19)
      bottomFlex: 2, // 10% (Approx 2/19)
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
