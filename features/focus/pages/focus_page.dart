import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import 'package:task_manager_app/core/theme/theme_controller.dart';

// --- MODELS ---
import 'package:task_manager_app/features/tasks/models/task_model.dart';
import 'package:task_manager_app/features/habits/models/habit_model.dart';
import '../models/focus_task_model.dart';

// --- REPOSITORIES ---
import '../../../data/repositories/task_repository.dart';
import '../../../data/repositories/focus_repository.dart';
import '../../../data/repositories/habit_repository.dart';

// --- WIDGETS ---
import '../widgets/interactive_time_picker.dart';
import '../widgets/focus_task_tile.dart';

// --- NEW FEATURES ---
import 'package:task_manager_app/core/services/notification_service.dart';
import 'focus_archive_page.dart';
import 'focus_task_creation_sheet.dart';

final ValueNotifier<bool> isFocusModeRunning = ValueNotifier(false);

class FocusPage extends StatefulWidget {
  final TaskModel? initialTask;
  final HabitModel? initialHabit;

  const FocusPage({super.key, this.initialTask, this.initialHabit});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

enum FocusMode { timer, pomodoro }

class _FocusPageState extends State<FocusPage> with TickerProviderStateMixin {
  final TaskRepository _taskRepo = TaskRepository();
  final FocusRepository _focusRepo = FocusRepository();
  final HabitRepository _habitRepo = HabitRepository();

  // --- STATE ---
  FocusMode _mode = FocusMode.pomodoro;
  bool _isRunning = false;
  bool _lockWithTask = false;
  int _currentSeconds = 1500;
  int _targetSeconds = 1500;
  Timer? _timer;

  FocusTaskModel? _activeFocusTask;
  TaskModel? _activeMainTask;
  HabitModel? _activeHabit;

  late AnimationController _playBtnController;
  late Animation<double> _playBtnAnimation;

  @override
  void initState() {
    super.initState();
    NotificationService().init();

    _playBtnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _playBtnAnimation = CurvedAnimation(
      parent: _playBtnController,
      curve: Curves.easeOutBack,
    );

    if (widget.initialTask != null) {
      _attachMainTask(widget.initialTask!);
    } else if (widget.initialHabit != null) {
      _attachHabit(widget.initialHabit!);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _playBtnController.dispose();
    isFocusModeRunning.value = false;
    super.dispose();
  }

  // --- LOGIC ---

  void _attachMainTask(TaskModel task) {
    setState(() {
      _activeMainTask = task;
      _activeHabit = null;
      _activeFocusTask = null;
      if (task.durationMinutes != null && task.durationMinutes! > 0) {
        _setDuration(task.durationMinutes! * 60, fromTask: true);
      }
    });
  }

  void _attachHabit(HabitModel habit) {
    setState(() {
      _activeHabit = habit;
      _activeMainTask = null;
      _activeFocusTask = null;
      if (habit.durationMinutes != null && habit.durationMinutes! > 0) {
        _setDuration(habit.durationMinutes! * 60, fromTask: true);
      }
    });
  }

  void _setDuration(int seconds, {bool fromTask = false}) {
    setState(() {
      _targetSeconds = seconds;
      _currentSeconds = seconds;
    });

    if (_lockWithTask && !fromTask) {
      if (_activeFocusTask != null) {
        _activeFocusTask!.targetDurationSeconds = seconds;
        _activeFocusTask!.save();
      }
      if (_activeMainTask != null) {
        _activeMainTask!.durationMinutes = seconds ~/ 60;
        _activeMainTask!.save();
      }
    }
  }

  void _switchMode(FocusMode mode) {
    if (_isRunning) return;
    setState(() {
      _mode = mode;
      int def = (mode == FocusMode.pomodoro) ? 25 : 45;
      _setDuration(def * 60);
    });
  }

  // --- TIMER ENGINE ---
  void _toggleTimer() {
    HapticFeedback.mediumImpact();
    setState(() => _isRunning = !_isRunning);
    isFocusModeRunning.value = _isRunning;
    if (_isRunning) {
      _playBtnController.forward();
      _startTicker();
    } else {
      _playBtnController.reverse();
      _timer?.cancel();
    }
  }

  void _startTicker() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_currentSeconds > 0) {
          _currentSeconds--;
          if (_activeFocusTask != null) {
            _activeFocusTask!.accumulatedSeconds += 1;
            if (_activeFocusTask!.accumulatedSeconds % 60 == 0) {
              _activeFocusTask!.save();
            }
          }
          if (_activeMainTask != null) {
            int current = _activeMainTask!.focusSeconds ?? 0;
            _activeMainTask!.focusSeconds = current + 1;
            if ((_activeMainTask!.focusSeconds ?? 0) % 60 == 0) {
              _activeMainTask!.save();
            }
          }
        } else {
          _completeSession();
        }
      });
    });
  }

  void _completeSession() {
    _timer?.cancel();
    _isRunning = false;
    isFocusModeRunning.value = false;
    _playBtnController.reverse();
    HapticFeedback.heavyImpact();

    String sessionName =
        _activeMainTask?.title ?? _activeHabit?.title ?? "Focus Session";

    NotificationService().showFocusComplete(
      id: 888,
      title: "Time is up!",
      body: "You completed your session for: $sessionName",
    );

    if (_activeMainTask != null || _activeHabit != null) {
      _showCompletionDialog();
    } else {
      setState(() => _currentSeconds = _targetSeconds);
    }
  }

  void _showCompletionDialog() {
    String title = _activeMainTask?.title ?? _activeHabit?.title ?? "Task";

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          final colors = Theme.of(context).extension<AppColors>()!;
          return AlertDialog(
            backgroundColor: colors.bgMiddle,
            title: Text("Session Complete!",
                style: TextStyle(color: colors.textMain)),
            content: Text("Finished '$title'?",
                style: TextStyle(color: colors.textSecondary)),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() => _currentSeconds = _targetSeconds);
                  },
                  child: Text("No",
                      style: TextStyle(color: colors.textSecondary))),
              TextButton(
                  onPressed: () async {
                    if (_activeMainTask != null) {
                      await _taskRepo.toggleTask(_activeMainTask!);
                      if (_activeMainTask!.isDone) {
                        NotificationService().showCompletion(
                          id: _activeMainTask!.id.hashCode,
                          title: "Task Completed",
                          body: _activeMainTask!.title,
                        );
                      }
                    } else if (_activeHabit != null) {
                      _activeHabit!.toggleCompletion(DateTime.now());
                    }

                    if (mounted) {
                      Navigator.pop(ctx);
                      setState(() {
                        _activeMainTask = null;
                        _activeHabit = null;
                        _currentSeconds = _targetSeconds;
                      });
                    }
                  },
                  child: Text("Yes",
                      style: TextStyle(
                          color: colors.highlight,
                          fontWeight: FontWeight.bold))),
            ],
          );
        });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      isFocusModeRunning.value = false;
      _currentSeconds = _targetSeconds;
    });
    _playBtnController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final int stepMinutes = _mode == FocusMode.pomodoro ? 5 : 1;

    String? attachedTitle;
    if (_activeFocusTask != null) attachedTitle = _activeFocusTask!.title;
    if (_activeMainTask != null) attachedTitle = _activeMainTask!.title;
    if (_activeHabit != null) attachedTitle = _activeHabit!.title;

    return Scaffold(
      backgroundColor: colors.bgMain,
      body: SafeArea(
        child: Column(
          children: [
            // 1. HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.initialTask != null || widget.initialHabit != null)
                    IconButton(
                        icon: Icon(Icons.arrow_back, color: colors.textMain),
                        onPressed: () => Navigator.pop(context))
                  else
                    Row(children: [
                      Icon(Icons.filter_center_focus,
                          color: colors.highlight, size: 20),
                      const SizedBox(width: 8),
                      Text("FOCUS",
                          style: TextStyle(
                              color: colors.textMain,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              fontSize: 16)),
                    ]),

                  // MENU ACTIONS
                  Row(
                    children: [
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: colors.bgMiddle, shape: BoxShape.circle),
                          child:
                              Icon(Icons.add, size: 20, color: colors.textMain),
                        ),
                        onPressed: () {
                          FocusTaskCreationSheet.show(context, colors);
                        },
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon:
                            Icon(Icons.more_vert, color: colors.textSecondary),
                        color: colors.bgMiddle,
                        onSelected: (val) {
                          if (val == 'theme')
                            ThemeController.instance.toggleMode();
                          if (val == 'lock')
                            setState(() => _lockWithTask = !_lockWithTask);
                          if (val == 'archive') {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const FocusArchivePage()));
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'theme',
                            child: Row(children: [
                              Icon(isDark ? Icons.light_mode : Icons.dark_mode,
                                  size: 20, color: colors.textMain),
                              const SizedBox(width: 10),
                              Text(isDark ? "Light Mode" : "Dark Mode",
                                  style: TextStyle(color: colors.textMain)),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'lock',
                            child: Row(children: [
                              Icon(_lockWithTask ? Icons.link : Icons.link_off,
                                  size: 20,
                                  color: _lockWithTask
                                      ? colors.highlight
                                      : colors.textSecondary),
                              const SizedBox(width: 10),
                              Text("Lock with Task",
                                  style: TextStyle(color: colors.textMain)),
                            ]),
                          ),
                          PopupMenuItem(
                            value: 'archive',
                            child: Row(children: [
                              Icon(Icons.inventory_2_outlined,
                                  size: 20, color: colors.textMain),
                              const SizedBox(width: 10),
                              Text("Archived Focus",
                                  style: TextStyle(color: colors.textMain)),
                            ]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. TOGGLE (Moved Left & Removed vertical spacing above)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: colors.bgMiddle,
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildToggleItem("Timer", FocusMode.timer, colors),
                      _buildToggleItem("Pomodoro", FocusMode.pomodoro, colors),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20), // Reduced spacing

            // 3. ATTACHED TASK LABEL
            if (attachedTitle != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.bgMiddle.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: colors.textSecondary.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.link, size: 16, color: colors.highlight),
                    const SizedBox(width: 8),
                    Flexible(
                        child: Text(attachedTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: colors.textMain,
                                fontWeight: FontWeight.w600))),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() {
                        _activeFocusTask = null;
                        _activeMainTask = null;
                        _activeHabit = null;
                      }),
                      child: Icon(Icons.close,
                          size: 16, color: colors.textSecondary),
                    ),
                  ],
                ),
              )
            else
              GestureDetector(
                onTap: () => _showAttachTaskDialog(colors),
                child: Text("Select a task to focus on",
                    style: TextStyle(
                        color: colors.textSecondary.withOpacity(0.5),
                        fontSize: 14,
                        decoration: TextDecoration.underline)),
              ),

            const SizedBox(height: 20), // Compact spacing (Was Spacer)

            // 4. MAIN TIMER (Moved Up)
            InteractiveTimePicker(
              totalSeconds: _currentSeconds,
              colors: colors,
              isEnabled: !_isRunning,
              stepMinutes: stepMinutes,
              onDurationChanged: (val) => _setDuration(val),
            ),

            const SizedBox(height: 20), // Compact spacing (Was Spacer)

            // 5. CONTROLS (Moved Up)
            SizedBox(
              height: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizeTransition(
                    sizeFactor: _playBtnAnimation,
                    axis: Axis.horizontal,
                    axisAlignment: 1.0,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: _buildCircleBtn(Icons.replay, colors.textSecondary,
                          colors.bgMiddle, _resetTimer),
                    ),
                  ),
                  GestureDetector(
                    onTap: _toggleTimer,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _isRunning ? colors.bgMiddle : colors.highlight,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: _isRunning
                                  ? Colors.transparent
                                  : colors.highlight.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10))
                        ],
                        border: _isRunning
                            ? Border.all(color: colors.highlight, width: 2)
                            : null,
                      ),
                      child: Icon(
                          _isRunning ? Icons.pause : Icons.play_arrow_rounded,
                          size: 40,
                          color: _isRunning
                              ? colors.textMain
                              : colors.textHighlighted),
                    ),
                  ),
                  SizeTransition(
                    sizeFactor: _playBtnAnimation,
                    axis: Axis.horizontal,
                    axisAlignment: -1.0,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: _buildCircleBtn(Icons.check, colors.bgMain,
                          colors.textMain, _completeSession),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20), // Reduced bottom gap

            // 6. FOCUS LIST (Expanded Area)
            Expanded(
              flex: 4, // Increased flex slightly
              child: _buildFocusList(colors, stepMinutes),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusList(AppColors colors, int stepMinutes) {
    return ValueListenableBuilder<Box<FocusTaskModel>>(
      valueListenable: _focusRepo.box.listenable(),
      builder: (context, box, _) {
        final tasks = _focusRepo.getActiveTasks();

        tasks.sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          return b.dateCreated.compareTo(a.dateCreated);
        });

        if (tasks.isEmpty) {
          return Center(
              child: Text("No active focus tasks",
                  style: TextStyle(
                      color: colors.textSecondary.withOpacity(0.3),
                      fontSize: 14)));
        }

        return ShaderMask(
          shaderCallback: (Rect rect) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black,
              Colors.black,
              Colors.transparent
            ],
            stops: [0.0, 0.1, 0.9, 1.0],
          ).createShader(rect),
          blendMode: BlendMode.dstIn,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return FocusTaskTile(
                key: ValueKey(task.id),
                task: task,
                colors: colors,
                stepMinutes: stepMinutes,
                onUpdate: () => setState(() {}),
                onCheck: () async {
                  task.isDone = !task.isDone;
                  task.save();

                  if (task.isDone) {
                    NotificationService().showCompletion(
                        id: task.id.hashCode,
                        title: "Completed",
                        body: task.title);
                  }
                },
                onPlay: (t) {
                  setState(() {
                    _activeFocusTask = t;
                    _activeMainTask = null;
                    _activeHabit = null;
                    _setDuration(t.targetDurationSeconds, fromTask: true);
                  });
                  _toggleTimer();
                },
                onDurationChanged: (newSeconds) {
                  // Lock Logic is triggered here
                  if (_lockWithTask && _activeFocusTask == task) {
                    setState(() {
                      _targetSeconds = newSeconds;
                      if (!_isRunning) _currentSeconds = newSeconds;
                    });
                  }
                },
                onPin: (t) => _focusRepo.togglePin(t),
                onArchive: (t) => _focusRepo.toggleArchive(t),
                onDelete: (t) => _focusRepo.deleteFocusTask(t.id),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildToggleItem(String label, FocusMode itemMode, AppColors colors) {
    final isSelected = _mode == itemMode;
    return GestureDetector(
      onTap: () => _switchMode(itemMode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.bgMain : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label,
            style: TextStyle(
                color: isSelected ? colors.textMain : colors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
      ),
    );
  }

  Widget _buildCircleBtn(
      IconData icon, Color iconColor, Color bgColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 28)),
    );
  }

  void _showAttachTaskDialog(AppColors colors) {
    final tasks = _taskRepo.getAll().where((t) {
      bool relevant = t.requiresFocusMode ||
          t.durationMinutes != null ||
          t.activePeriodStart != null;
      return !t.isDone && !t.isArchived && relevant;
    }).toList();

    final habits = _habitRepo.getAllActiveHabits().where((h) {
      return h.durationMode == HabitDurationMode.focusTimer;
    }).toList();

    final hasItems = tasks.isNotEmpty || habits.isNotEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.bgMiddle,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Attach to Focus",
                style: TextStyle(
                    color: colors.textMain,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            if (!hasItems)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text("No focus tasks or habits found.",
                      style: TextStyle(color: colors.textSecondary)))
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (tasks.isNotEmpty) ...[
                      Text("TASKS",
                          style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      ...tasks.map((t) => _buildAttachTile(
                            colors: colors,
                            title: t.title,
                            meta: t.durationMinutes != null
                                ? "${t.durationMinutes}m"
                                : "Scheduled",
                            onTap: () {
                              _attachMainTask(t);
                              Navigator.pop(ctx);
                            },
                          )),
                      const SizedBox(height: 15),
                    ],
                    if (habits.isNotEmpty) ...[
                      Text("HABITS",
                          style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      ...habits.map((h) => _buildAttachTile(
                            colors: colors,
                            title: h.title,
                            meta: "${h.durationMinutes ?? 30}m Focus",
                            onTap: () {
                              _attachHabit(h);
                              Navigator.pop(ctx);
                            },
                          )),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachTile({
    required AppColors colors,
    required String title,
    required String meta,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title,
          style:
              TextStyle(color: colors.textMain, fontWeight: FontWeight.bold)),
      subtitle:
          Text(meta, style: TextStyle(color: colors.highlight, fontSize: 12)),
      trailing: Icon(Icons.add_circle_outline, color: colors.textSecondary),
      onTap: onTap,
    );
  }
}
