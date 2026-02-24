import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';

class FontSizeSheet extends StatelessWidget {
  final AppColors colors;
  final double currentSize;
  final Function(double) onSizeSelected;

  const FontSizeSheet({
    super.key,
    required this.colors,
    required this.currentSize,
    required this.onSizeSelected,
  });

  // Standard sizes that map well to editor logic
  static const List<double> _sizes = [12, 14, 16, 18, 20, 24, 30, 36];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80, // Slimmer horizontal container
      margin: const EdgeInsets.only(bottom: 10, left: 10, right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
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
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _sizes.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final double value = _sizes[index];
                final bool isSelected = (value - currentSize).abs() < 1;

                return GestureDetector(
                  onTap: () => onSizeSelected(value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? colors.highlight : colors.bgMain,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? colors.highlight
                            : colors.textSecondary.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? colors.textHighlighted
                            : colors.textMain,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
