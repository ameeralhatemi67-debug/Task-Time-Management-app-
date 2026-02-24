import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'habit_folder_model.g.dart';

@HiveType(typeId: 5)
class HabitFolder extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  DateTime dateCreated;

  @HiveField(3)
  List<String> habitIds;

  // --- NEW FIELD ---
  @HiveField(4, defaultValue: 'folder')
  String iconKey;

  HabitFolder({
    required this.id,
    required this.name,
    required this.dateCreated,
    List<String>? habitIds,
    this.iconKey = 'folder',
  }) : habitIds = habitIds ?? [];

  static HabitFolder create(String name) {
    return HabitFolder(
      id: const Uuid().v4(),
      name: name,
      dateCreated: DateTime.now(),
      habitIds: [],
      iconKey: 'folder',
    );
  }
}
