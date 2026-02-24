import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart'; // Required for ID generation
import 'note_model.dart';

part 'note_folder_model.g.dart';

@HiveType(typeId: 2)
class NoteFolder {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  final DateTime dateCreated;

  @HiveField(3)
  List<String> subFolderIds; // Storing IDs for Hive Relationship

  @HiveField(4)
  List<String> noteIds; // Storing IDs for Hive Relationship

  // In-Memory containers (Not stored in Hive, populated at runtime)
  List<NoteFolder> subFolders = [];
  List<NoteModel> notes = [];

  NoteFolder({
    required this.id,
    required this.name,
    required this.dateCreated,
    List<String>? subFolderIds,
    List<String>? noteIds,
  })  : subFolderIds = subFolderIds ?? [],
        noteIds = noteIds ?? [];

  // --- FACTORY METHODS ---
  static NoteFolder create(String name) {
    return NoteFolder(
      id: const Uuid().v4(),
      name: name,
      dateCreated: DateTime.now(),
    );
  }

  static NoteFolder root() {
    return NoteFolder(
      id: 'root',
      name: 'All Notes',
      dateCreated: DateTime.now(),
    );
  }

  // --- MISSING HELPERS RESTORED ---

  /// Adds a sub-folder to this folder, updating both the ID list and object list.
  void addSubFolder(NoteFolder folder) {
    if (!subFolderIds.contains(folder.id)) {
      subFolderIds.add(folder.id);
    }
    // Avoid duplicates in memory
    if (!subFolders.any((f) => f.id == folder.id)) {
      subFolders.add(folder);
    }
  }

  /// Adds a note to this folder, updating both the ID list and object list.
  void addNote(NoteModel note) {
    if (!noteIds.contains(note.id)) {
      noteIds.add(note.id);
    }
    // Avoid duplicates in memory
    if (!notes.any((n) => n.id == note.id)) {
      notes.add(note);
    }
  }

  /// Recursively get all notes in this folder AND its sub-folders
  List<NoteModel> get allNotes {
    final List<NoteModel> all = [...notes];
    for (var sub in subFolders) {
      all.addAll(sub.allNotes);
    }
    return all;
  }
}
