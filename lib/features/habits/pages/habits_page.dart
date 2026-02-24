import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import 'package:task_manager_app/core/theme/theme_controller.dart';
import 'package:task_manager_app/core/services/auth_service.dart';
import 'package:task_manager_app/core/widgets/create_task_button.dart';
import 'package:task_manager_app/core/widgets/profile_bubble.dart';

import '../models/habit_model.dart';
import '../../../data/repositories/habit_repository.dart';

// Widgets
import '../widgets/weekly_habit_card.dart';
import '../widgets/monthly_habit_card.dart';
import '../widgets/yearly_habit_card.dart';
import '../widgets/habit_sidebar.dart'; // <--- NEW IMPORT
import '../widgets/streak_bar.dart';
import 'habit_form_page.dart';

class HabitsPage extends StatefulWidget {
  final Function(bool isOpen)? onDrawerChanged;
  final Function(bool isSelecting)? onSelectionModeChanged;

  const HabitsPage({
    super.key,
    this.onDrawerChanged,
    this.onSelectionModeChanged,
  });

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage>
    with SingleTickerProviderStateMixin {
  final HabitRepository _repo = HabitRepository();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // State
  String _selectedFolderId = HabitRepository.idAll;
  String _currentFolderName = "All Habits";

  // Selection Mode
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  // Animation for Bulk Action Bar
  late AnimationController _barController;
  late Animation<Offset> _actionBarOffset;

  @override
  void initState() {
    super.initState();
    _selectedFolderId = _repo.getDefaultFolder();
    _updateFolderName();

    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _actionBarOffset = Tween<Offset>(
      begin: const Offset(0, 2.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _barController,
      curve: Curves.easeOutBack,
    ));
  }

  @override
  void dispose() {
    _barController.dispose();
    super.dispose();
  }

  // --- FOLDER LOGIC ---
  void _updateFolderName() {
    if (_selectedFolderId == HabitRepository.idAll) {
      _currentFolderName = "All Habits";
    } else if (_selectedFolderId == HabitRepository.idArchived) {
      _currentFolderName = "Archived";
    } else if (_selectedFolderId == HabitRepository.coreWeekly) {
      _currentFolderName = "Weekly";
    } else if (_selectedFolderId == HabitRepository.coreMonthly) {
      _currentFolderName = "Monthly";
    } else if (_selectedFolderId == HabitRepository.coreYearly) {
      _currentFolderName = "Yearly";
    } else {
      final folders = _repo.getFolders();
      final match = folders.where((f) => f.id == _selectedFolderId);
      _currentFolderName = match.isNotEmpty ? match.first.name : "Habits";
    }
  }

  // --- ACTIONS ---

  void _openHabitForm({HabitModel? habit}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HabitFormPage(
          existingHabit: habit,
          initialFolderId: _repo.isCoreFolder(_selectedFolderId) ||
                  _selectedFolderId == HabitRepository.idAll ||
                  _selectedFolderId == HabitRepository.idArchived
              ? null
              : _selectedFolderId,
        ),
      ),
    );
  }

  void _toggleHabitCheck(HabitModel habit) async {
    habit.toggleCompletion(DateTime.now());
  }

  // --- SELECTION MODE ---

  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.clear();
    });
    widget.onSelectionModeChanged?.call(true);
    _barController.forward();
  }

  void _exitSelectionMode() {
    _barController.reverse();
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
    widget.onSelectionModeChanged?.call(false);
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _exitSelectionMode();
      } else {
        _selectedIds.add(id);
        if (!_isSelectionMode) _enterSelectionMode();
      }
    });
  }

  Future<void> _performBulkPin() async {
    await _repo.bulkPin(_selectedIds.toList(), true);
    _exitSelectionMode();
  }

  Future<void> _performBulkArchive() async {
    await _repo.bulkArchive(_selectedIds.toList(), true);
    _exitSelectionMode();
  }

  Future<void> _performBulkDelete() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Habits?"),
        content: Text(
            "Are you sure you want to delete ${_selectedIds.length} habits?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _repo.bulkDelete(_selectedIds.toList());
      _exitSelectionMode();
    }
  }

  Future<void> _performBulkMove(AppColors colors) async {
    final folders =
        _repo.getFolders().where((f) => !_repo.isCoreFolder(f.id)).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bgMiddle,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Move to Custom Folder...",
                style: TextStyle(
                    color: colors.textMain, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            title: Text("Remove from Folder",
                style: TextStyle(color: colors.textMain)),
            onTap: () async {
              await _repo.bulkMove(_selectedIds.toList(), null);
              if (mounted) Navigator.pop(ctx);
              _exitSelectionMode();
            },
          ),
          ...folders.map((f) => ListTile(
                title: Text(f.name, style: TextStyle(color: colors.textMain)),
                leading: Icon(Icons.folder, color: colors.highlight),
                onTap: () async {
                  await _repo.bulkMove(_selectedIds.toList(), f.id);
                  if (mounted) Navigator.pop(ctx);
                  _exitSelectionMode();
                },
              )),
        ],
      ),
    );
  }

  DateTime _getFirstLaunchDate(List<HabitModel> habits) {
    if (habits.isEmpty) return DateTime.now();
    DateTime earliest = habits.first.startDate;
    for (var h in habits) {
      if (h.startDate.isBefore(earliest)) earliest = h.startDate;
    }
    return earliest;
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = AuthService.instance.currentUser;
    final String displayName = user?.displayName ?? "User";

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: colors.bgMain,

      // 1. REPLACED DRAWER
      drawer: HabitSidebar(
        colors: colors,
        currentFolderId: _selectedFolderId,
        onFolderSelected: (folderId, folder) {
          setState(() {
            _selectedFolderId = folderId;
            _updateFolderName();
            _exitSelectionMode();
          });
        },
        onUpdate: () => setState(() {}),
      ),
      onDrawerChanged: widget.onDrawerChanged,

      // 2. FAB
      floatingActionButton: !_isSelectionMode
          ? Padding(
              padding: const EdgeInsets.only(bottom: 100, right: 10),
              child: CreateTaskButton(
                onPressed: () => _openHabitForm(),
              ),
            )
          : null,

      // 3. BODY
      body: GestureDetector(
        onTap: () {
          if (_isSelectionMode) _exitSelectionMode();
        },
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  // HEADER
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: Menu & Title
                        GestureDetector(
                          onTap: () => _scaffoldKey.currentState?.openDrawer(),
                          child: Row(
                            children: [
                              Icon(Icons.menu,
                                  color: colors.textMain, size: 28),
                              const SizedBox(width: 15),
                              Text(
                                _currentFolderName,
                                style: TextStyle(
                                  color: colors.textMain,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Right: Kebab Menu
                        ValueListenableBuilder(
                            valueListenable: _repo.prefsBox.listenable(),
                            builder: (context, _, __) {
                              final bool isGlobalStreak = _repo.getStreakMode();

                              return PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert,
                                    color: colors.textMain),
                                color: colors.bgMiddle,
                                onSelected: (val) {
                                  if (val == 'select') _enterSelectionMode();
                                  if (val == 'theme')
                                    ThemeController.instance.toggleMode();
                                  if (val == 'streak_mode') {
                                    _repo.setStreakMode(!isGlobalStreak);
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'theme',
                                    child: Row(children: [
                                      Icon(
                                          isDark
                                              ? Icons.light_mode
                                              : Icons.dark_mode,
                                          color: colors.textMain),
                                      const SizedBox(width: 10),
                                      Text(isDark ? "Light Mode" : "Dark Mode",
                                          style: TextStyle(
                                              color: colors.textMain)),
                                    ]),
                                  ),
                                  PopupMenuItem(
                                    value: 'streak_mode',
                                    child: Row(children: [
                                      Icon(
                                          isGlobalStreak
                                              ? Icons.public
                                              : Icons.folder_special,
                                          color: colors.textMain),
                                      const SizedBox(width: 10),
                                      Text(
                                          isGlobalStreak
                                              ? "Global Streak"
                                              : "Folder Streak",
                                          style: TextStyle(
                                              color: colors.textMain)),
                                    ]),
                                  ),
                                  PopupMenuItem(
                                    value: 'select',
                                    child: Row(children: [
                                      Icon(Icons.checklist,
                                          color: colors.textMain),
                                      const SizedBox(width: 10),
                                      Text("Select Habits",
                                          style: TextStyle(
                                              color: colors.textMain)),
                                    ]),
                                  ),
                                ],
                              );
                            }),
                      ],
                    ),
                  ),

                  // MAIN CONTENT
                  Expanded(
                    child: ValueListenableBuilder(
                      valueListenable: _repo.box.listenable(),
                      builder: (context, Box<HabitModel> box, _) {
                        // 1. Fetch Data
                        final folderHabits =
                            _repo.getHabitsByFolder(_selectedFolderId);
                        final allActiveHabits = _repo.getAllActiveHabits();

                        // 2. Sort
                        folderHabits.sort((a, b) {
                          if (a.isPinned != b.isPinned) {
                            return a.isPinned ? -1 : 1;
                          }
                          return 0;
                        });

                        return ValueListenableBuilder(
                            valueListenable: _repo.prefsBox.listenable(),
                            builder: (context, _, __) {
                              final bool isGlobalStreak = _repo.getStreakMode();

                              final streakHabits = isGlobalStreak
                                  ? allActiveHabits
                                  : folderHabits;

                              return ListView(
                                padding: const EdgeInsets.only(
                                    left: 20, right: 20, bottom: 150),
                                children: [
                                  const SizedBox(height: 10),
                                  ProfileBubble(
                                    colors: colors,
                                    userName: displayName,
                                  ),
                                  const SizedBox(height: 20),

                                  // STREAK BAR
                                  if (streakHabits.isNotEmpty)
                                    StreakBar(
                                      colors: colors,
                                      habits: streakHabits,
                                      firstLaunchDate:
                                          _getFirstLaunchDate(allActiveHabits),
                                    ),
                                  const SizedBox(height: 20),

                                  // HABIT LIST
                                  if (folderHabits.isEmpty)
                                    Center(
                                      child: Column(
                                        children: [
                                          const SizedBox(height: 40),
                                          Icon(Icons.inbox_outlined,
                                              size: 60,
                                              color: colors.textSecondary
                                                  .withOpacity(0.3)),
                                          const SizedBox(height: 10),
                                          Text(
                                            "No habits in $_currentFolderName",
                                            style: TextStyle(
                                                color: colors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: folderHabits.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 12),
                                      itemBuilder: (context, index) {
                                        final habit = folderHabits[index];
                                        return _buildHabitCard(habit, colors);
                                      },
                                    ),
                                ],
                              );
                            });
                      },
                    ),
                  ),
                ],
              ),

              // 4. BULK ACTION BAR
              Align(
                alignment: Alignment.bottomCenter,
                child: SlideTransition(
                  position: _actionBarOffset,
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    height: 70,
                    decoration: BoxDecoration(
                      color: colors.textMain,
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 15,
                            offset: const Offset(0, 5))
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.close, color: colors.bgMain),
                          onPressed: _exitSelectionMode,
                        ),
                        if (_selectedIds.isNotEmpty)
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.push_pin_outlined,
                                    color: colors.bgMain),
                                onPressed: _performBulkPin,
                              ),
                              IconButton(
                                icon: Icon(Icons.drive_file_move_outline,
                                    color: colors.bgMain),
                                onPressed: () => _performBulkMove(colors),
                              ),
                              IconButton(
                                icon: Icon(Icons.archive_outlined,
                                    color: colors.bgMain),
                                onPressed: _performBulkArchive,
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline,
                                    color: Colors.redAccent),
                                onPressed: _performBulkDelete,
                              ),
                            ],
                          )
                        else
                          Text(
                            "${_selectedIds.length} Selected",
                            style: TextStyle(
                              color: colors.bgMain,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHabitCard(HabitModel habit, AppColors colors) {
    final bool isSelected = _selectedIds.contains(habit.id);

    void onTap() {
      if (_isSelectionMode) {
        _toggleSelection(habit.id);
      } else {
        _openHabitForm(habit: habit);
      }
    }

    void onCheck() {
      if (_isSelectionMode) return;
      _toggleHabitCheck(habit);
    }

    switch (habit.type) {
      case HabitType.weekly:
        return WeeklyHabitCard(
          habit: habit,
          colors: colors,
          onTap: onTap,
          onCheckToggle: onCheck,
          isSelectionMode: _isSelectionMode,
          isSelected: isSelected,
          onSelectionToggle: () => _toggleSelection(habit.id),
        );
      case HabitType.monthly:
        return MonthlyHabitCard(
          habit: habit,
          colors: colors,
          onTap: onTap,
          onCheckToggle: onCheck,
          isSelectionMode: _isSelectionMode,
          isSelected: isSelected,
          onSelectionToggle: () => _toggleSelection(habit.id),
        );
      case HabitType.yearly:
        return YearlyHabitCard(
          habit: habit,
          colors: colors,
          onTap: onTap,
          onCheckToggle: onCheck,
          isSelectionMode: _isSelectionMode,
          isSelected: isSelected,
          onSelectionToggle: () => _toggleSelection(habit.id),
        );
    }
  }
}
