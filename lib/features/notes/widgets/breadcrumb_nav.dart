import 'package:flutter/material.dart';
import '../models/note_folder_model.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';

class BreadcrumbNav extends StatelessWidget {
  // The full path to the current folder (e.g. [Root, Personal, Ideas])
  final List<NoteFolder> path;
  // Callback when a user clicks a parent folder
  final Function(NoteFolder) onFolderSelected;
  final AppColors colors;

  const BreadcrumbNav({
    super.key,
    required this.path,
    required this.onFolderSelected,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    // We use a ListView to allow scrolling if the path gets very deep
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // Match the padding of your other headers
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: path.length,
        separatorBuilder: (context, index) => Icon(
          Icons.chevron_right,
          color: colors.textSecondary.withOpacity(0.5),
          size: 20,
        ),
        itemBuilder: (context, index) {
          final folder = path[index];
          final isLast = index == path.length - 1;

          return GestureDetector(
            onTap: () {
              // Only trigger navigation if we click a parent (not the current page)
              if (!isLast) {
                onFolderSelected(folder);
              }
            },
            child: Container(
              alignment: Alignment.center,
              color: Colors.transparent, // Increases tap area
              child: Text(
                folder.name,
                style: TextStyle(
                  // Last item (Current) is Bold & Main Color
                  // Parents are Secondary Color (indicating clickable history)
                  color: isLast ? colors.textMain : colors.textSecondary,
                  fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
