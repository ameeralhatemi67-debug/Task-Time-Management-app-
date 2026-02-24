import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import '../models/task_folder_model.dart';

class SectionPickerDialog extends StatelessWidget {
  final AppColors colors;
  final TaskFolder folder;
  final Function(String) onSectionSelected;

  const SectionPickerDialog({
    super.key,
    required this.colors,
    required this.folder,
    required this.onSectionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: colors.bgMiddle,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Move to Section",
              style: TextStyle(
                color: colors.textMain,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            ...folder.sections.map((section) => _buildOption(context, section)),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel",
                    style: TextStyle(color: colors.textSecondary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, String section) {
    return InkWell(
      onTap: () {
        onSectionSelected(section);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: colors.bgTop,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.textSecondary.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(Icons.view_column, size: 18, color: colors.textSecondary),
            const SizedBox(width: 12),
            Text(
              section,
              style: TextStyle(
                color: colors.textMain,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
