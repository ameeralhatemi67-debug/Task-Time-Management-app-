import '../../features/notes/models/note_model.dart';
import '../../features/notes/models/note_folder_model.dart';
import '../../core/services/storage_service.dart';
import 'base_repository.dart';
import 'package:hive/hive.dart';

class NoteRepository extends BaseRepository<NoteModel> {
  @override
  Box<NoteModel> get box => StorageService.instance.noteBox;

  final _folderBox = StorageService.instance.folderBox;

  // --- 1. INITIALIZATION (The Recursive Tree) ---

  NoteFolder loadRootFolder() {
    NoteFolder? root = _folderBox.get('root');

    if (root == null) {
      root = NoteFolder.root();
      _folderBox.put('root', root);
    }

    _populateChildren(root);
    return root;
  }

  void _populateChildren(NoteFolder folder) {
    // 1. Populate Notes
    folder.notes.clear();
    List<String> validNoteIds = [];

    for (String id in folder.noteIds) {
      final note = getById(id); // Inherited from BaseRepository
      if (note != null) {
        folder.notes.add(note);
        validNoteIds.add(id);
      } else {
        // Cleanup logic could go here
      }
    }

    // 2. Populate Sub-Folders
    folder.subFolders.clear();
    List<String> validSubFolderIds = [];

    for (String id in folder.subFolderIds) {
      final sub = _folderBox.get(id);
      if (sub != null) {
        _populateChildren(sub);
        folder.subFolders.add(sub);
        validSubFolderIds.add(id);
      }
    }
  }

  // --- 2. FLAT ACCESS (For AI & Search) ---

  List<NoteFolder> getFolders() {
    return _folderBox.values.toList();
  }

  List<NoteModel> getAllNotes() {
    return getAll();
  }

  // --- 3. CRUD OPERATIONS ---

  // FIX: Updated Signature to accept named parameter 'folderId'
  Future<void> saveNote(NoteModel note, {String? folderId}) async {
    // 1. Update the Note's internal pointer if provided
    if (folderId != null) {
      note.folderId = folderId;
    }

    // 2. Save the Note itself
    await save(note.id, note);

    // 3. Link to Folder (Smart Linking)
    // If a folderId was passed, ensure the folder knows about this note
    if (folderId != null) {
      final folder = _folderBox.get(folderId);
      if (folder != null) {
        // Only add if not already there to avoid duplicates
        if (!folder.noteIds.contains(note.id)) {
          folder.noteIds.add(note.id);
          await _folderBox.put(folder.id, folder);
        }
      }
    }
  }

  Future<void> deleteNote(String noteId) async {
    await delete(noteId);
    final root = loadRootFolder();
    _removeNoteIdFromTree(root, noteId);
  }

  Future<void> moveNote(
      String noteId, String oldFolderId, String newFolderId) async {
    // 1. Remove from Old Folder
    final oldFolder = _folderBox.get(oldFolderId);
    if (oldFolder != null) {
      oldFolder.noteIds.remove(noteId);
      await _folderBox.put(oldFolderId, oldFolder);
    }

    // 2. Add to New Folder
    final newFolder = _folderBox.get(newFolderId);
    if (newFolder != null) {
      if (!newFolder.noteIds.contains(noteId)) {
        newFolder.noteIds.add(noteId);
        await _folderBox.put(newFolderId, newFolder);
      }
    }

    // 3. Sync the Model
    final note = getById(noteId);
    if (note != null) {
      note.folderId = newFolderId;
      await note.save();
    }
  }

  bool _removeNoteIdFromTree(NoteFolder folder, String noteId) {
    if (folder.noteIds.contains(noteId)) {
      folder.noteIds.remove(noteId);
      _folderBox.put(folder.id, folder);
      return true;
    }
    for (var sub in folder.subFolders) {
      if (_removeNoteIdFromTree(sub, noteId)) return true;
    }
    return false;
  }

  // --- 4. FOLDER CRUD ---

  Future<void> createFolder(String name, {String? parentId}) async {
    final newFolder = NoteFolder.create(name);
    await _folderBox.put(newFolder.id, newFolder);

    final parent =
        parentId != null ? _folderBox.get(parentId) : _folderBox.get('root');

    if (parent != null) {
      parent.subFolderIds.add(newFolder.id);
      await _folderBox.put(parent.id, parent);
    }
  }

  Future<void> deleteFolder(String folderId) async {
    await _folderBox.delete(folderId);
    final root = loadRootFolder();
    _removeFolderIdFromTree(root, folderId);
  }

  bool _removeFolderIdFromTree(NoteFolder parent, String targetId) {
    if (parent.subFolderIds.contains(targetId)) {
      parent.subFolderIds.remove(targetId);
      _folderBox.put(parent.id, parent);
      return true;
    }
    for (var sub in parent.subFolders) {
      if (_removeFolderIdFromTree(sub, targetId)) return true;
    }
    return false;
  }
}
