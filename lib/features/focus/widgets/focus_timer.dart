import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Haptics
import 'package:intl/intl.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import 'package:task_manager_app/features/tasks/models/task_model.dart';
import '../../../data/repositories/task_repository.dart';

class FocusTimer extends StatefulWidget {
  final AppColors colors;
  final bool isCountdownMode;
  final TaskModel? task; // Optional initial task

  const FocusTimer({
    super.key,
    required this.colors,
    required this.isCountdownMode,
    this.task,
  });

  @override
  State<FocusTimer> createState() => _FocusTimerState();
}

class _FocusTimerState extends State<FocusTimer> {
  final TaskRepository _repo = TaskRepository();

  // Internal State for Task (allows attaching dynamically)
  TaskModel? _attachedTask;

  Timer? _timer;
  bool _isRunning = false;

  late int _currentSeconds;
  late int _totalSeconds;
  final int _maxCapSeconds = 180 * 60; // 3 hours cap

  @override
  void initState() {
    super.initState();
    _attachedTask = widget.task; // Initialize with passed task if any
    _resetLogic();
  }

  @override
  void didUpdateWidget(FocusTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If parent passes a NEW task, update it
    if (widget.task != oldWidget.task) {
      setState(() {
        _attachedTask = widget.task;
        _stopTimer();
        _resetLogic();
      });
    }
    // Handle mode switch only if no task is attached
    if (_attachedTask == null &&
        oldWidget.isCountdownMode != widget.isCountdownMode) {
      _stopTimer();
      _resetLogic();
    }
  }

  void _resetLogic() {
    setState(() {
      int initialDuration = 25 * 60; // Default

      // PRIORITY 1: Attached Task Constraints
      if (_attachedTask != null) {
        if (_attachedTask!.activePeriodStart != null &&
            _attachedTask!.activePeriodEnd != null) {
          Duration diff = _attachedTask!.activePeriodEnd!
              .difference(_attachedTask!.activePeriodStart!);
          initialDuration = diff.inSeconds;
        } else if (_attachedTask!.durationMinutes != null &&
            _attachedTask!.durationMinutes! > 0) {
          initialDuration = _attachedTask!.durationMinutes! * 60;
        }
      }
      // PRIORITY 2: Manual Mode
      else if (!widget.isCountdownMode) {
        initialDuration = 0; // Stopwatch
      }

      _currentSeconds = initialDuration;
      _totalSeconds = _currentSeconds == 0 ? 60 : _currentSeconds;
      _isRunning = false;
    });
  }

  String get _timerString {
    int minutes = _currentSeconds ~/ 60;
    int seconds = _currentSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- TIMER LOGIC ---

  void _toggleTimer() {
    if (_isRunning) {
      _stopTimer();
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          // Task always uses countdown logic
          if (widget.isCountdownMode || _attachedTask != null) {
            if (_currentSeconds > 0) {
              _currentSeconds--;
            } else {
              _finishTimer();
            }
          } else {
            // Stopwatch Logic
            _currentSeconds++;
            if (_currentSeconds > _totalSeconds) {
              _totalSeconds = _currentSeconds;
            }
          }
        });
      });
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _finishTimer() {
    _stopTimer();
    HapticFeedback.vibrate();

    // LOGIC: Only show dialog if a task is linked
    if (_attachedTask != null) {
      _showTaskCompletionDialog();
    } else {
      // Normal Reset (No pop-up as requested)
      setState(() {
        if (widget.isCountdownMode) _currentSeconds = _totalSeconds;
      });
    }
  }

  void _resetTimer() {
    _stopTimer();
    _resetLogic();
  }

  void _adjustTime(double delta) {
    if (_isRunning) return;
    const int interval = 60;
    setState(() {
      if (delta < 0) {
        if (_currentSeconds + interval <= _maxCapSeconds) {
          _currentSeconds += interval;
        }
      } else {
        if (_currentSeconds - interval >= 0) _currentSeconds -= interval;
      }
      _totalSeconds = _currentSeconds;
    });
  }

  // --- TASK ATTACHMENT LOGIC ---

  void _showAttachTaskDialog() {
    final candidates = _repo
        .getAll()
        .where((t) =>
            !t.isDone &&
            !t.isArchived &&
            (t.requiresFocusMode || t.activePeriodStart != null))
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: widget.colors.bgMiddle,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Attach Task",
                style: TextStyle(
                    color: widget.colors.textMain,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            if (candidates.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text("No tasks with duration or period found.",
                    style: TextStyle(color: widget.colors.textSecondary)),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: candidates.length,
                  itemBuilder: (context, index) {
                    final t = candidates[index];
                    String meta = "";
                    if (t.activePeriodStart != null) {
                      meta =
                          "${DateFormat.jm().format(t.activePeriodStart!)} - ${DateFormat.jm().format(t.activePeriodEnd!)}";
                    } else if (t.durationMinutes != null) {
                      meta = "${t.durationMinutes}m Duration";
                    }

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(t.title,
                          style: TextStyle(
                              color: widget.colors.textMain,
                              fontWeight: FontWeight.bold)),
                      subtitle: Text(meta,
                          style: TextStyle(
                              color: widget.colors.highlight, fontSize: 12)),
                      trailing: Icon(Icons.add_circle_outline,
                          color: widget.colors.textSecondary),
                      onTap: () {
                        setState(() {
                          _attachedTask = t;
                          _stopTimer();
                          _resetLogic();
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _detachTask() {
    setState(() {
      _attachedTask = null;
      _stopTimer();
      _resetLogic();
    });
  }

  void _markAttachedTaskDone() async {
    if (_attachedTask == null) return;
    await _repo.toggleTask(_attachedTask!);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("'${_attachedTask!.title}' completed!"),
      backgroundColor: widget.colors.bgMiddle,
    ));

    if (widget.task != null) {
      Navigator.pop(context);
    } else {
      _detachTask();
    }
  }

  // --- COMPLETION DIALOG ---
  void _showTaskCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.colors.bgMiddle,
        title: Text("Session Finished!",
            style: TextStyle(color: widget.colors.textMain)),
        content: Text(
          "Is '${_attachedTask!.title}' done?",
          style: TextStyle(color: widget.colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _currentSeconds = 5 * 60;
                _totalSeconds = _currentSeconds;
                _toggleTimer();
              });
            },
            child: Text("Nearly (+5m)",
                style: TextStyle(color: widget.colors.textMain)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (widget.task != null) Navigator.pop(context);
            },
            child: const Text("No", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: widget.colors.highlight),
            onPressed: () async {
              await _repo.toggleTask(_attachedTask!);
              if (!mounted) return;
              Navigator.pop(ctx);
              if (widget.task != null) {
                Navigator.pop(context);
              } else {
                _detachTask();
              }
            },
            child: Text("Yes",
                style: TextStyle(color: widget.colors.textHighlighted)),
          ),
        ],
      ),
    );
  }

  // --- UI BUILDER ---

  @override
  Widget build(BuildContext context) {
    double progress = (_totalSeconds == 0)
        ? 0
        : (_currentSeconds / _totalSeconds).clamp(0.0, 1.0);

    return Column(
      children: [
        // TASK TITLE INDICATOR
        if (_attachedTask != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: GestureDetector(
              onTap: _markAttachedTaskDone,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.colors.bgMiddle,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: widget.colors.highlight.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 18, color: widget.colors.highlight),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _attachedTask!.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: widget.colors.textMain,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _detachTask,
                      child: Icon(Icons.close,
                          size: 16, color: widget.colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // TIMER CIRCLE
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 280,
              height: 280,
              child: CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 15,
                valueColor: AlwaysStoppedAnimation<Color>(widget.colors.undone),
              ),
            ),
            SizedBox(
              width: 280,
              height: 280,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 15,
                strokeCap: StrokeCap.round,
                valueColor: AlwaysStoppedAnimation<Color>(widget.colors.done),
              ),
            ),
            GestureDetector(
              onVerticalDragUpdate: (details) => _adjustTime(details.delta.dy),
              onTap: () {},
              child: Container(
                width: 240,
                height: 240,
                color: Colors.transparent,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _timerString,
                      style: TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: widget.colors.textMain,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _isRunning ? "FOCUSING" : "TAP PLAY",
                      style: TextStyle(
                        fontSize: 14,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                        color: widget.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 50),

        // CONTROLS
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              iconSize: 32,
              icon: Icon(Icons.refresh, color: widget.colors.textSecondary),
              onPressed: _resetTimer,
            ),
            const SizedBox(width: 20),

            GestureDetector(
              onTap: _toggleTimer,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _isRunning
                      ? widget.colors.bgMiddle
                      : widget.colors.highlight,
                  shape: BoxShape.circle,
                  border: _isRunning
                      ? Border.all(color: widget.colors.highlight, width: 2)
                      : null,
                ),
                child: Icon(
                  _isRunning ? Icons.pause : Icons.play_arrow_rounded,
                  size: 45,
                  color: _isRunning
                      ? widget.colors.textMain
                      : widget.colors.textHighlighted,
                ),
              ),
            ),

            const SizedBox(width: 20),

            // NEW: FINISH BUTTON
            IconButton(
              iconSize: 32,
              icon: Icon(Icons.check_circle_outline,
                  color: widget.colors.textMain),
              onPressed: _finishTimer,
              tooltip: "Finish Early",
            ),

            const SizedBox(width: 20),

            // ATTACH BUTTON
            IconButton(
              iconSize: 32,
              icon: Icon(Icons.link,
                  color: _attachedTask != null
                      ? widget.colors.highlight
                      : widget.colors.textSecondary),
              onPressed: widget.task != null
                  ? null // Locked if passed from Task Page
                  : _showAttachTaskDialog,
            ),
          ],
        ),
      ],
    );
  }
}
