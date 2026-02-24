import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import 'package:task_manager_app/data/repositories/settings_repository.dart';
import 'package:task_manager_app/core/services/notification_service.dart';
import '../models/notification_settings_model.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final SettingsRepository _repo = SettingsRepository();
  final NotificationService _notifications = NotificationService();

  late NotificationSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = _repo.getSettings();
  }

  void _update() {
    _settings.save();
    setState(() {});
  }

  // --- TEST SOUND ACTIONS ---
  void _testAlarm() {
    // Linked to Focus/Alarms
    _notifications.showAlarm(
      id: 999,
      title: "Focus Alarm",
      body: "Time is up! (Testing Alarm Sound)",
    );
  }

  void _testReminder() {
    // Linked to Tasks/Reminders
    _notifications.showSmartNudge(
      id: 998,
      title: "Test Reminder",
      body: "This is your reminder sound.",
    );
  }

  void _testCompletion() {
    // Linked to Completion
    _notifications.showCompletion(
      id: 997,
      title: "Task Completed",
      body: "Good job! (Testing Completion Sound)",
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final disabledText = colors.textSecondary.withOpacity(0.5);

    return Scaffold(
      backgroundColor: colors.bgMain,
      appBar: AppBar(
        backgroundColor: colors.bgMain,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Notifications",
          style: TextStyle(color: colors.textMain, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 1. MASTER TOGGLE
          _buildToggleCard(
            colors: colors,
            title: "Allow Notifications",
            subtitle: "Master switch for all app alerts",
            value: _settings.allEnabled,
            isMaster: true,
            onChanged: (val) {
              _settings.allEnabled = val;
              _update();
            },
          ),

          const SizedBox(height: 25),

          if (_settings.allEnabled) ...[
            _buildSectionHeader("Sound & Feedback", colors),

            // ALARMS (Linked to focusNotifications)
            _buildSoundOption(
              colors: colors,
              title: "Alarms & Focus",
              subtitle: "Timer sounds",
              value: _settings.focusNotifications,
              onChanged: (v) {
                _settings.focusNotifications = v;
                _update();
              },
              onTestTap: _testAlarm,
            ),

            // REMINDERS (Linked to taskNotifications)
            _buildSoundOption(
              colors: colors,
              title: "Reminders",
              subtitle: "Task due dates",
              value: _settings.taskNotifications,
              onChanged: (v) {
                _settings.taskNotifications = v;
                _update();
              },
              onTestTap: _testReminder,
            ),

            // COMPLETION (New Field)
            _buildSoundOption(
              colors: colors,
              title: "Completion Sound",
              subtitle: "Play sound when task is done",
              value: _settings.completionSounds,
              onChanged: (v) {
                _settings.completionSounds = v;
                _update();
              },
              onTestTap: _testCompletion,
            ),

            const SizedBox(height: 20),
            _buildSectionHeader("Advanced", colors),

            // VIBRATION
            _buildSimpleSwitch(
              colors: colors,
              title: "Vibration",
              value: _settings.vibrationEnabled,
              onChanged: (v) {
                _settings.vibrationEnabled = v;
                _update();
              },
            ),

            // LOOPING ALARM
            _buildSimpleSwitch(
              colors: colors,
              title: "Loop Alarm Sound",
              subtitle: "Keep playing until dismissed",
              value: _settings.loopingAlarm,
              onChanged: (v) {
                _settings.loopingAlarm = v;
                _update();
              },
            ),
          ] else ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Text(
                  "Notifications are disabled.",
                  style: TextStyle(color: disabledText),
                ),
              ),
            )
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, left: 5),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // Card for the Master Switch
  Widget _buildToggleCard({
    required AppColors colors,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    bool isMaster = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isMaster ? colors.bgMiddle : colors.bgMiddle.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
        border: isMaster ? Border.all(color: colors.highlight, width: 1) : null,
      ),
      child: SwitchListTile(
        activeColor: colors.highlight,
        inactiveTrackColor: colors.bgBottom,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        title: Text(
          title,
          style: TextStyle(
              color: colors.textMain,
              fontWeight: FontWeight.bold,
              fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: colors.textSecondary, fontSize: 12),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  // Row with "Test" button
  Widget _buildSoundOption({
    required AppColors colors,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required VoidCallback onTestTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgMiddle,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textMain,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: colors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),

          // Test Button
          GestureDetector(
            onTap: onTestTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colors.bgTop,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.play_arrow, size: 14, color: colors.highlight),
                  const SizedBox(width: 4),
                  Text(
                    "Test",
                    style: TextStyle(
                        color: colors.highlight,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          Switch(
            value: value,
            activeColor: colors.highlight,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // Simple Switch for Vibration/Looping
  Widget _buildSimpleSwitch({
    required AppColors colors,
    required String title,
    String? subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.bgMiddle,
        borderRadius: BorderRadius.circular(15),
      ),
      child: SwitchListTile(
        activeColor: colors.highlight,
        inactiveTrackColor: colors.bgBottom,
        title: Text(title,
            style: TextStyle(
                color: colors.textMain,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
        subtitle: subtitle != null
            ? Text(subtitle,
                style: TextStyle(color: colors.textSecondary, fontSize: 11))
            : null,
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
