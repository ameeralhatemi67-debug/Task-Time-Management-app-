import 'package:hive_flutter/hive_flutter.dart';

// MODELS
import '../../features/habits/models/habit_model.dart';
import '../../features/habits/models/habit_folder_model.dart';
import '../../features/notes/models/note_model.dart';
import '../../features/notes/models/note_folder_model.dart';
import '../../features/tasks/models/task_model.dart';
import '../../features/tasks/models/task_folder_model.dart';
// Focus Model
import 'package:task_manager_app/features/focus/models/focus_task_model.dart';
// Settings Model
import 'package:task_manager_app/features/settings/models/notification_settings_model.dart';

class StorageService {
  static final StorageService instance = StorageService._();
  StorageService._();

  // Internal Box References
  Box<HabitModel>? _habitBox;
  Box<HabitFolder>? _habitFolderBox;
  Box<NoteModel>? _noteBox;
  Box<NoteFolder>? _folderBox;
  Box<TaskModel>? _taskBox;
  Box<TaskFolder>? _taskFolderBox;
  Box<FocusTaskModel>? _focusBox;
  Box<NotificationSettings>? _settingsBox;

  // General Preferences
  Box? _prefsBox;

  // --- NEW: LEARNING BRAIN ---
  Box? _associationsBox;

  // 1. INITIAL SETUP
  Future<void> initialize() async {
    await Hive.initFlutter();

    // Register Adapters
    Hive.registerAdapter(HabitModelAdapter());
    Hive.registerAdapter(HabitFolderAdapter());

    Hive.registerAdapter(NoteModelAdapter());
    Hive.registerAdapter(NoteFolderAdapter());

    Hive.registerAdapter(TaskModelAdapter());
    Hive.registerAdapter(TaskImportanceAdapter());
    Hive.registerAdapter(TaskTypeAdapter());
    Hive.registerAdapter(TaskViewTypeAdapter());
    Hive.registerAdapter(TaskFolderAdapter());

    Hive.registerAdapter(FocusTaskModelAdapter());
    Hive.registerAdapter(NotificationSettingsAdapter());

    // Open Core Boxes
    _prefsBox = await Hive.openBox('app_preferences');
    _settingsBox =
        await Hive.openBox<NotificationSettings>('notification_settings');
    _associationsBox = await Hive.openBox('keyword_associations');
  }

  // --- NEW: REFACTORED CLONING MIGRATION ---
  Future<void> _migrateGuestDataIfNeeded() async {
    // 1. Temporarily open the guest boxes to check for data
    final guestHabitBox = await Hive.openBox<HabitModel>('default_user_habits');
    final guestHabitFolderBox =
        await Hive.openBox<HabitFolder>('default_user_habit_folders');
    final guestNoteBox = await Hive.openBox<NoteModel>('default_user_notes');
    final guestFolderBox =
        await Hive.openBox<NoteFolder>('default_user_note_folders');
    final guestTaskBox = await Hive.openBox<TaskModel>('default_user_tasks');
    final guestTaskFolderBox =
        await Hive.openBox<TaskFolder>('default_user_task_folders');
    final guestFocusBox =
        await Hive.openBox<FocusTaskModel>('default_user_focus_tasks');

    // 2. Check if the guest created ANY data
    final bool hasData = guestHabitBox.isNotEmpty ||
        guestHabitFolderBox.isNotEmpty ||
        guestNoteBox.isNotEmpty ||
        guestFolderBox.isNotEmpty ||
        guestTaskBox.isNotEmpty ||
        guestTaskFolderBox.isNotEmpty ||
        guestFocusBox.isNotEmpty;

    // 3. CLONE the data so Hive doesn't throw the "Same Instance" Error
    if (hasData) {
      for (var e in guestHabitBox.values) {
        await _habitBox!.put(e.id, e.copyWith());
      }
      for (var e in guestHabitFolderBox.values) {
        await _habitFolderBox!.put(
            e.id,
            HabitFolder(
              id: e.id,
              name: e.name,
              dateCreated: e.dateCreated,
              habitIds: List.from(e.habitIds),
              iconKey: e.iconKey,
            ));
      }
      for (var e in guestNoteBox.values) {
        await _noteBox!.put(e.id, e.copyWith());
      }
      for (var e in guestFolderBox.values) {
        await _folderBox!.put(
            e.id,
            NoteFolder(
              id: e.id,
              name: e.name,
              dateCreated: e.dateCreated,
              subFolderIds: List.from(e.subFolderIds),
              noteIds: List.from(e.noteIds),
            ));
      }
      for (var e in guestTaskBox.values) {
        await _taskBox!.put(e.id, e.copyWith());
      }
      for (var e in guestTaskFolderBox.values) {
        await _taskFolderBox!.put(
            e.id,
            TaskFolder(
              id: e.id,
              name: e.name,
              dateCreated: e.dateCreated,
              sections: List.from(e.sections),
            ));
      }
      for (var e in guestFocusBox.values) {
        await _focusBox!.put(
            e.id,
            FocusTaskModel(
              id: e.id,
              title: e.title,
              targetDurationSeconds: e.targetDurationSeconds,
              isDone: e.isDone,
              dateCreated: e.dateCreated,
              accumulatedSeconds: e.accumulatedSeconds,
              isPinned: e.isPinned,
              isArchived: e.isArchived,
            ));
      }

      // Clear the guest boxes so migration only happens once
      await guestHabitBox.clear();
      await guestHabitFolderBox.clear();
      await guestNoteBox.clear();
      await guestFolderBox.clear();
      await guestTaskBox.clear();
      await guestTaskFolderBox.clear();
      await guestFocusBox.clear();
    }

    // 4. Close the guest boxes. (We DO NOT close the new user boxes!)
    await guestHabitBox.close();
    await guestHabitFolderBox.close();
    await guestNoteBox.close();
    await guestFolderBox.close();
    await guestTaskBox.close();
    await guestTaskFolderBox.close();
    await guestFocusBox.close();
  }

  // 2. USER SESSION HANDLING
  Future<void> openUserBoxes(String userId) async {
    // --- STEP 1: OPEN THE TARGET USER BOXES FIRST ---
    _habitBox = await Hive.openBox<HabitModel>('${userId}_habits');
    _habitFolderBox =
        await Hive.openBox<HabitFolder>('${userId}_habit_folders');
    _noteBox = await Hive.openBox<NoteModel>('${userId}_notes');
    _folderBox = await Hive.openBox<NoteFolder>('${userId}_note_folders');
    _taskBox = await Hive.openBox<TaskModel>('${userId}_tasks');
    _taskFolderBox = await Hive.openBox<TaskFolder>('${userId}_task_folders');
    _focusBox = await Hive.openBox<FocusTaskModel>('${userId}_focus_tasks');

    // --- STEP 2: IF THIS IS A LOGGED-IN USER, MIGRATE ANY PENDING GUEST DATA ---
    if (userId != 'default_user') {
      await _migrateGuestDataIfNeeded();
    }
  }

  Future<void> closeUserBoxes() async {
    await _habitBox?.close();
    await _habitFolderBox?.close();
    await _noteBox?.close();
    await _folderBox?.close();
    await _taskBox?.close();
    await _taskFolderBox?.close();
    await _focusBox?.close();

    _habitBox = null;
    _habitFolderBox = null;
    _noteBox = null;
    _folderBox = null;
    _taskBox = null;
    _taskFolderBox = null;
    _focusBox = null;
  }

  // --- EMERGENCY RESET METHOD ---
  Future<void> clearAllData() async {
    await closeUserBoxes();
    await _prefsBox?.clear();
    await _settingsBox?.clear();
    await _associationsBox?.clear();
    await Hive.deleteFromDisk(); // Nuke everything
  }

  // 4. SAFE GETTERS
  void _checkInit() {
    if (_habitBox == null) {
      throw Exception(
          "StorageService: Critical boxes not open. Call openUserBoxes() first.");
    }
  }

  bool get isHabitFolderBoxOpen =>
      _habitFolderBox != null && _habitFolderBox!.isOpen;

  Box<HabitModel> get habitBox {
    _checkInit();
    return _habitBox!;
  }

  Box<HabitFolder> get habitFolderBox {
    if (_habitFolderBox == null)
      throw Exception("HabitFolderBox accessed but not open.");
    return _habitFolderBox!;
  }

  Box<NoteModel> get noteBox {
    _checkInit();
    return _noteBox!;
  }

  Box<NoteFolder> get folderBox {
    _checkInit();
    return _folderBox!;
  }

  Box<TaskModel> get taskBox {
    _checkInit();
    return _taskBox!;
  }

  Box<TaskFolder> get taskFolderBox {
    _checkInit();
    return _taskFolderBox!;
  }

  Box<FocusTaskModel> get focusBox {
    _checkInit();
    return _focusBox!;
  }

  Box<NotificationSettings> get settingsBox {
    if (_settingsBox == null) throw Exception("Settings Box not initialized");
    return _settingsBox!;
  }

  Box get prefsBox {
    if (_prefsBox == null) throw Exception("Prefs Box not initialized");
    return _prefsBox!;
  }

  Box get associationsBox {
    if (_associationsBox == null)
      throw Exception("Associations Box not initialized");
    return _associationsBox!;
  }
}
