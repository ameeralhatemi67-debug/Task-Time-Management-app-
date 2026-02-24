import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';

// --- PAGE ENUM ---
enum NavItem {
  home(Icons.home_filled, "Home"),
  tasks(Icons.check_box_outlined, "Tasks"),
  habits(Icons.sync, "Habits"), // Changed to Sync icon for Habits
  focus(Icons.filter_center_focus, "Focus"),
  notes(Icons.description_outlined, "Notes"), // Document icon for Notes
  settings(Icons.settings, "Settings");

  final IconData icon;
  final String label;
  const NavItem(this.icon, this.label);
}

class PrimaryNavBar extends StatelessWidget {
  final NavItem currentItem;
  final Function(NavItem) onItemSelected;

  const PrimaryNavBar({
    super.key,
    required this.currentItem,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // The fixed list of 6 items
    final items = [
      NavItem.home,
      NavItem.tasks,
      NavItem.habits,
      NavItem.focus,
      NavItem.notes,
      NavItem.settings,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: colors.bgMiddle,
          borderRadius: BorderRadius.circular(35), // Pill shape
          border: Border.all(
            color: isDark
                ? colors.textSecondary.withOpacity(0.2)
                : colors.bgBottom,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: items.map((item) {
            final bool isSelected = currentItem == item;

            // Highlight Color Logic
            final Color activeBg =
                isDark ? colors.textHighlighted : colors.bgTop;
            final Color activeIcon = colors.textMain;
            final Color inactiveIcon = colors.textSecondary;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onItemSelected(item);
                },
                behavior: HitTestBehavior.opaque, // Ensure tap area is full
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: isSelected ? activeBg : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.icon,
                        size: 24,
                        color: isSelected ? activeIcon : inactiveIcon,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
