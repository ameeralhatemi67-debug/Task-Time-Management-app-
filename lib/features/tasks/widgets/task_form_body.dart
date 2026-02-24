import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:intl/intl.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';

class TaskFormBody extends StatelessWidget {
  final AppColors colors;
  final TextEditingController titleController;
  final quill.QuillController quillController;
  final Function(String)? onTitleSubmitted;

  // --- Meta Data for Chips ---
  final DateTime? reminderTime;
  final DateTime? startTime;
  final DateTime? activePeriodStart;
  final DateTime? activePeriodEnd;
  final int? durationMinutes;
  final String? location;

  // Habit Data
  final bool isHabit;
  final int? habitGoal;
  final bool isStreakCount;

  const TaskFormBody({
    super.key,
    required this.colors,
    required this.titleController,
    required this.quillController,
    this.onTitleSubmitted,
    // Meta Fields
    this.reminderTime,
    this.startTime,
    this.activePeriodStart,
    this.activePeriodEnd,
    this.durationMinutes,
    this.location,
    this.isHabit = false,
    this.habitGoal,
    this.isStreakCount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. TITLE INPUT
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 100),
          child: TextField(
            controller: titleController,
            autofocus: true, // Auto-focus usually desired for new tasks
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: colors.textMain,
            ),
            maxLines: null,
            decoration: InputDecoration(
              hintText: "What to do?",
              hintStyle:
                  TextStyle(color: colors.textSecondary.withOpacity(0.5)),
              border: InputBorder.none,
              isDense: true,
            ),
            textInputAction: TextInputAction.next,
            onSubmitted: onTitleSubmitted,
          ),
        ),

        // 2. META CHIPS
        _buildMetaChips(),

        const SizedBox(height: 16),

        // 3. RICH TEXT EDITOR
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 100),
          child: quill.QuillEditor.basic(
            controller: quillController,
            config: const quill.QuillEditorConfig(
              padding: EdgeInsets.zero,
              placeholder: "Add details...",
              autoFocus: false,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetaChips() {
    List<Widget> chips = [];

    // 1. Reminder
    if (reminderTime != null) {
      String label = DateFormat('h:mm a').format(reminderTime!);
      chips.add(_buildChip(Icons.notifications, label));
    } else if (startTime != null) {
      String label = DateFormat('MMM d').format(startTime!);
      chips.add(_buildChip(Icons.calendar_today, label));
    }

    // 2. Active Period
    if (activePeriodStart != null && activePeriodEnd != null) {
      String start = DateFormat('h:mm').format(activePeriodStart!);
      String end = DateFormat('h:mm a').format(activePeriodEnd!);
      chips.add(_buildChip(Icons.access_time, "$start - $end"));
    }

    // 3. Duration
    if (durationMinutes != null) {
      chips.add(
          _buildChip(Icons.center_focus_strong, "${durationMinutes}m Focus"));
    }

    // 4. Location
    if (location != null && location!.isNotEmpty) {
      chips.add(_buildChip(Icons.place, location!));
    }

    // 5. Habit
    if (isHabit) {
      String habitLabel = "Habit: ${habitGoal ?? 30} days";
      if (isStreakCount) habitLabel += " (Streak)";
      chips.add(_buildChip(Icons.repeat, habitLabel));
    }

    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Wrap(spacing: 8, children: chips),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.bgTop,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: colors.textSecondary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colors.highlight),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
