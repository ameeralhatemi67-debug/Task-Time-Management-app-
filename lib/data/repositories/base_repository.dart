import 'package:hive/hive.dart';

/// A generic base class to handle standard CRUD (Create, Read, Update, Delete)
/// for any Hive-backed model.
abstract class BaseRepository<T> {
  /// The specific Hive box for this repository.
  /// Must be implemented by the child class.
  Box<T> get box;

  /// Get all items from the box as a List.
  List<T> getAll() {
    return box.values.toList();
  }

  /// Get a single item by its String ID.
  T? getById(String id) {
    return box.get(id);
  }

  /// Save (Create or Update) an item using its ID as the key.
  Future<void> save(String id, T item) async {
    await box.put(id, item);
  }

  /// Delete an item by its ID.
  Future<void> delete(String id) async {
    await box.delete(id);
  }

  /// Delete multiple items at once.
  Future<void> deleteAll(Iterable<String> ids) async {
    await box.deleteAll(ids);
  }

  /// Clear the entire box.
  Future<void> clear() async {
    await box.clear();
  }
}
