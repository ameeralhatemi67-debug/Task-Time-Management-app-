import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import 'package:task_manager_app/features/smart_add/widgets/smart_add_chips.dart';
import 'package:task_manager_app/features/notes/logic/smart_suggestion_manager.dart';

class GhostChipStack extends StatelessWidget {
  final SmartSuggestionManager manager;
  final AppColors colors;

  const GhostChipStack({
    super.key,
    required this.manager,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final chips = manager.activeChips;

    if (chips.isEmpty) return const SizedBox.shrink();

    // "Burger Stack" Logic:
    // We align them to the bottom right.
    // We use reverse: true so they build from the right side.

    return Container(
      height: 45, // Fixed height for the chip row
      alignment: Alignment.centerRight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true, // Takes only needed space
        reverse: true, // Start from the right side
        itemCount: chips.length,
        separatorBuilder: (ctx, i) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final chip = chips[index];

          return UniversalSmartChip(
            label: chip.label,
            icon: chip.icon,
            // Dynamic coloring based on type
            color: _getColorForType(chip.type, colors),
            state: chip.state,
            onTap: () => manager.confirmChip(chip),
            onDelete: () => manager.removeChip(chip),
          );
        },
      ),
    );
  }

  Color _getColorForType(ChipType type, AppColors colors) {
    switch (type) {
      case ChipType.priority:
        return colors.priorityHigh;
      case ChipType.date:
        return colors.highlight;
      case ChipType.habit:
        return colors.completedWork;
      case ChipType.focus:
        return colors.focusLink;
      case ChipType.folder:
        return colors.textSecondary;
      default:
        return colors.textMain;
    }
  }
}
