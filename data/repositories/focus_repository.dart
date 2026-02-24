import 'package:hive/hive.dart';
import 'package:task_manager_app/features/focus/models/focus_task_model.dart';
import '../../../../core/services/storage_service.dart';
import 'base_repository.dart';

class FocusRepository extends BaseRepository<FocusTaskModel> {
  @override
  Box<FocusTaskModel> get box => StorageService.instance.focusBox;

  Future<void> addFocusTask(FocusTaskModel task) async {
    await save(task.id, task);
  }

  // --- NEW ACTIONS ---

  Future<void> togglePin(FocusTaskModel task) async {
    task.isPinned = !task.isPinned;
    await task.save();
  }

  Future<void> toggleArchive(FocusTaskModel task) async {
    task.isArchived = !task.isArchived;
    await task.save();
  }

  Future<void> deleteFocusTask(String id) async {
    await delete(id);
  }

  /// Returns Active Tasks: Not archived AND (Not done OR Done within last 24h)
  List<FocusTaskModel> getActiveTasks() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    return getAll().where((t) {
      if (t.isArchived) return false;
      if (t.isDone && t.dateCreated.isBefore(cutoff)) return false;
      return true;
    }).toList();
  }

  /// Returns Archived Tasks: Explicitly archived OR (Done AND older than 24h)
  List<FocusTaskModel> getArchivedTasks() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    return getAll().where((t) {
      if (t.isArchived) return true;
      if (t.isDone && t.dateCreated.isBefore(cutoff)) return true;
      return false;
    }).toList();
  }
}
