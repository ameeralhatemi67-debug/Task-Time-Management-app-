import 'dart:async'; // For StreamSubscription
import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import '../../../core/widgets/theme_test_view.dart';

// --- NEW: Toolbar Import ---
import 'package:task_manager_app/core/widgets/app_toolbar_container.dart';

// --- NEW: Sidebar Import ---
import 'package:task_manager_app/core/widgets/side_bar.dart';

// SERVICES & REPOS
import 'package:task_manager_app/core/services/notification_service.dart';
import 'package:task_manager_app/data/repositories/habit_repository.dart';
import 'package:task_manager_app/features/smart_add/services/smart_nudge_manager.dart';

// CORE WIDGETS
import 'package:task_manager_app/core/widgets/create_task_button.dart';

class HomePage extends StatefulWidget {
  // Callback for MainScaffold animation
  final Function(bool isOpen)? onDrawerChanged;

  const HomePage({
    super.key,
    this.onDrawerChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  StreamSubscription<String?>? _notificationSubscription;
  final HabitRepository _habitRepo = HabitRepository();

  // Scaffold Key to control the drawer from the icon
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // --- NEW: Track Current Folder ID ---
  String _currentFolderId = 'all_folders';

  @override
  void initState() {
    super.initState();

    _setupNotificationListener();

    Future.delayed(const Duration(seconds: 2), () {
      SmartNudgeManager.instance.triggerDailyNudges();
    });
  }

  void _setupNotificationListener() {
    _notificationSubscription =
        NotificationService().onNotificationClick.listen((payload) {
      if (payload != null && payload.startsWith('reschedule_habit:')) {
        final habitId = payload.split(':')[1];
        _showRescheduleDialog(habitId);
      }
    });
  }

  void _showRescheduleDialog(String habitId) {
    final habit = _habitRepo.getById(habitId);
    if (habit == null) return;

    final colors = Theme.of(context).extension<AppColors>()!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgMiddle,
        title:
            Text("Smart Suggestion", style: TextStyle(color: colors.textMain)),
        content: Text(
          "You've missed '${habit.title}' a few times recently. Would you like to move it to a different day to keep your streak?",
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text("Not now", style: TextStyle(color: colors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Habit reschedule logic triggered",
                      style: TextStyle(color: colors.bgMain)),
                  backgroundColor: colors.completedWork,
                ),
              );
            },
            child: Text("Yes, Move it",
                style: TextStyle(
                    color: colors.highlight, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      key: _scaffoldKey, // Assigned key
      onDrawerChanged: widget.onDrawerChanged,
      drawer: Sidebar(
        colors: colors,
        // FIX: Pass the current ID to satisfy the new requirement
        currentFolderId: _currentFolderId,
        onUpdate: () {
          setState(() {});
        },
        // FIX: Update local state when a folder is selected
        onFolderSelected: (folderId, folder) {
          setState(() {
            _currentFolderId = folderId;
          });
        },
      ),
      body: Column(
        children: [
          // 1. ADDED HEADER TOOLBAR
          AppToolbarContainer(
            colors: colors,
            height: 60,
            child: Row(
              children: [
                // Hamburger Menu Icon
                IconButton(
                  icon: Icon(Icons.menu, color: colors.textMain),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                const SizedBox(width: 10),
                Text(
                  // Optional: Show Folder Name in Title
                  _currentFolderId == 'all_folders'
                      ? "Overview"
                      : (_currentFolderId == 'archived'
                          ? "Archived"
                          : "Folder View"),
                  style: TextStyle(
                    color: colors.textMain,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // 2. MAIN CONTENT
          Expanded(
            child: ThemeTestView(pageName: "Home Page - $_currentFolderId"),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100, right: 10),
        child: CreateTaskButton(
          isMenuEnabled: true,
          onPressed: () {},
        ),
      ),
    );
  }
}
