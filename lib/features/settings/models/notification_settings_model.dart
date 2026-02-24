import 'package:hive/hive.dart';

part 'notification_settings_model.g.dart';

@HiveType(typeId: 30)
class NotificationSettings extends HiveObject {
  @HiveField(0)
  bool allEnabled; // Master Switch

  @HiveField(1)
  bool loopingAlarm; // Useful for the Focus Timer logic later

  @HiveField(2)
  String ringtoneName; // e.g., "Default"

  @HiveField(3)
  bool vibrationEnabled;

  @HiveField(4)
  bool taskNotifications; // We will use this for "Reminders"

  @HiveField(5)
  bool habitNotifications; // Can be linked to Reminders too

  @HiveField(6)
  bool focusNotifications; // We will use this for "Alarms"

  // --- NEW FIELD ---
  @HiveField(7)
  bool completionSounds; // The "Ding" when finishing a task

  NotificationSettings({
    this.allEnabled = true,
    this.loopingAlarm = false,
    this.ringtoneName = "Default",
    this.vibrationEnabled = true,
    this.taskNotifications = true,
    this.habitNotifications = true,
    this.focusNotifications = true,
    this.completionSounds = true, // Default to on
  });
}
