import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';

class KababMenu extends StatelessWidget {
  final AppColors colors;
  final Function() onThemeChanged;
  final Function() onSelectMode;

  // Optional: View Toggle (Hidden if null)
  final bool? isSlimView;
  final Function()? onViewChanged;

  // Generic Sort Items (Allows each page to define its own sorting logic)
  final List<PopupMenuEntry> sortItems;

  const KababMenu({
    super.key,
    required this.colors,
    required this.onThemeChanged,
    required this.onSelectMode,
    required this.sortItems,
    this.isSlimView,
    this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: colors.textMain),
      color: colors.bgMiddle,
      onSelected: (val) {
        if (val == 'theme') onThemeChanged();
        if (val == 'select') onSelectMode();
        if (val == 'view' && onViewChanged != null) onViewChanged!();
      },
      itemBuilder: (context) => [
        // 1. VIEW TOGGLE (Conditional)
        if (onViewChanged != null && isSlimView != null)
          PopupMenuItem(
            value: 'view',
            child: Row(children: [
              Icon(
                isSlimView! ? Icons.view_agenda : Icons.view_headline,
                size: 18,
                color: colors.textMain,
              ),
              const SizedBox(width: 8),
              Text(
                isSlimView! ? "Card View" : "Slim View",
                style: TextStyle(color: colors.textMain),
              ),
            ]),
          ),

        // 2. SELECT MODE
        PopupMenuItem(
          value: 'select',
          child: Row(children: [
            Icon(Icons.checklist, size: 18, color: colors.textMain),
            const SizedBox(width: 8),
            Text("Select", style: TextStyle(color: colors.textMain)),
          ]),
        ),

        // 3. SORT OPTIONS (Sub-menu)
        PopupMenuItem(
          child: SubmenuButton(
            menuChildren: sortItems,
            child: Row(children: [
              Icon(Icons.sort, size: 18, color: colors.textMain),
              const SizedBox(width: 8),
              Text("Sort By", style: TextStyle(color: colors.textMain)),
            ]),
          ),
        ),

        // 4. THEME TOGGLE
        PopupMenuItem(
          value: 'theme',
          child: Row(children: [
            Icon(Icons.brightness_6, size: 18, color: colors.textMain),
            const SizedBox(width: 8),
            Text("Toggle Theme", style: TextStyle(color: colors.textMain)),
          ]),
        ),
      ],
    );
  }
}
