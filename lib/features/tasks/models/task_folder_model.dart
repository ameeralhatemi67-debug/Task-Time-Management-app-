import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'task_folder_model.g.dart';

@HiveType(typeId: 4)
class TaskFolder extends HiveObject {
  // <--- CHANGED: Added extends HiveObject
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  DateTime dateCreated;

  @HiveField(3)
  List<String> sections;

  TaskFolder({
    required this.id,
    required this.name,
    required this.dateCreated,
    required this.sections,
  });

  static TaskFolder create(String name) {
    return TaskFolder(
      id: const Uuid().v4(),
      name: name,
      dateCreated: DateTime.now(),
      sections: ["General"],
    );
  }
}
