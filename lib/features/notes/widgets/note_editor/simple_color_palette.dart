import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';

class SimpleColorPalette extends StatelessWidget {
  final AppColors colors;
  final Function(Color) onColorSelected;
  final VoidCallback onCustomColorPressed;
  final VoidCallback onClose;

  const SimpleColorPalette({
    super.key,
    required this.colors,
    required this.onColorSelected,
    required this.onCustomColorPressed,
    required this.onClose,
  });

  // Row 1: 9 Basic Colors
  static const List<Color> _row1 = [
    Colors.black,
    Colors.white,
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.tealAccent,
    Colors.cyan,
    Colors.blue,
  ];

  // Row 2: 9 Shades + Gradient Button will be added manually
  static const List<Color> _row2 = [
    Color(0xFF4D4D4D), // Dark Grey
    Color(0xFF9E9E9E), // Grey
    Color(0xFFBDBDBD), // Light Grey
    Color(0xFFE0E0E0), // Lighter Grey
    Colors.pinkAccent,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.brown,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ), // Slim margins
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 15), // Tighter padding
      decoration: BoxDecoration(
        color: colors.bgMiddle,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Font Color",
                style: TextStyle(
                  fontSize: 14, // Smaller font
                  fontWeight: FontWeight.bold,
                  color: colors.textMain,
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: Icon(Icons.close, size: 18, color: colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 1 (9 items)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _row1.map((c) => _buildColorButton(c)).toList(),
          ),

          const SizedBox(height: 8), // Gap between rows
          // Row 2 (10 items: 9 colors + Gradient)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ..._row2.map((c) => _buildColorButton(c)),

              // Gradient Button (The 10th item)
              GestureDetector(
                onTap: onCustomColorPressed,
                child: Container(
                  width: 30,
                  height: 30, // Matches button size
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.red, Colors.blue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.edit, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    return GestureDetector(
      onTap: () {
        onColorSelected(color);
        onClose();
      },
      child: Container(
        width: 30,
        height: 30, // Slimmer buttons (30px)
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
      ),
    );
  }
}
