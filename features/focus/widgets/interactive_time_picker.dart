import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';

class InteractiveTimePicker extends StatefulWidget {
  final int totalSeconds;
  final Function(int) onDurationChanged;
  final AppColors colors;
  final bool isEnabled;
  final int stepMinutes; // 1 for Timer, 5 for Pomodoro

  const InteractiveTimePicker({
    super.key,
    required this.totalSeconds,
    required this.onDurationChanged,
    required this.colors,
    this.isEnabled = true,
    this.stepMinutes = 1,
  });

  @override
  State<InteractiveTimePicker> createState() => _InteractiveTimePickerState();
}

class _InteractiveTimePickerState extends State<InteractiveTimePicker> {
  // Drag State
  double _dragAccumulator = 0.0;
  static const double _pixelsPerStep = 20.0; // Sensitivity

  // Limits
  static const int _minSeconds = 30; // Global min
  static const int _maxSeconds = 360 * 60; // 6 hours

  @override
  Widget build(BuildContext context) {
    final minutes = widget.totalSeconds ~/ 60;
    final seconds = widget.totalSeconds % 60;

    final minStr = minutes.toString().padLeft(2, '0');
    final secStr = seconds.toString().padLeft(2, '0');

    final textStyle = TextStyle(
      fontSize: 80,
      fontWeight: FontWeight.w200,
      color: widget.isEnabled
          ? widget.colors.textMain
          : widget.colors.textSecondary.withOpacity(0.3),
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The Time Display (Split for interaction)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // MINUTES (Drag/Tap)
            GestureDetector(
              onVerticalDragUpdate: widget.isEnabled ? _handleDrag : null,
              onTap: widget.isEnabled ? _showManualEntryDialog : null,
              child: Container(
                color: Colors.transparent,
                child: Text(minStr, style: textStyle),
              ),
            ),

            // SEPARATOR
            Text(":", style: textStyle.copyWith(fontSize: 70, height: 0.8)),

            // SECONDS (Tap to toggle 30s)
            GestureDetector(
              onTap: widget.isEnabled ? _toggleSeconds : null,
              child: Container(
                color: Colors.transparent,
                child: Text(secStr, style: textStyle),
              ),
            ),
          ],
        ),

        // Hint Text
        if (widget.isEnabled)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              "Drag mins • Tap :${secStr} for 30s",
              style: TextStyle(
                fontSize: 12,
                color: widget.colors.textSecondary.withOpacity(0.5),
              ),
            ),
          ),
      ],
    );
  }

  // --- LOGIC ---

  void _handleDrag(DragUpdateDetails details) {
    // Invert delta: Drag Up (-dy) = Increase Time
    _dragAccumulator -= details.delta.dy;

    if (_dragAccumulator.abs() >= _pixelsPerStep) {
      int steps = (_dragAccumulator / _pixelsPerStep).truncate();

      if (steps != 0) {
        // Step size depends on mode (1 min or 5 mins)
        int stepSeconds = widget.stepMinutes * 60;
        int newSeconds = widget.totalSeconds + (steps * stepSeconds);

        // Clamp
        newSeconds = newSeconds.clamp(_minSeconds, _maxSeconds);

        if (newSeconds != widget.totalSeconds) {
          HapticFeedback.selectionClick();
          widget.onDurationChanged(newSeconds);
        }

        _dragAccumulator -= (steps * _pixelsPerStep);
      }
    }
  }

  void _toggleSeconds() {
    int currentSeconds = widget.totalSeconds % 60;
    int baseMinutes = widget.totalSeconds - currentSeconds;
    int newTotal;

    // Toggle logic: If < 30, go to 30. If >= 30, go to 00.
    if (currentSeconds < 30) {
      newTotal = baseMinutes + 30;
    } else {
      newTotal = baseMinutes; // Reset to 00
    }

    // Safety clamp
    newTotal = newTotal.clamp(_minSeconds, _maxSeconds);

    HapticFeedback.mediumImpact();
    widget.onDurationChanged(newTotal);
  }

  // --- MANUAL ENTRY DIALOG ---

  void _showManualEntryDialog() {
    String value = (widget.totalSeconds ~/ 60).toString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.colors.bgMiddle,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Set Duration (Minutes)",
          style: TextStyle(color: widget.colors.textMain),
        ),
        content: TextField(
          autofocus: true,
          keyboardType: TextInputType.number,
          style: TextStyle(
            color: widget.colors.textMain,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          controller: TextEditingController(text: value),
          onChanged: (v) => value = v,
          decoration: InputDecoration(
            hintText: "25",
            hintStyle: TextStyle(color: widget.colors.textSecondary),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: widget.colors.highlight),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: widget.colors.textMain, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel",
                style: TextStyle(color: widget.colors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              int? mins = int.tryParse(value);
              if (mins != null) {
                // Respect stepMinutes if possible, but manual entry usually overrides
                int total = mins * 60;
                total = total.clamp(_minSeconds, _maxSeconds);
                widget.onDurationChanged(total);
              }
              Navigator.pop(ctx);
            },
            child: Text(
              "Set",
              style: TextStyle(
                color: widget.colors.highlight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
