import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';

class MoreMenuSheet extends StatelessWidget {
  const MoreMenuSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
      decoration: BoxDecoration(
        color: colors.bgMain, // User requested bgMain
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Handle Bar (Visual cue)
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.textSecondary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 30),

          // 2. The Grid of Options
          Wrap(
            spacing: 25,
            runSpacing: 25,
            alignment: WrapAlignment.center,
            children: [
              _buildMenuItem(context, Icons.calendar_month, "Calendar", colors),
              _buildMenuItem(context, Icons.bar_chart, "Progress", colors),
              _buildMenuItem(context, Icons.settings, "Settings", colors),
              _buildMenuItem(context, Icons.person, "Profile", colors),

              // Divider or spacing if needed, but Wrap handles flow nicely

              // The "Edit" Option (Special interaction)
              _buildMenuItem(context, Icons.edit, "Edit", colors,
                  isAction: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, IconData icon, String label, AppColors colors,
      {bool isAction = false}) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // Close sheet
        if (isAction) {
          // TODO: Trigger "Edit/Reorder" mode
          // _showReorderDialog(context);
        } else {
          // TODO: Navigate to respective page
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: colors.bgMiddle, // Slightly distinct background for button
              borderRadius: BorderRadius.circular(18),
              border: isAction
                  ? Border.all(color: colors.textMain.withOpacity(0.1))
                  : null,
            ),
            child: Icon(
              icon,
              size: 28,
              color: colors.textMain, // User requested textMain
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: colors.textMain,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
