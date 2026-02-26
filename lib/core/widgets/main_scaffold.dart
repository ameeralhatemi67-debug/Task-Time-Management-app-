import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import 'expandable_nav_bar.dart'; // Keeping file name same to avoid import errors

// --- PAGE IMPORTS ---
import '../../features/home/pages/home_page.dart';
import '../../features/notes/pages/notes_page.dart';
import '../../features/tasks/pages/tasks_page.dart';
import '../../features/habits/pages/habits_page.dart';
import '../../features/focus/pages/focus_page.dart';
import '../../features/settings/pages/settings_page.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  // Default Page is Home
  NavItem _currentItem = NavItem.tasks;

  // State to track UI overlays
  bool _isInnerDrawerOpen = false;
  bool _isFocusModeActive = false;
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
  }

  Widget _getPage(NavItem item) {
    switch (item) {
      case NavItem.tasks:
        return TasksPage(
          onDrawerChanged: (isOpen) =>
              setState(() => _isInnerDrawerOpen = isOpen),
          onSelectionModeChanged: (isSelecting) =>
              setState(() => _isSelectionMode = isSelecting),
        );

      case NavItem.home:
        return HomePage(
          onDrawerChanged: (isOpen) =>
              setState(() => _isInnerDrawerOpen = isOpen),
        );

      case NavItem.habits:
        return HabitsPage(
          onDrawerChanged: (isOpen) =>
              setState(() => _isInnerDrawerOpen = isOpen),
          onSelectionModeChanged: (isSelecting) =>
              setState(() => _isSelectionMode = isSelecting),
        );

      case NavItem.focus:
        return const FocusPage();

      case NavItem.notes:
        return NotesPage(
          onDrawerChanged: (isOpen) =>
              setState(() => _isInnerDrawerOpen = isOpen),
          onSelectionModeChanged: (isSelecting) =>
              setState(() => _isSelectionMode = isSelecting),
        );

      case NavItem.settings:
        return const SettingsPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    // Logic: Hide Nav Bar if (Drawer Open) OR (Focus Running) OR (Selecting Items)
    final bool hideNavBar =
        _isInnerDrawerOpen || _isFocusModeActive || _isSelectionMode;

    return Scaffold(
      backgroundColor: colors.bgMain,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. THE ACTIVE PAGE
          Positioned.fill(
            child: _getPage(_currentItem),
          ),

          // 2. THE FLOATING NAVIGATION BAR (Simplified)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: hideNavBar ? Curves.easeInBack : Curves.easeOutBack,
            // Slide down (off-screen) if hidden
            bottom: hideNavBar ? -150 : 0,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: PrimaryNavBar(
                currentItem: _currentItem,
                onItemSelected: (item) {
                  setState(() => _currentItem = item);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
