import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import '../models/habit_model.dart';

class HabitBasicDetails extends StatelessWidget {
  final AppColors colors;
  final TextEditingController titleController;
  final TextEditingController descController;

  // Basic State
  final HabitType selectedType;
  final HabitImportance importance;
  final int streakGoal;

  // Schedule State
  final List<int> scheduledWeekdays; // For Weekly
  final List<int> monthlyDays; // NEW: For Monthly (List of day numbers)
  final List<DateTime> targetDates; // For Yearly (Specific dates)

  // Time State
  final HabitDurationMode durationMode;
  final TimeOfDay? reminderTime;
  final TimeOfDay? activePeriodStart;
  final TimeOfDay? activePeriodEnd;
  final int? durationMinutes;

  // Callbacks
  final Function(HabitType) onTypeChanged;
  final Function(HabitImportance) onImportanceChanged;
  final Function(int) onStreakChanged;

  // Schedule Callbacks
  final Function(int day) onWeekdayToggle;
  final Function(int dayOfMonth) onMonthlyDayToggle;
  final Function(DateTime date) onYearlyDateAdd;
  final Function(DateTime date) onYearlyDateRemove;

  // Time Callbacks
  final Function(HabitDurationMode) onDurationModeChanged;
  final Function(TimeOfDay?) onReminderChanged;
  final Function(TimeOfDay) onActiveStartChanged;
  final Function(TimeOfDay) onActiveEndChanged;
  final Function(int) onDurationMinutesChanged;

  const HabitBasicDetails({
    super.key,
    required this.colors,
    required this.titleController,
    required this.descController,
    required this.selectedType,
    required this.importance,
    required this.streakGoal,
    required this.scheduledWeekdays,
    required this.monthlyDays, // NEW
    required this.targetDates,
    required this.durationMode,
    this.reminderTime,
    this.activePeriodStart,
    this.activePeriodEnd,
    this.durationMinutes,
    required this.onTypeChanged,
    required this.onImportanceChanged,
    required this.onStreakChanged,
    required this.onWeekdayToggle,
    required this.onMonthlyDayToggle,
    required this.onYearlyDateAdd,
    required this.onYearlyDateRemove,
    required this.onDurationModeChanged,
    required this.onReminderChanged,
    required this.onActiveStartChanged,
    required this.onActiveEndChanged,
    required this.onDurationMinutesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. HEADER (Name & Importance)
        Row(
          children: [
            Expanded(child: _buildLabel("Name")),
            _buildImportanceSelector(),
          ],
        ),
        _buildTextField(
          controller: titleController,
          hint: "e.g. Read Book",
        ),
        const SizedBox(height: 15),

        // 2. DESCRIPTION
        _buildLabel("Description (Optional)"),
        _buildTextField(
          controller: descController,
          hint: "e.g. 30 mins",
        ),
        const SizedBox(height: 20),

        // 3. FREQUENCY (Type)
        _buildTypeSelector(),
        const SizedBox(height: 25),

        // 4. SCHEDULE PICKER (Dynamic based on Type)
        _buildLabel(
          selectedType == HabitType.weekly
              ? "Schedule Days"
              : selectedType == HabitType.monthly
                  ? "Select Days of Month"
                  : "Select Specific Dates",
        ),
        const SizedBox(height: 10),
        if (selectedType == HabitType.weekly)
          _buildWeeklySelector()
        else if (selectedType == HabitType.monthly)
          _buildMonthlySelector()
        else
          _buildYearlySelector(context),

        const SizedBox(height: 25),

        // 5. STREAK GOAL
        _buildStreakCounter(),
        const SizedBox(height: 30),

        Divider(color: colors.textSecondary.withOpacity(0.1)),
        const SizedBox(height: 20),

        // 6. TIME OPTIONS
        _buildLabel("Time Options"),
        const SizedBox(height: 10),
        _buildTimeModeSelector(),
        const SizedBox(height: 20),

        // Dynamic Time Inputs based on Mode
        if (durationMode == HabitDurationMode.fixedWindow)
          _buildFixedWindowInputs(context),
        if (durationMode == HabitDurationMode.focusTimer)
          _buildFocusDurationInput(),

        // 7. REMINDER (Always available)
        const SizedBox(height: 10),
        _buildReminderRow(context),
      ],
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        text,
        style: TextStyle(
          color: colors.textMain,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
      decoration: BoxDecoration(
        color: colors.bgMiddle,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: colors.textMain),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: colors.textSecondary.withOpacity(0.5)),
        ),
      ),
    );
  }

  // --- IMPORTANCE ---
  Widget _buildImportanceSelector() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: HabitImportance.values.map((imp) {
        final isSelected = importance == imp;
        Color color;
        IconData icon;

        switch (imp) {
          case HabitImportance.high:
            color = colors.priorityHigh;
            icon = Icons.flag;
            break;
          case HabitImportance.medium:
            color = colors.priorityMedium;
            icon = Icons.flag;
            break;
          case HabitImportance.low:
            color = colors.priorityLow;
            icon = Icons.flag;
            break;
          case HabitImportance.none:
            color = colors.textSecondary.withOpacity(0.5);
            icon = Icons.outlined_flag;
            break;
        }

        return GestureDetector(
          onTap: () => onImportanceChanged(imp),
          child: Container(
            margin: const EdgeInsets.only(left: 8, bottom: 8),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: color) : null,
            ),
            child: Icon(icon,
                size: 20, color: isSelected ? color : color.withOpacity(0.5)),
          ),
        );
      }).toList(),
    );
  }

  // --- TYPE SELECTOR ---
  Widget _buildTypeSelector() {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          _buildTypeOption(HabitType.weekly, "Weekly"),
          const SizedBox(width: 10),
          _buildTypeOption(HabitType.monthly, "Monthly"),
          const SizedBox(width: 10),
          _buildTypeOption(HabitType.yearly, "Yearly"),
        ],
      ),
    );
  }

  Widget _buildTypeOption(HabitType type, String label) {
    final isSelected = selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTypeChanged(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colors.highlight : colors.bgMiddle,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? colors.highlight : colors.bgMiddle,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? colors.textHighlighted : colors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // --- SCHEDULE SELECTORS ---

  // 1. Weekly (M T W...)
  Widget _buildWeeklySelector() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          final int dayNum = index + 1;
          final bool isSelected = scheduledWeekdays.contains(dayNum);
          return GestureDetector(
            onTap: () => onWeekdayToggle(dayNum),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? colors.highlight : colors.bgMiddle,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? colors.highlight : colors.bgBottom,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                ["M", "T", "W", "T", "F", "S", "S"][index],
                style: TextStyle(
                  color: isSelected
                      ? colors.textHighlighted
                      : colors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }),
      );

  // 2. Monthly (Grid 1-31)
  Widget _buildMonthlySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(31, (index) {
        final int day = index + 1;
        // FIX: Check against monthlyDays (int list), NOT targetDates
        final bool isSelected = monthlyDays.contains(day);

        return GestureDetector(
          onTap: () => onMonthlyDayToggle(day),
          child: Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              // FIX: Highlight color when selected
              color: isSelected ? colors.highlight : colors.bgMiddle,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              "$day",
              style: TextStyle(
                // FIX: Highlight text color when selected
                color:
                    isSelected ? colors.textHighlighted : colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }),
    );
  }

  // 3. Yearly (Chips + Add Button)
  Widget _buildYearlySelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...targetDates.map((date) => Chip(
                  label: Text(
                    DateFormat('MMM dd').format(date),
                    style: TextStyle(color: colors.textHighlighted),
                  ),
                  backgroundColor: colors.highlight,
                  deleteIcon: Icon(Icons.close,
                      size: 16, color: colors.textHighlighted),
                  onDeleted: () => onYearlyDateRemove(date),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                )),
            ActionChip(
              label: Text("Add Date", style: TextStyle(color: colors.textMain)),
              backgroundColor: colors.bgMiddle,
              avatar: Icon(Icons.add, size: 16, color: colors.textMain),
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2030),
                  builder: (context, child) => Theme(
                    data: ThemeData.light().copyWith(
                      colorScheme: ColorScheme.light(
                        primary: colors.highlight,
                        onPrimary: colors.textHighlighted,
                        surface: colors.bgMiddle,
                        onSurface: colors.textMain,
                      ),
                      dialogBackgroundColor: colors.bgMain,
                    ),
                    child: child!,
                  ),
                );
                if (d != null) onYearlyDateAdd(d);
              },
            ),
          ],
        ),
      ],
    );
  }

  // --- STREAK GOAL ---
  Widget _buildStreakCounter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildLabel("Streak Goal"),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colors.bgMiddle,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => onStreakChanged(streakGoal - 1),
                child: Icon(Icons.remove, size: 18, color: colors.textMain),
              ),
              const SizedBox(width: 15),
              Text(
                "$streakGoal",
                style: TextStyle(
                  color: colors.textMain,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 15),
              GestureDetector(
                onTap: () => onStreakChanged(streakGoal + 1),
                child: Icon(Icons.add, size: 18, color: colors.textMain),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- TIME OPTIONS ---

  Widget _buildTimeModeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: colors.bgMiddle,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildTimeModeOption(HabitDurationMode.anyTime, "Any Time"),
          _buildTimeModeOption(HabitDurationMode.fixedWindow, "Scheduled"),
          _buildTimeModeOption(HabitDurationMode.focusTimer, "Focus"),
        ],
      ),
    );
  }

  Widget _buildTimeModeOption(HabitDurationMode mode, String label) {
    final isSelected = durationMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => onDurationModeChanged(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? colors.highlight : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? colors.textHighlighted : colors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFixedWindowInputs(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildTimeInputTile(
            context,
            "Start Time",
            activePeriodStart,
            (t) => onActiveStartChanged(t),
          ),
        ),
        const SizedBox(width: 12),
        const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTimeInputTile(
            context,
            "End Time",
            activePeriodEnd,
            (t) => onActiveEndChanged(t),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeInputTile(BuildContext context, String label,
      TimeOfDay? value, Function(TimeOfDay) onChanged) {
    return GestureDetector(
      onTap: () async {
        final t = await showTimePicker(
          context: context,
          initialTime: value ?? TimeOfDay.now(),
          builder: (context, child) => _pickerTheme(child, colors),
        );
        if (t != null) onChanged(t);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: colors.bgMiddle,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.textSecondary.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(color: colors.textSecondary, fontSize: 10)),
            const SizedBox(height: 2),
            Text(
              value?.format(context) ?? "--:--",
              style: TextStyle(
                  color: colors.textMain, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusDurationInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Duration",
                style: TextStyle(color: colors.textSecondary, fontSize: 12)),
            Text("${durationMinutes ?? 30} min",
                style: TextStyle(
                    color: colors.textMain, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: (durationMinutes ?? 30).toDouble(),
          min: 5,
          max: 180,
          divisions: 35, // 5 min increments
          activeColor: colors.highlight,
          inactiveColor: colors.bgMiddle,
          onChanged: (val) => onDurationMinutesChanged(val.toInt()),
        ),
      ],
    );
  }

  Widget _buildReminderRow(BuildContext context) {
    final bool hasReminder = reminderTime != null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgMiddle,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_none,
              color: hasReminder ? colors.highlight : colors.textSecondary),
          const SizedBox(width: 12),
          Text(
            "Reminder",
            style:
                TextStyle(color: colors.textMain, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          if (hasReminder)
            GestureDetector(
              onTap: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: reminderTime!,
                  builder: (context, child) => _pickerTheme(child, colors),
                );
                if (t != null) onReminderChanged(t);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.bgTop,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  reminderTime!.format(context),
                  style: TextStyle(
                      color: colors.textMain,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
            ),
          const SizedBox(width: 12),
          Switch(
            value: hasReminder,
            activeColor: colors.highlight,
            onChanged: (val) {
              if (val) {
                onReminderChanged(const TimeOfDay(hour: 9, minute: 0));
              } else {
                onReminderChanged(null);
              }
            },
          ),
        ],
      ),
    );
  }

  Theme _pickerTheme(Widget? child, AppColors colors) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(
            primary: colors.highlight,
            onPrimary: colors.textHighlighted,
            surface: colors.bgMiddle,
            onSurface: colors.textMain,
          ),
          dialogBackgroundColor: colors.bgMiddle,
        ),
        child: child!,
      );
}
