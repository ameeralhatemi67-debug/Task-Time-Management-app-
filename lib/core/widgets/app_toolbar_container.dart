import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';

class AppToolbarContainer extends StatelessWidget {
  final AppColors colors;
  final Widget child;
  final double height;

  const AppToolbarContainer({
    super.key,
    required this.colors,
    required this.child,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: colors.bgMiddle,
        border: Border(
          top: BorderSide(color: colors.bgBottom.withOpacity(0.5), width: 1),
        ),
      ),
      child: child,
    );
  }
}
