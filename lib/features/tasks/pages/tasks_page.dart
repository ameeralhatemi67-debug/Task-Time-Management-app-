import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import 'package:task_manager_app/core/theme/theme_controller.dart';
import '../models/task_folder_model.dart';
import '../models/task_model.dart';
import '../../../data/repositories/task_repository.dart';

// --- LOGIC & WIDGETS ---
import '../logic/task_view_controller.dart'; // Imports Enums
import '../widgets/task_sidebar.dart';
import '../widgets/calendar_strip.dart';
import '../widgets/smart_task_card.dart';

// --- CORE WIDGETS ---
import 'package:task_manager_app/core/widgets/create_task_button.dart';
import 'package:task_manager_app/core/widgets/kabab_menu.dart';
import 'package:task_manager_app/core/widgets/swipe_gestures.dart';

// --- SHEETS ---
import 'task_creation_sheet.dart';
import 'task_edit_sheet.dart'; // Required for editing

class TasksPage extends StatefulWidget {
  final Function(bool isOpen)? onDrawerChanged;
  final Function(bool isSelecting)? onSelectionModeChanged;

  const TasksPage({
    super.key,
    this.onDrawerChanged,
    this.onSelectionModeChanged,
  });

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final TaskRepository _repo = TaskRepository();
  final TaskViewController _viewController = TaskViewController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // --- STATE ---
  List<TaskFolder> _folders = [];
  bool _isLoading = true;

  // View State
  SidebarItemType _sidebarType = SidebarItemType.folder;
  int _currentFolderIndex = 0;
  int _currentSectionIndex = -1;

  // View Configuration
  TaskSortOption _currentSort = TaskSortOption.importance;
  DateTime _selectedDate = DateTime.now();

  // Selection Mode
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};
  bool _showActionBar = false; // Controls Animation

  // Calculated Data
  List<TaskModel> _activeTasks = [];
  List<TaskModel> _overdueTasks = [];
  List<TaskModel> _doneTasks = [];

  bool _showNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    var loadedFolders = _repo.getFolders();

    if (loadedFolders.isEmpty) {
      final defaultFolder = TaskFolder.create("Main");
      defaultFolder.sections = ["Tasks", "Routine"];
      await _repo.saveFolder(defaultFolder);
      loadedFolders = _repo.getFolders();
    }

    if (!mounted) return;

    setState(() {
      _folders = loadedFolders;
      if (_folders.isNotEmpty && _currentFolderIndex >= _folders.length) {
        _currentFolderIndex = 0;
      }
      _isLoading = false;
    });

    _refreshTasks();
  }

  void _refreshTasks() {
    final result = _viewController.calculateTaskLists(
      sidebarType: _sidebarType,
      folders: _folders,
      currentFolderIndex: _currentFolderIndex,
      currentSectionIndex: _currentSectionIndex,
      selectedDate: _selectedDate,
      sortOption: _currentSort,
    );

    setState(() {
      _activeTasks = result.active;
      _overdueTasks = result.overdue;
      _doneTasks = result.done;
    });
  }

  // --- HELPER: OPTIMISTIC REMOVAL (Makes UI Snappy) ---
  void _optimisticRemove(String taskId) {
    setState(() {
      _activeTasks.removeWhere((t) => t.id == taskId);
      _overdueTasks.removeWhere((t) => t.id == taskId);
      _doneTasks.removeWhere((t) => t.id == taskId);
    });
  }

  // --- ANIMATED SELECTION ---

  void _enterSelectionMode() async {
    setState(() => _isSelectionMode = true);
    widget.onSelectionModeChanged?.call(true);
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) setState(() => _showActionBar = true);
  }

  void _exitSelectionMode() async {
    if (mounted) setState(() => _showActionBar = false);
    await Future.delayed(const Duration(milliseconds: 200));
    widget.onSelectionModeChanged?.call(false);
    if (mounted) {
      setState(() {
        _isSelectionMode = false;
        _selectedIds.clear();
      });
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      if (!_isSelectionMode && _selectedIds.isNotEmpty) _enterSelectionMode();
      if (_isSelectionMode && _selectedIds.isEmpty) _exitSelectionMode();
    });
  }

  // --- ACTIONS ---

  Future<void> _performBulkAction(
      Future<void> Function(TaskModel) action, String label) async {
    int count = 0;
    // Snapshot IDs to process
    final idsToProcess = List<String>.from(_selectedIds);

    // 1. Optimistic Removal
    for (String id in idsToProcess) {
      _optimisticRemove(id);
    }

    // 2. Perform DB Actions
    for (String id in idsToProcess) {
      final task = _repo.getById(id);
      if (task != null) {
        await action(task);
        count++;
      }
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("$label $count tasks")));
    _exitSelectionMode();
    _refreshTasks(); // Final Sync
  }

  Future<void> _deleteSelected() async {
    await _performBulkAction(
        (t) async => await _repo.deleteTask(t.id), "Deleted");
  }

  Future<void> _archiveSelected() async {
    await _performBulkAction((t) async {
      t.isArchived = true;
      await _repo.addTask(t);
    }, "Archived");
  }

  // --- SINGLE ACTIONS (UPDATED FOR IMMEDIATE FEEDBACK) ---

  void _onTaskCheck(TaskModel task) async {
    if (_isSelectionMode) {
      _toggleSelection(task.id);
      return;
    }
    // Optimistic Toggle can be complex due to recurrence,
    // relying on fast Repo update + setState from _refreshTasks
    await _repo.toggleTask(task);
    _refreshTasks();
  }

  Future<void> _deleteSingle(TaskModel task) async {
    _optimisticRemove(task.id); // Immediate UI update
    await _repo.deleteTask(task.id);
    _refreshTasks(); // Background Sync
  }

  Future<void> _archiveSingle(TaskModel task) async {
    _optimisticRemove(task.id); // Immediate UI update
    task.isArchived = true;
    await _repo.addTask(task);
    _refreshTasks(); // Background Sync
  }

  Future<void> _togglePin(TaskModel task) async {
    setState(() {
      task.isPinned = !task.isPinned; // Immediate visual update
    });
    await _repo.addTask(task);
    _refreshTasks(); // Re-sorts the list
  }

  void _moveTasks(List<String> ids, AppColors colors) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgMiddle,
        title: Text("Move to...", style: TextStyle(color: colors.textMain)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: _folders.length,
            itemBuilder: (ctx, i) {
              final folder = _folders[i];
              return ExpansionTile(
                title:
                    Text(folder.name, style: TextStyle(color: colors.textMain)),
                iconColor: colors.highlight,
                collapsedIconColor: colors.textMain,
                children: folder.sections.map((section) {
                  return ListTile(
                    title: Text(section,
                        style: TextStyle(color: colors.textSecondary)),
                    contentPadding: const EdgeInsets.only(left: 30),
                    onTap: () async {
                      // 1. Optimistic Removal (If viewing a specific folder)
                      if (_sidebarType == SidebarItemType.folder) {
                        for (var id in ids) _optimisticRemove(id);
                      }

                      // 2. DB Update
                      for (var id in ids) {
                        final t = _repo.getById(id);
                        if (t != null) {
                          t.folderId = folder.id;
                          t.sectionName = section;
                          await _repo.addTask(t);
                        }
                      }
                      if (mounted) Navigator.pop(ctx);
                      _exitSelectionMode();
                      _refreshTasks(); // Final Sync
                    },
                  );
                }).toList(),
              );
            },
          ),
        ),
      ),
    );
  }

  // --- NAVIGATION ---

  Future<void> _openCreator() async {
    if (_folders.isEmpty) {
      _loadData();
      return;
    }
    TaskFolder targetFolder =
        _folders.isNotEmpty ? _folders[_currentFolderIndex] : _folders.first;
    String targetSection = "General";

    if (_sidebarType != SidebarItemType.folder) {
      targetFolder = _folders.first;
      if (targetFolder.sections.isNotEmpty)
        targetSection = targetFolder.sections.first;
    } else if (_currentSectionIndex != -1) {
      targetSection = targetFolder.sections[_currentSectionIndex];
    } else if (targetFolder.sections.isNotEmpty) {
      targetSection = targetFolder.sections.first;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          TaskCreationSheet(folder: targetFolder, section: targetSection),
    );
    _loadData();
  }

  // --- UI BUILDERS ---

  String _getCurrentSidebarId() {
    if (_sidebarType == SidebarItemType.all) return 'all_folders';
    if (_sidebarType == SidebarItemType.archived) return 'archived';
    if (_folders.isNotEmpty && _currentFolderIndex < _folders.length) {
      return _folders[_currentFolderIndex].id;
    }
    return '';
  }

  String get _headerTitle {
    if (_sidebarType == SidebarItemType.all) return "All Tasks";
    if (_sidebarType == SidebarItemType.archived) return "Archived";
    if (_folders.isNotEmpty && _currentFolderIndex < _folders.length) {
      final f = _folders[_currentFolderIndex];
      if (_currentSectionIndex != -1 &&
          _currentSectionIndex < f.sections.length) {
        return f.sections[_currentSectionIndex];
      }
      return f.name;
    }
    return "Tasks";
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    if (_isLoading) {
      return Scaffold(
          backgroundColor: colors.bgMain,
          body: Center(
              child: CircularProgressIndicator(color: colors.highlight)));
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: colors.bgMain,
      drawer: TaskSidebar(
        colors: colors,
        currentFolderId: _getCurrentSidebarId(),
        onUpdate: _loadData,
        onFolderSelected: (folderId, folder) {
          setState(() {
            if (folderId == 'all_folders') {
              _sidebarType = SidebarItemType.all;
            } else if (folderId == 'archived') {
              _sidebarType = SidebarItemType.archived;
            } else if (folder != null) {
              _sidebarType = SidebarItemType.folder;
              _currentFolderIndex =
                  _folders.indexWhere((f) => f.id == folder.id);
              _currentSectionIndex = -1;
            }
            _refreshTasks();
          });
        },
      ),
      onDrawerChanged: widget.onDrawerChanged,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                if (_isSelectionMode) _exitSelectionMode();
              },
              behavior: HitTestBehavior.opaque,
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    _buildHeader(colors),
                    CalendarStrip(
                        colors: colors,
                        selectedDate: _selectedDate,
                        onDateSelected: (date) {
                          setState(() => _selectedDate = date);
                          _refreshTasks();
                        }),
                    const SizedBox(height: 15),
                    if (_sidebarType == SidebarItemType.folder &&
                        _folders.isNotEmpty)
                      _buildSectionsBar(colors),
                    if (_sidebarType == SidebarItemType.folder &&
                        _folders.isNotEmpty)
                      const SizedBox(height: 15),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 0),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          children: [
                            if (_activeTasks.isNotEmpty) ...[
                              _buildSectionTitle("ACTIVE", colors),
                              ..._activeTasks
                                  .map((t) => _buildTaskTile(t, colors)),
                            ],
                            if (_overdueTasks.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              _buildSectionTitle("OVERDUE", colors,
                                  isError: true),
                              ..._overdueTasks
                                  .map((t) => _buildTaskTile(t, colors)),
                            ],
                            if (_doneTasks.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              _buildSectionTitle("COMPLETED", colors),
                              ..._doneTasks
                                  .map((t) => _buildTaskTile(t, colors)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!_isSelectionMode)
            Positioned(
              bottom: 131,
              right: 26,
              child: CreateTaskButton(onPressed: _openCreator),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: _showActionBar ? Curves.easeOutBack : Curves.easeInBack,
            bottom: _showActionBar ? 0 : -100,
            left: 0,
            right: 0,
            child: _buildSelectionBar(colors),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.bgMiddle,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.folder_open, color: colors.textMain, size: 24),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              _headerTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textMain,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _showNotifications
                  ? Icons.notifications_active
                  : Icons.notifications_off,
              color:
                  _showNotifications ? colors.highlight : colors.textSecondary,
            ),
            onPressed: () =>
                setState(() => _showNotifications = !_showNotifications),
          ),
          KababMenu(
            colors: colors,
            onThemeChanged: () => ThemeController.instance.toggleMode(),
            onSelectMode: _enterSelectionMode,
            sortItems: [
              PopupMenuItem(
                onTap: () {
                  setState(() => _currentSort = TaskSortOption.alphabetical);
                  _refreshTasks();
                },
                child: Text("A-Z", style: TextStyle(color: colors.textMain)),
              ),
              PopupMenuItem(
                onTap: () {
                  setState(() => _currentSort = TaskSortOption.dateNewest);
                  _refreshTasks();
                },
                child: Text("Newest First",
                    style: TextStyle(color: colors.textMain)),
              ),
              PopupMenuItem(
                onTap: () {
                  setState(() => _currentSort = TaskSortOption.dateOldest);
                  _refreshTasks();
                },
                child: Text("Oldest First",
                    style: TextStyle(color: colors.textMain)),
              ),
              PopupMenuItem(
                onTap: () {
                  setState(() => _currentSort = TaskSortOption.importance);
                  _refreshTasks();
                },
                child: Text("Importance",
                    style: TextStyle(color: colors.textMain)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionsBar(AppColors colors) {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(left: 20),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _folders[_currentFolderIndex].sections.length,
              itemBuilder: (context, index) {
                final isSelected = index == _currentSectionIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() => _currentSectionIndex = index);
                    _refreshTasks();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? colors.textMain : colors.bgMiddle,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _folders[_currentFolderIndex].sections[index],
                      style: TextStyle(
                        color: isSelected ? colors.bgMain : colors.textMain,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.add, size: 26, color: colors.textMain),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildTaskTile(TaskModel task, AppColors colors) {
    if (_isSelectionMode) {
      return _buildSelectionWrapper(task, colors);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SwipeableTile(
        keyId: task.id,
        leadingOptions: [
          SwipeOption(
            icon: Icons.archive,
            color: colors.completedWork,
            label: "Archive",
            onTap: () => _archiveSingle(task),
          ),
          SwipeOption(
            icon: Icons.delete,
            color: colors.priorityHigh,
            label: "Delete",
            onTap: () => _deleteSingle(task),
          ),
        ],
        trailingOptions: [
          SwipeOption(
            icon: task.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
            color: colors.priorityMedium,
            label: task.isPinned ? "Unpin" : "Pin",
            onTap: () => _togglePin(task),
          ),
          SwipeOption(
            icon: Icons.drive_file_move,
            color: colors.priorityLow,
            label: "Move",
            onTap: () => _moveTasks([task.id], colors),
          ),
        ],
        child: SmartTaskCard(
          task: task,
          colors: colors,
          onCheck: () => _onTaskCheck(task),
          onLongPress: () => _toggleSelection(task.id),
          // --- FIXED: ADDED onBodyTap ---
          onBodyTap: () => TaskEditSheet.show(context, task),
        ),
      ),
    );
  }

  Widget _buildSelectionWrapper(TaskModel task, AppColors colors) {
    final isSelected = _selectedIds.contains(task.id);
    return GestureDetector(
      onTap: () => _toggleSelection(task.id),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SmartTaskCard(
              task: task,
              colors: colors,
              onCheck: () {},
              onLongPress: () {},
              // Disable edit in selection mode
              onBodyTap: () => _toggleSelection(task.id),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? colors.highlight
                    : colors.bgMain.withOpacity(0.5),
                border: Border.all(color: colors.highlight, width: 2),
              ),
              padding: const EdgeInsets.all(4),
              child: isSelected
                  ? Icon(Icons.check, size: 16, color: colors.textHighlighted)
                  : const SizedBox(width: 16, height: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, AppColors colors,
      {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          color: isError ? colors.priorityHigh : colors.textSecondary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSelectionBar(AppColors colors) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: colors.bgMiddle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBarBtn(Icons.drive_file_move, "Move", colors.textMain,
              () => _moveTasks(_selectedIds.toList(), colors)),
          _buildBarBtn(
              Icons.archive, "Archive", colors.textMain, _archiveSelected),
          _buildBarBtn(
              Icons.delete, "Delete", colors.priorityHigh, _deleteSelected),
        ],
      ),
    );
  }

  Widget _buildBarBtn(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          Text(label, style: TextStyle(color: color, fontSize: 10)),
        ],
      ),
    );
  }
}
