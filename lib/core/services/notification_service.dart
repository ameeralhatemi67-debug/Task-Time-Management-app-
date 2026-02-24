import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  final AudioPlayer _sfxPlayer = AudioPlayer();

  // --- NAVIGATION STREAM ---
  final StreamController<String?> _onNotificationClick =
      StreamController<String?>.broadcast();
  Stream<String?> get onNotificationClick => _onNotificationClick.stream;

  // --- CHANNEL IDS ---
  // We use distinct channels for different sounds
  static const String _channelAlarm = 'channel_alarm';
  static const String _channelReminder = 'channel_reminder_v2';
  static const String _channelCompletion = 'channel_completion';

  Future<void> init() async {
    tz.initializeTimeZones();

    // 1. Android Initialization
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 2. iOS Initialization
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        // Handle iOS foreground notification
      },
    );

    final settings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          _onNotificationClick.add(response.payload);
        }
      },
    );

    // 3. Create Android Channels (Required for Custom Sounds)
    // This allows the user to have different settings for each type in Android Settings
    await _createNotificationChannel(
      _channelAlarm,
      'Alarms',
      'High priority alerts',
      'alarm', // filename without extension
    );

    await _createNotificationChannel(
      _channelReminder,
      'Reminders',
      'Task and habit reminders',
      'reminder',
    );

    await _createNotificationChannel(
      _channelCompletion,
      'Task Completed',
      'Sounds when a task is done',
      'completion',
    );
  }

  /// Helper to create an Android Channel with a specific sound
  Future<void> _createNotificationChannel(
      String id, String name, String desc, String soundFileName) async {
    final androidChannel = AndroidNotificationChannel(
      id,
      name,
      description: desc,
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(soundFileName),
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  // ===========================================================================
  // SHOWING NOTIFICATIONS
  // ===========================================================================

  /// 1. IMMEDIATE ALARM (e.g., Timer finished)
  Future<void> showAlarm({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notifications.show(
      id,
      title,
      body,
      _buildDetails(
        channelId: _channelAlarm,
        soundFile: 'alarm', // Matches android/app/src/main/res/raw/alarm.mp3
      ),
      payload: payload,
    );
  }

  /// 2. SCHEDULED REMINDER (e.g., Task due date)
  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    final tzTime = tz.TZDateTime.from(scheduledDate, tz.local);

    // Don't schedule in the past
    if (tzTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      _buildDetails(
        channelId: _channelReminder,
        soundFile: 'reminder',
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime, // Fire once
      payload: payload,
    );
  }

  /// 4. DAILY HABIT REMINDER (Restored & Updated)
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      // Use the existing Reminder Channel logic so it plays 'reminder.mp3'
      _buildDetails(
        channelId: _channelReminder,
        soundFile: 'reminder',
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // <--- REPEATS DAILY
    );
  }

  /// 5. FOCUS SESSION COMPLETE
  /// Uses the high-priority Alarm channel
  Future<void> showFocusComplete({
    required int id,
    required String title,
    required String body,
  }) async {
    await _notifications.show(
      id,
      title,
      body,
      _buildDetails(
        channelId: _channelAlarm,
        soundFile: 'alarm', // Plays alarm.mp3
      ),
    );
  }

  /// 6. SMART NUDGE (AI Insights)
  Future<void> showSmartNudge({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _notifications.show(
      id,
      title,
      body,
      _buildDetails(
        channelId: _channelReminder, // Treat as a reminder
        soundFile: 'reminder', // Plays reminder.mp3
      ),
      payload: payload,
    );
  }

  /// 3. TASK COMPLETION (Immediate feedback)
  Future<void> showCompletion({
    required int id,
    required String title,
    required String body,
  }) async {
    // 1. Stop any previous sound (allows rapid checking)
    await _sfxPlayer.stop();

    // 2. Play instantly from assets
    // This expects the file at: task_manager_app/assets/sounds/completion.mp3
    await _sfxPlayer.play(AssetSource('sounds/completion.mp3'));
  }

  // --- Helper to build platform specifics ---
  NotificationDetails _buildDetails({
    required String channelId,
    required String soundFile,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId, // Must match the channel created in init()
        channelId == _channelAlarm ? 'Alarms' : 'Reminders', // Simple Name
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        // Android sound reference
        sound: RawResourceAndroidNotificationSound(soundFile),
      ),
      iOS: DarwinNotificationDetails(
        presentSound: true,
        // iOS sound reference (must include extension)
        sound: '$soundFile.mp3',
      ),
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
