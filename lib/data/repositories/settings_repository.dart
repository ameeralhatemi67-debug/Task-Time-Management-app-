import 'package:hive/hive.dart';
import 'package:task_manager_app/core/services/storage_service.dart';
import 'package:task_manager_app/features/settings/models/notification_settings_model.dart';

class SettingsRepository {
  Box<NotificationSettings> get box => StorageService.instance.settingsBox;

  // Get current settings or create default if not exists
  NotificationSettings getSettings() {
    if (box.isEmpty) {
      final defaultSettings = NotificationSettings();
      box.put('notifications', defaultSettings);
      return defaultSettings;
    }
    return box.get('notifications')!;
  }

  Future<void> updateSettings(NotificationSettings settings) async {
    await box.put('notifications', settings);
  }
}
