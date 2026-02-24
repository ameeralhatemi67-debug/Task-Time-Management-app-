import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

part 'note_model.g.dart';

@HiveType(typeId: 1)
class NoteModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String content; // Plain text preview

  @HiveField(3)
  String jsonContent; // Rich text JSON

  @HiveField(4)
  DateTime dateModified;

  @HiveField(5)
  final DateTime dateCreated;

  @HiveField(6, defaultValue: false)
  bool isPinned;

  @HiveField(7, defaultValue: false)
  bool isArchived;

  @HiveField(8)
  String? folderId;

  NoteModel({
    required this.id,
    required this.title,
    required this.content,
    this.jsonContent = '',
    required this.dateModified,
    required this.dateCreated,
    this.isPinned = false,
    this.isArchived = false,
    this.folderId,
  });

  // --- FACTORY: For Easy Creation ---
  // Fixes usage like: NoteModel.create(...)
  static NoteModel create({
    required String title,
    String content = '',
    String jsonContent = '',
    String? folderId,
  }) {
    final now = DateTime.now();
    return NoteModel(
      id: const Uuid().v4(),
      title: title,
      content: content,
      jsonContent: jsonContent,
      dateModified: now,
      dateCreated: now,
      folderId: folderId,
    );
  }

  // --- COPYWITH: For Updates ---
  // Fixes usage like: note.copyWith(folderId: 'new_id')
  NoteModel copyWith({
    String? title,
    String? content,
    String? jsonContent,
    DateTime? dateModified,
    bool? isPinned,
    bool? isArchived,
    String? folderId,
  }) {
    return NoteModel(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      jsonContent: jsonContent ?? this.jsonContent,
      dateModified: dateModified ?? this.dateModified,
      dateCreated: dateCreated,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      folderId: folderId ?? this.folderId,
    );
  }

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(dateModified);
    if (diff.inDays == 0) {
      return DateFormat('h:mm a').format(dateModified);
    } else if (diff.inDays < 7) {
      return DateFormat('EEE').format(dateModified);
    } else {
      return DateFormat('MMM d').format(dateModified);
    }
  }
}
