import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';

class AlignmentSheet extends StatelessWidget {
  final AppColors colors;
  final Function(TextAlign) onAlignSelected;

  const AlignmentSheet({
    super.key,
    required this.colors,
    required this.onAlignSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 60,
        right: 20,
      ), // Floats above toolbar, right side
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.bgMiddle,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIcon(Icons.format_align_left, TextAlign.left),
          const SizedBox(width: 10),
          _buildIcon(Icons.format_align_center, TextAlign.center),
          const SizedBox(width: 10),
          _buildIcon(Icons.format_align_right, TextAlign.right),
          const SizedBox(width: 10),
          _buildIcon(Icons.format_align_justify, TextAlign.justify),
        ],
      ),
    );
  }

  Widget _buildIcon(IconData icon, TextAlign align) {
    return IconButton(
      icon: Icon(icon, color: colors.textMain),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: () => onAlignSelected(align),
    );
  }
}
