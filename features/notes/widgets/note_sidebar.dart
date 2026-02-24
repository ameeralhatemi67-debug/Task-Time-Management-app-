import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import 'package:task_manager_app/core/services/storage_service.dart';

// UI COMPONENT
import 'package:task_manager_app/core/widgets/sidebar_ui.dart';

// DATA & MODELS
import 'package:task_manager_app/data/repositories/note_repository.dart';
import 'package:task_manager_app/features/notes/models/note_folder_model.dart';

class NoteSidebar extends StatefulWidget {
  final AppColors colors;
  final String currentFolderId;
  final VoidCallback onUpdate;
  final Function(bool isOpen)? onDrawerChanged;
  final Function(String folderId, NoteFolder? folder)? onFolderSelected;

  const NoteSidebar({
    super.key,
    required this.colors,
    required this.currentFolderId,
    required this.onUpdate,
    this.onDrawerChanged,
    this.onFolderSelected,
  });

  @override
  State<NoteSidebar> createState() => _NoteSidebarState();
}

class _NoteSidebarState extends State<NoteSidebar> {
  final NoteRepository _repo = NoteRepository();

  late String _defaultFolderId;
  List<SidebarItem> _folderItems = [];
  Map<String, int> _folderCounts = {};
  NoteFolder? _root;

  // Virtual Core IDs
  static const String _idAll = 'all_notes';
  static const String _idArchived = 'archived_notes';

  @override
  void initState() {
    super.initState();
    _loadPin();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant NoteSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onUpdate != widget.onUpdate) {
      _loadData();
    }
  }

  void _loadPin() {
    final prefs = StorageService.instance.prefsBox;
    setState(() {
      _defaultFolderId =
          prefs.get('pinned_note_folder_id', defaultValue: _idAll);
    });
  }

  void _loadData() {
    _root = _repo.loadRootFolder();

    // 1. Create Main if missing
    if (_root!.subFolders.isEmpty) {
      _createDefaultMainFolder();
      return; // Reload triggered inside
    }

    // 2. Build Recursive Items
    final List<SidebarItem> items =
        _root!.subFolders.map((f) => _mapFolderToItem(f)).toList();

    // 3. Count
    final Map<String, int> counts = {};
    counts[_idAll] =
        _repo.getAll().where((n) => !n.isArchived).length; // Approx All
    counts[_idArchived] = _repo.getAll().where((n) => n.isArchived).length;
    _countRecursive(_root!, counts);

    if (mounted) {
      setState(() {
        _folderItems = items;
        _folderCounts = counts;
      });
    }
  }

  SidebarItem _mapFolderToItem(NoteFolder folder) {
    return SidebarItem(
      id: folder.id,
      name: folder.name,
      icon: Icons.folder_outlined,
      isCore: false,
      children: folder.subFolders.map((sub) => _mapFolderToItem(sub)).toList(),
    );
  }

  void _countRecursive(NoteFolder folder, Map<String, int> counts) {
    counts[folder.id] = folder.noteIds.length;
    for (var sub in folder.subFolders) {
      _countRecursive(sub, counts);
    }
  }

  Future<void> _createDefaultMainFolder() async {
    final mainFolder = NoteFolder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: "Main",
      dateCreated: DateTime.now(),
    );
    await StorageService.instance.folderBox.put(mainFolder.id, mainFolder);
    _root!.subFolderIds.add(mainFolder.id);
    await StorageService.instance.folderBox.put(_root!.id, _root!);
    _loadData();
  }

  // --- ACTIONS ---

  void _handleSelect(SidebarItem item) {
    if (widget.onFolderSelected != null) {
      if (item.isCore) {
        widget.onFolderSelected!(item.id, null);
      } else {
        // Find folder object from Repo Root
        final folder = _findFolderById(_root!, item.id);
        widget.onFolderSelected!(item.id, folder);
      }
    }
  }

  NoteFolder? _findFolderById(NoteFolder parent, String id) {
    if (parent.id == id) return parent;
    for (var sub in parent.subFolders) {
      final found = _findFolderById(sub, id);
      if (found != null) return found;
    }
    return null;
  }

  void _handlePin(SidebarItem item) {
    StorageService.instance.prefsBox.put('pinned_note_folder_id', item.id);
    setState(() => _defaultFolderId = item.id);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Set as startup folder",
            style: TextStyle(color: widget.colors.textMain)),
        backgroundColor: widget.colors.bgMiddle));
  }

  Future<void> _handleAddNew(String name, bool isSubFolder) async {
    // Logic: If isSubFolder, add to *Current Selected Folder*.
    // If current is Core (All/Archived), fallback to Root (Top Level).
    NoteFolder? parent = _root;

    if (isSubFolder &&
        widget.currentFolderId != _idAll &&
        widget.currentFolderId != _idArchived) {
      parent = _findFolderById(_root!, widget.currentFolderId) ?? _root;
    }

    final newFolder = NoteFolder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      dateCreated: DateTime.now(),
    );

    // Save New
    await StorageService.instance.folderBox.put(newFolder.id, newFolder);

    // Link to Parent
    parent!.subFolderIds.add(newFolder.id);
    await StorageService.instance.folderBox.put(parent.id, parent);

    _loadData();
    widget.onUpdate();
  }

  Future<void> _handleRename(SidebarItem item, String newName) async {
    final folder = _findFolderById(_root!, item.id);
    if (folder != null) {
      folder.name = newName;
      await StorageService.instance.folderBox.put(folder.id, folder);
      _loadData();
      widget.onUpdate();
    }
  }

  Future<void> _handleDelete(SidebarItem item) async {
    if (_defaultFolderId == item.id) {
      _handlePin(const SidebarItem(id: _idAll, name: '', icon: Icons.folder));
    }

    // 1. Find Parent to unlink
    _removeIdFromTree(_root!, item.id);
    await StorageService.instance.folderBox.put(_root!.id, _root!);

    // 2. Delete Object
    await StorageService.instance.folderBox.delete(item.id);

    // 3. Fallback selection if current was deleted
    if (widget.currentFolderId == item.id) {
      widget.onFolderSelected!(_idAll, null);
    }

    _loadData();
    widget.onUpdate();
  }

  bool _removeIdFromTree(NoteFolder current, String targetId) {
    if (current.subFolderIds.contains(targetId)) {
      current.subFolderIds.remove(targetId);
      StorageService.instance.folderBox.put(current.id, current);
      return true;
    }
    for (var sub in current.subFolders) {
      if (_removeIdFromTree(sub, targetId)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final List<SidebarItem> libraryItems = [
      const SidebarItem(
          id: _idAll, name: 'All Notes', icon: Icons.description, isCore: true),
      const SidebarItem(
          id: _idArchived,
          name: 'Archived',
          icon: Icons.archive_outlined,
          isCore: true),
    ];

    return SidebarUI(
      colors: widget.colors,
      currentFolderId: widget.currentFolderId,
      pinnedFolderId: _defaultFolderId,
      folderCounts: _folderCounts,
      headerFlex: 1,
      bottomFlex: 1,
      sections: [
        SidebarSection(title: "LIBRARY", items: libraryItems, flex: 2),
        SidebarSection(title: "FOLDERS", items: _folderItems, flex: 6),
      ],
      onSelect: _handleSelect,
      onPin: _handlePin,
      onDelete: _handleDelete,
      onRename: _handleRename,
      onAdd: _handleAddNew,
    );
  }
}
