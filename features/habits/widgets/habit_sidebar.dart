import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';

// UI COMPONENT
import 'package:task_manager_app/core/widgets/sidebar_ui.dart';

// DATA & MODELS
import 'package:task_manager_app/data/repositories/habit_repository.dart';
import 'package:task_manager_app/features/habits/models/habit_folder_model.dart';

class HabitSidebar extends StatefulWidget {
  final AppColors colors;
  final String currentFolderId;
  final VoidCallback onUpdate;
  final Function(bool isOpen)? onDrawerChanged;
  final Function(String folderId, HabitFolder? folder)? onFolderSelected;

  const HabitSidebar({
    super.key,
    required this.colors,
    required this.currentFolderId,
    required this.onUpdate,
    this.onDrawerChanged,
    this.onFolderSelected,
  });

  @override
  State<HabitSidebar> createState() => _HabitSidebarState();
}

class _HabitSidebarState extends State<HabitSidebar> {
  final HabitRepository _repo = HabitRepository();

  late String _defaultFolderId;
  List<HabitFolder> _userFolders = [];
  Map<String, int> _folderCounts = {};

  @override
  void initState() {
    super.initState();
    _loadPin();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant HabitSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onUpdate != widget.onUpdate) {
      _loadData();
    }
  }

  // --- DATA LOADING ---

  void _loadPin() {
    setState(() {
      _defaultFolderId = _repo.getDefaultFolder();
    });
  }

  void _loadData() {
    final allFolders = _repo.getFolders();
    final customFolders =
        allFolders.where((f) => !_repo.isCoreFolder(f.id)).toList();

    final Map<String, int> counts = {};

    // Core Counts
    counts[HabitRepository.idAll] = _repo.getAllActiveHabits().length;
    counts[HabitRepository.idArchived] = _repo.getArchivedHabits().length;
    counts[HabitRepository.coreWeekly] =
        _repo.getHabitsByFolder(HabitRepository.coreWeekly).length;
    counts[HabitRepository.coreMonthly] =
        _repo.getHabitsByFolder(HabitRepository.coreMonthly).length;
    counts[HabitRepository.coreYearly] =
        _repo.getHabitsByFolder(HabitRepository.coreYearly).length;

    // Custom Counts
    for (var f in customFolders) {
      counts[f.id] = _repo.getHabitsByFolder(f.id).length;
    }

    if (mounted) {
      setState(() {
        _userFolders = customFolders;
        _folderCounts = counts;
      });
    }
  }

  // --- LOGIC ACTIONS ---

  void _handleSelect(SidebarItem item) {
    if (widget.onFolderSelected != null) {
      if (item.isCore) {
        // Pass null folder object for core items
        widget.onFolderSelected!(item.id, null);
      } else {
        // Find the original HabitFolder object
        try {
          final folder = _userFolders.firstWhere((f) => f.id == item.id);
          widget.onFolderSelected!(item.id, folder);
        } catch (e) {
          print("HabitSidebar: Error finding folder: $e");
        }
      }
    }
  }

  void _handlePin(SidebarItem item) async {
    await _repo.setDefaultFolder(item.id);
    setState(() => _defaultFolderId = item.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Set as startup folder",
              style: TextStyle(color: widget.colors.textMain)),
          duration: const Duration(seconds: 1),
          backgroundColor: widget.colors.bgMiddle,
        ),
      );
    }
  }

  Future<void> _handleAddNew(String name, bool isSubFolder) async {
    if (isSubFolder) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Sub-folders are not available for Habits yet.",
              style: TextStyle(color: widget.colors.textMain)),
          backgroundColor: widget.colors.bgMiddle,
        ),
      );
      return;
    }

    await _repo.createFolder(name);
    _loadData();
    widget.onUpdate();
  }

  Future<void> _handleRename(SidebarItem item, String newName) async {
    await _repo.renameFolder(item.id, newName);
    _loadData();
    widget.onUpdate();
  }

  Future<void> _handleDelete(SidebarItem item) async {
    // If we are deleting the pinned folder, reset to All
    if (_defaultFolderId == item.id) {
      _repo.setDefaultFolder(HabitRepository.idAll);
      setState(() => _defaultFolderId = HabitRepository.idAll);
    }

    await _repo.deleteFolder(item.id);

    // If we deleted the currently viewed folder, notify parent
    if (widget.currentFolderId == item.id) {
      widget.onFolderSelected!(HabitRepository.idAll, null);
    }

    _loadData();
    widget.onUpdate();
  }

  // --- BUILD ---

  @override
  Widget build(BuildContext context) {
    // 1. Prepare Data Groups

    // Group A: Library (All, Archived)
    final libraryItems = [
      const SidebarItem(
        id: HabitRepository.idAll,
        name: 'All Habits',
        icon: Icons.all_inbox,
        isCore: true,
      ),
      const SidebarItem(
        id: HabitRepository.idArchived,
        name: 'Archived',
        icon: Icons.archive_outlined,
        isCore: true,
      ),
    ];

    // Group B: Frequencies (Weekly, Monthly, Yearly)
    final frequencyItems = [
      const SidebarItem(
        id: HabitRepository.coreWeekly,
        name: 'Weekly',
        icon: Icons.view_week,
        isCore: true,
      ),
      const SidebarItem(
        id: HabitRepository.coreMonthly,
        name: 'Monthly',
        icon: Icons.calendar_view_month,
        isCore: true,
      ),
      const SidebarItem(
        id: HabitRepository.coreYearly,
        name: 'Yearly',
        icon: Icons.calendar_today,
        isCore: true,
      ),
    ];

    // Group C: User Folders
    final folderItems = _userFolders
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

      // CONFIGURATION: NEW 3-SECTION LAYOUT (1, 2, 3, 5, 1)
      headerFlex: 1,
      bottomFlex: 1,
      sections: [
        SidebarSection(title: "LIBRARY", items: libraryItems, flex: 2),
        SidebarSection(title: "FREQUENCIES", items: frequencyItems, flex: 3),
        SidebarSection(title: "FOLDERS", items: folderItems, flex: 5),
      ],

      onSelect: _handleSelect,
      onPin: _handlePin,
      onDelete: _handleDelete,
      onRename: _handleRename,
      onAdd: _handleAddNew,
    );
  }
}
