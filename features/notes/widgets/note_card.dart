import 'package:flutter/material.dart';
import '../models/note_model.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';

class NoteCard extends StatelessWidget {
  final NoteModel note;
  final bool isSlimView;
  final AppColors colors;
  final VoidCallback onTap;

  const NoteCard({
    super.key,
    required this.note,
    required this.isSlimView,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: colors.bgMiddle,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.bgBottom),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isSlimView ? _buildSlimView() : _buildCardView(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // VIEW 1: SLIM (Row) - Title & Date Only
  // ---------------------------------------------------------------------------
  Widget _buildSlimView() {
    return Row(
      children: [
        Icon(Icons.notes, color: colors.textSecondary, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            note.title.isNotEmpty ? note.title : "No Title",
            style: TextStyle(
              color: colors.textMain,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          note.formattedDate,
          style: TextStyle(
            color: colors.textSecondary.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // VIEW 2: CARD (Column) - Dynamic Height (Max 5 lines)
  // ---------------------------------------------------------------------------
  Widget _buildCardView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Shrinks to fit content
      children: [
        // Title Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                note.title.isNotEmpty ? note.title : "No Title",
                style: TextStyle(
                  color: colors.textMain,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              note.formattedDate,
              style: TextStyle(
                color: colors.textSecondary.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),

        // Content Preview (Only if content exists)
        if (note.content.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            note.content,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
              height: 1.4, // Good readability
            ),
            maxLines: 5, // <--- The "3rd design" limit
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
