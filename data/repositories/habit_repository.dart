import 'package:hive/hive.dart';
import 'package:task_manager_app/core/services/storage_service.dart';
import '../../features/habits/models/habit_model.dart';
import '../../features/habits/models/habit_folder_model.dart';
import '../../features/smart_add/services/keyword_service.dart'; // <--- NEW: Link to the Brain
import 'base_repository.dart';

class HabitRepository extends BaseRepository<HabitModel> {
  // --- CONSTANTS ---
  static const String coreWeekly = 'core_weekly';
  static const String coreMonthly = 'core_monthly';
  static const String coreYearly = 'core_yearly';

  // "Virtual" Views
  static const String idAll = 'all_habits';
  static const String idArchived = 'archived_habits';

  // Preference Keys
  static const String _prefDefaultFolderKey = 'habit_default_folder_id';
  static const String _prefDailyGoalKey = 'habit_daily_goal';
  static const String _prefStreakModeKey = 'habit_streak_mode_global';
  static const String _prefShowStreakCounterKey = 'habit_show_streak_counter';
  static const String _prefShowHabitBadgesKey = 'habit_show_badges'; // NEW

  @override
  Box<HabitModel> get box => StorageService.instance.habitBox;

  Box<HabitFolder> get folderBox => StorageService.instance.habitFolderBox;

  Box get prefsBox => StorageService.instance.prefsBox;

  // ---------------------------------------------------------------------------
  // 1. PREFERENCES
  // ---------------------------------------------------------------------------

  String getDefaultFolder() {
    return prefsBox.get(_prefDefaultFolderKey, defaultValue: idAll);
  }

  Future<void> setDefaultFolder(String id) async {
    await prefsBox.put(_prefDefaultFolderKey, id);
  }

  int getDailyGoal() {
    return prefsBox.get(_prefDailyGoalKey, defaultValue: 3);
  }

  Future<void> setDailyGoal(int goal) async {
    await prefsBox.put(_prefDailyGoalKey, goal);
  }

  bool getStreakMode() {
    return prefsBox.get(_prefStreakModeKey, defaultValue: true);
  }

  Future<void> setStreakMode(bool isGlobal) async {
    await prefsBox.put(_prefStreakModeKey, isGlobal);
  }

  bool getShowStreakCounter() {
    return prefsBox.get(_prefShowStreakCounterKey, defaultValue: true);
  }

  Future<void> setShowStreakCounter(bool show) async {
    await prefsBox.put(_prefShowStreakCounterKey, show);
  }

  // --- NEW: SHOW BADGES TOGGLE ---
  bool getShowHabitBadges() {
    return prefsBox.get(_prefShowHabitBadgesKey, defaultValue: true);
  }

  Future<void> setShowHabitBadges(bool show) async {
    await prefsBox.put(_prefShowHabitBadgesKey, show);
  }

  // ---------------------------------------------------------------------------
  // 2. HELPER METHODS
  // ---------------------------------------------------------------------------

  bool isCoreFolder(String id) {
    return id == coreWeekly || id == coreMonthly || id == coreYearly;
  }

  List<HabitFolder> getFolders() {
    final coreFolders = [
      HabitFolder(
          id: coreWeekly,
          name: 'Weekly Habits',
          dateCreated: DateTime(2000),
          iconKey: 'view_week'),
      HabitFolder(
          id: coreMonthly,
          name: 'Monthly Habits',
          dateCreated: DateTime(2000),
          iconKey: 'calendar_view_month'),
      HabitFolder(
          id: coreYearly,
          name: 'Yearly Goals',
          dateCreated: DateTime(2000),
          iconKey: 'calendar_today'),
    ];

    final userFolders = folderBox.values.toList()
      ..sort((a, b) => a.dateCreated.compareTo(b.dateCreated));

    return [...coreFolders, ...userFolders];
  }

  Future<void> createFolder(String name) async {
    final folder = HabitFolder.create(name);
    await folderBox.put(folder.id, folder);
  }

  Future<void> deleteFolder(String id) async {
    await folderBox.delete(id);
    final habitsInFolder = box.values.where((h) => h.folderId == id);
    for (var h in habitsInFolder) {
      h.folderId = null;
      await h.save();
    }
  }

  Future<void> renameFolder(String id, String newName) async {
    final folder = folderBox.get(id);
    if (folder != null) {
      folder.name = newName;
      await folder.save();
    }
  }

  // ---------------------------------------------------------------------------
  // 3. HABIT CRUD & FILTERING
  // ---------------------------------------------------------------------------

  Future<void> saveHabit(HabitModel habit) async {
    // 1. CRITICAL: Save FIRST.
    await save(habit.id, habit);

    // 2. NEW: Silent Learning (The Teacher)
    // We allow learning for both Custom Folders AND Core Folders (Weekly/Monthly)
    try {
      if (habit.folderId != null && habit.folderId != idAll) {
        await KeywordService.instance
            .learnCorrection(habit.title, habit.folderId!);
      }
    } catch (e) {
      // Fail silently, never block the UI
      print("SmartLearning Error: $e");
    }
  }

  List<HabitModel> getAllActiveHabits() {
    return box.values.where((h) => !(h.isArchived ?? false)).toList();
  }

  List<HabitModel> getArchivedHabits() {
    return box.values.where((h) => (h.isArchived ?? false)).toList();
  }

  List<HabitModel> getHabits({required String folderId}) {
    return getHabitsByFolder(folderId);
  }

  List<HabitModel> getHabitsByFolder(String folderId) {
    if (folderId == idAll) return getAllActiveHabits();
    if (folderId == idArchived) return getArchivedHabits();

    if (folderId == coreWeekly) {
      return getAllActiveHabits()
          .where((h) => h.type == HabitType.weekly)
          .toList();
    }
    if (folderId == coreMonthly) {
      return getAllActiveHabits()
          .where((h) => h.type == HabitType.monthly)
          .toList();
    }
    if (folderId == coreYearly) {
      return getAllActiveHabits()
          .where((h) => h.type == HabitType.yearly)
          .toList();
    }

    return box.values
        .where((h) => h.folderId == folderId && !(h.isArchived ?? false))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // 4. BULK ACTIONS
  // ---------------------------------------------------------------------------

  Future<void> bulkPin(List<String> ids, bool pin) async {
    for (var id in ids) {
      final h = box.get(id);
      if (h != null) {
        h.isPinned = pin;
        await h.save();
      }
    }
  }

  Future<void> bulkArchive(List<String> ids, bool archive) async {
    for (var id in ids) {
      final h = box.get(id);
      if (h != null) {
        h.isArchived = archive;
        await h.save();
      }
    }
  }

  Future<void> bulkDelete(List<String> ids) async => await box.deleteAll(ids);

  Future<void> bulkMove(List<String> ids, String? folderId) async {
    for (var id in ids) {
      final h = box.get(id);
      if (h != null) {
        h.folderId = folderId;
        await h.save();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 5. MAINTENANCE
  // ---------------------------------------------------------------------------

  Future<void> checkAutoArchive() async {
    final now = DateTime.now();
    for (var habit in getAllActiveHabits()) {
      DateTime lastActive = habit.startDate;
      if (habit.completedDaysList.isNotEmpty) {
        final dates = List<DateTime>.from(habit.completedDaysList)
          ..sort((a, b) => b.compareTo(a));
        if (dates.first.isAfter(lastActive)) lastActive = dates.first;
      }
      final daysInactive = now.difference(lastActive).inDays;
      if (daysInactive > 60) {
        habit.isArchived = true;
        await habit.save();
      }
    }
  }
}
