import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';

class TimeConfigurationDialog extends StatefulWidget {
  final AppColors colors;
  final DateTime? initialReminder;
  final DateTime? initialPeriodStart;
  final DateTime? initialPeriodEnd;
  final int? initialDuration;

  const TimeConfigurationDialog({
    super.key,
    required this.colors,
    this.initialReminder,
    this.initialPeriodStart,
    this.initialPeriodEnd,
    this.initialDuration,
  });

  @override
  State<TimeConfigurationDialog> createState() =>
      _TimeConfigurationDialogState();
}

class _TimeConfigurationDialogState extends State<TimeConfigurationDialog> {
  // Toggles
  bool _hasReminder = false;
  bool _hasPeriod = false;
  bool _hasDuration = false;

  // Values
  late TimeOfDay _reminderTime;
  late TimeOfDay _periodStart;
  late TimeOfDay _periodEnd;
  int _durationMinutes = 25; // Default Pomodoro

  @override
  void initState() {
    super.initState();
    final now = TimeOfDay.now();

    _hasReminder = widget.initialReminder != null;
    _reminderTime = widget.initialReminder != null
        ? TimeOfDay.fromDateTime(widget.initialReminder!)
        : now;

    _hasPeriod = widget.initialPeriodStart != null;
    _periodStart = widget.initialPeriodStart != null
        ? TimeOfDay.fromDateTime(widget.initialPeriodStart!)
        : now;
    _periodEnd = widget.initialPeriodEnd != null
        ? TimeOfDay.fromDateTime(widget.initialPeriodEnd!)
        : TimeOfDay(hour: now.hour + 1, minute: now.minute);

    _hasDuration = widget.initialDuration != null;
    _durationMinutes = widget.initialDuration ?? 25;
  }

  Future<void> _pickTime(
      BuildContext context, Function(TimeOfDay) onPicked) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: widget.colors.highlight,
              onPrimary: widget.colors.bgMain,
              surface: widget.colors.bgMiddle,
              onSurface: widget.colors.textMain,
            ),
          ),
          child: child!,
        );
      },
    );
    if (t != null) {
      setState(() => onPicked(t));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: widget.colors.bgMiddle,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Time Options",
              style: TextStyle(
                color: widget.colors.textMain,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // 1. REMINDER
            _buildToggleSection(
              label: "Set Reminder",
              isActive: _hasReminder,
              onToggle: (v) => setState(() => _hasReminder = v),
              child: _buildTimeChip(_reminderTime,
                  () => _pickTime(context, (t) => _reminderTime = t)),
            ),

            Divider(color: widget.colors.textSecondary.withOpacity(0.1)),

            // 2. PERIOD (Active Time)
            _buildToggleSection(
              label: "Set Active Period",
              isActive: _hasPeriod,
              onToggle: (v) => setState(() => _hasPeriod = v),
              child: Row(
                children: [
                  _buildTimeChip(_periodStart,
                      () => _pickTime(context, (t) => _periodStart = t)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text("to",
                        style: TextStyle(color: widget.colors.textSecondary)),
                  ),
                  _buildTimeChip(_periodEnd,
                      () => _pickTime(context, (t) => _periodEnd = t)),
                ],
              ),
            ),

            Divider(color: widget.colors.textSecondary.withOpacity(0.1)),

            // 3. DURATION (Focus Mode)
            _buildToggleSection(
              label: "Set Duration (Focus)",
              isActive: _hasDuration,
              onToggle: (v) => setState(() => _hasDuration = v),
              child: _buildDurationSelector(),
            ),

            const SizedBox(height: 25),

            // ACTIONS
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel",
                      style: TextStyle(color: widget.colors.textSecondary)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.colors.highlight,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saveAndClose,
                  child: Text(
                    "Save",
                    style: TextStyle(
                        color: widget.colors.textHighlighted,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleSection({
    required String label,
    required bool isActive,
    required Function(bool) onToggle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(color: widget.colors.textMain, fontSize: 16)),
            Switch(
              value: isActive,
              activeThumbColor: widget.colors.highlight,
              onChanged: onToggle,
            ),
          ],
        ),
        if (isActive) ...[
          const SizedBox(height: 8),
          child,
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildTimeChip(TimeOfDay time, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: widget.colors.bgMain,
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: widget.colors.textSecondary.withOpacity(0.3)),
        ),
        child: Text(
          time.format(context),
          style: TextStyle(
              color: widget.colors.textMain, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDurationSelector() {
    final options = [15, 25, 30, 45, 60, 90];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((min) {
          final isSelected = _durationMinutes == min;
          return GestureDetector(
            onTap: () => setState(() => _durationMinutes = min),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:
                    isSelected ? widget.colors.highlight : widget.colors.bgMain,
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? null
                    : Border.all(
                        color: widget.colors.textSecondary.withOpacity(0.3)),
              ),
              child: Text(
                "${min}m",
                style: TextStyle(
                  color: isSelected
                      ? widget.colors.textHighlighted
                      : widget.colors.textMain,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _saveAndClose() {
    final now = DateTime.now();

    // Construct Return Data
    final data = {
      'reminder': _hasReminder
          ? DateTime(now.year, now.month, now.day, _reminderTime.hour,
              _reminderTime.minute)
          : null,
      'periodStart': _hasPeriod
          ? DateTime(now.year, now.month, now.day, _periodStart.hour,
              _periodStart.minute)
          : null,
      'periodEnd': _hasPeriod
          ? DateTime(
              now.year, now.month, now.day, _periodEnd.hour, _periodEnd.minute)
          : null,
      'duration': _hasDuration ? _durationMinutes : null,
    };

    Navigator.pop(context, data);
  }
}
