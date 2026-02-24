import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'focus_task_model.g.dart';

@HiveType(typeId: 20)
class FocusTaskModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  int targetDurationSeconds;

  @HiveField(3)
  bool isDone;

  @HiveField(4)
  DateTime dateCreated;

  @HiveField(5)
  int accumulatedSeconds;

  // --- NEW FIELDS ---
  @HiveField(6)
  bool isPinned;

  @HiveField(7)
  bool isArchived;

  FocusTaskModel({
    required this.id,
    required this.title,
    required this.targetDurationSeconds,
    this.isDone = false,
    required this.dateCreated,
    this.accumulatedSeconds = 0,
    this.isPinned = false, // Default false
    this.isArchived = false, // Default false
  });

  static FocusTaskModel create({
    required String title,
    required int targetDuration,
  }) {
    return FocusTaskModel(
      id: const Uuid().v4(),
      title: title,
      targetDurationSeconds: targetDuration,
      dateCreated: DateTime.now(),
      isPinned: false,
      isArchived: false,
    );
  }
}
