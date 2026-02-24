import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import 'package:task_manager_app/core/theme/theme_controller.dart';
import 'package:task_manager_app/core/widgets/profile_bubble.dart';
import 'package:task_manager_app/core/services/auth_service.dart';
import 'package:task_manager_app/core/widgets/create_task_button.dart';

// MODELS & REPO
import '../models/note_folder_model.dart';
import '../models/note_model.dart';
import '../../../data/repositories/note_repository.dart';

// WIDGETS
import '../widgets/note_card.dart';
import '../widgets/note_sidebar.dart';
import '../widgets/kabab_menu.dart';
import '../../../../core/widgets/swipe_gestures.dart';
import 'note_editor_page.dart';

class NotesPage extends StatefulWidget {
  final Function(bool isOpen)? onDrawerChanged;
  final Function(bool isSelecting)? onSelectionModeChanged;

  const NotesPage({
    super.key,
    this.onDrawerChanged,
    this.onSelectionModeChanged,
  });

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final NoteRepository _repo = NoteRepository();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // --- STATE ---
  String _currentFolderId = 'all_notes';
  NoteFolder? _currentFolderObject;
  bool _isLoading = true;

  // Selection Mode
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  // Animation State for Action Bar
  bool _showActionBar = false;

  // View & Sort Options
  bool _isSlimView = false;
  SortOption _currentSort = SortOption.dateModified;
  bool _isAscending = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final root = _repo.loadRootFolder();

    try {
      final prefs = await Hive.openBox('prefs');
      final pinnedId = prefs.get('pinned_note_folder_id');

      if (pinnedId != null) {
        _currentFolderId = pinnedId;
        if (pinnedId != 'all_notes' && pinnedId != 'archived_notes') {
          _currentFolderObject = _findFolderById(root, pinnedId);
          if (_currentFolderObject == null) {
            _currentFolderId = 'all_notes';
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading prefs: $e");
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _refresh() {
    setState(() {
      if (_currentFolderObject != null) {
        final root = _repo.loadRootFolder();
        _currentFolderObject = _findFolderById(root, _currentFolderObject!.id);
      }
    });
  }

  NoteFolder? _findFolderById(NoteFolder parent, String id) {
    if (parent.id == id) return parent;
    for (var sub in parent.subFolders) {
      final found = _findFolderById(sub, id);
      if (found != null) return found;
    }
    return null;
  }

  // --- ACTIONS ---

  void _createNote() async {
    String? targetFolderId;
    if (_currentFolderObject != null) {
      targetFolderId = _currentFolderObject!.id;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorPage(initialFolderId: targetFolderId),
      ),
    );
    _refresh();
  }

  void _openNote(NoteModel note) async {
    if (_isSelectionMode) {
      _toggleSelection(note.id);
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteEditorPage(existingNote: note)),
    );
    _refresh();
  }

  // --- SELECTION LOGIC (With Sequenced Animation) ---

  void _enterSelectionMode() async {
    setState(() => _isSelectionMode = true);

    // 1. Notify MainScaffold to Hide Nav Bar
    widget.onSelectionModeChanged?.call(true);

    // 2. Wait for Nav Bar to go down
    await Future.delayed(const Duration(milliseconds: 150));

    // 3. Show Action Bar with Kickback
    if (mounted) setState(() => _showActionBar = true);
  }

  void _exitSelectionMode() async {
    // 1. Hide Action Bar
    if (mounted) setState(() => _showActionBar = false);

    // 2. Wait for Action Bar to go down
    await Future.delayed(const Duration(milliseconds: 200));

    // 3. Notify MainScaffold to Show Nav Bar
    widget.onSelectionModeChanged?.call(false);

    if (mounted) {
      setState(() {
        _isSelectionMode = false;
        _selectedIds.clear();
      });
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }

      if (!_isSelectionMode && _selectedIds.isNotEmpty) {
        _enterSelectionMode();
      }

      if (_isSelectionMode && _selectedIds.isEmpty) {
        _exitSelectionMode();
      }
    });
  }

  Future<void> _performBulkAction(
      Future<void> Function(String) action, String successMsg) async {
    for (String id in _selectedIds) {
      await action(id);
    }
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$successMsg (${_selectedIds.length})")));
    _exitSelectionMode();
    _refresh();
  }

  Future<void> _deleteSelected() async {
    await _performBulkAction(
        (id) async => await _repo.deleteNote(id), "Deleted");
  }

  // --- SINGLE ACTIONS ---

  Future<void> _deleteSingle(NoteModel note) async {
    await _repo.deleteNote(note.id);
    _refresh();
  }

  Future<void> _archiveNote(NoteModel note) async {
    note.isArchived = true;
    await note.save();
    _refresh();
  }

  Future<void> _togglePin(NoteModel note) async {
    note.isPinned = !note.isPinned;
    await note.save();
    _refresh();
  }

  // --- MOVE LOGIC ---

  void _moveSelectedNotes(AppColors colors) {
    _showMoveDialog(colors, _selectedIds.toList());
  }

  void _moveSingleNote(AppColors colors, NoteModel note) {
    _showMoveDialog(colors, [note.id]);
  }

  void _showMoveDialog(AppColors colors, List<String> noteIds) {
    showDialog(
      context: context,
      builder: (context) {
        final root = _repo.loadRootFolder();
        return AlertDialog(
          backgroundColor: colors.bgMiddle,
          title: Text("Move to...", style: TextStyle(color: colors.textMain)),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView(
              children: [
                _buildMoveTargetTile(root, colors, 0, noteIds),
                ..._buildSubFolderTargets(root, colors, 1, noteIds),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  Text("Cancel", style: TextStyle(color: colors.textSecondary)),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildSubFolderTargets(
      NoteFolder parent, AppColors colors, int depth, List<String> noteIds) {
    List<Widget> tiles = [];
    for (var sub in parent.subFolders) {
      tiles.add(_buildMoveTargetTile(sub, colors, depth, noteIds));
      tiles.addAll(_buildSubFolderTargets(sub, colors, depth + 1, noteIds));
    }
    return tiles;
  }

  Widget _buildMoveTargetTile(NoteFolder targetFolder, AppColors colors,
      int depth, List<String> noteIds) {
    if (_currentFolderObject != null &&
        targetFolder.id == _currentFolderObject!.id) {
      return const SizedBox.shrink();
    }

    return ListTile(
      contentPadding: EdgeInsets.only(left: 16.0 + (depth * 10), right: 16),
      leading: Icon(Icons.folder_open, color: colors.highlight, size: 20),
      title: Text(targetFolder.name, style: TextStyle(color: colors.textMain)),
      onTap: () async {
        final root = _repo.loadRootFolder();

        for (String noteId in noteIds) {
          String? currentSourceId;
          if (_currentFolderObject != null) {
            currentSourceId = _currentFolderObject!.id;
          } else {
            currentSourceId = _findParentFolderId(root, noteId);
          }

          if (currentSourceId != null && currentSourceId != targetFolder.id) {
            await _repo.moveNote(noteId, currentSourceId, targetFolder.id);
          }
        }

        if (mounted) {
          Navigator.pop(context);
          if (_isSelectionMode) _exitSelectionMode();
          _refresh();
        }
      },
    );
  }

  String? _findParentFolderId(NoteFolder folder, String noteId) {
    if (folder.noteIds.contains(noteId)) {
      return folder.id;
    }
    for (var sub in folder.subFolders) {
      final foundId = _findParentFolderId(sub, noteId);
      if (foundId != null) return foundId;
    }
    return null;
  }

  // --- DATA FETCHING ---

  List<NoteModel> _getDisplayNotes() {
    List<NoteModel> notes = [];

    if (_currentFolderId == 'all_notes') {
      notes = _repo.getAll().where((n) => !n.isArchived).toList();
    } else if (_currentFolderId == 'archived_notes') {
      notes = _repo.getAll().where((n) => n.isArchived).toList();
    } else if (_currentFolderObject != null) {
      notes =
          _currentFolderObject!.allNotes.where((n) => !n.isArchived).toList();
    }

    notes.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;

      int cmp = 0;
      switch (_currentSort) {
        case SortOption.dateModified:
          cmp = a.dateModified.compareTo(b.dateModified);
          break;
        case SortOption.dateCreated:
          cmp = a.dateCreated.compareTo(b.dateCreated);
          break;
        case SortOption.title:
          cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
      }
      return _isAscending ? cmp : -cmp;
    });

    return notes;
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final user = AuthService.instance.currentUser;
    final displayName = user?.displayName ?? "User";

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colors.bgMain,
        body: Center(child: CircularProgressIndicator(color: colors.highlight)),
      );
    }

    final displayNotes = _getDisplayNotes();

    String folderName;
    if (_currentFolderId == 'all_notes') {
      folderName = "All Notes";
    } else if (_currentFolderId == 'archived_notes') {
      folderName = "Archived";
    } else {
      folderName = _currentFolderObject?.name ?? "Notes";
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: colors.bgMain,
      drawer: NoteSidebar(
        colors: colors,
        currentFolderId: _currentFolderId,
        onUpdate: _refresh,
        onFolderSelected: (id, folder) {
          setState(() {
            _currentFolderId = id;
            _currentFolderObject = folder;
          });
        },
      ),
      onDrawerChanged: widget.onDrawerChanged,

      // REPLACED Single Widget body with Stack for Layering
      body: Stack(
        children: [
          // 1. MAIN CONTENT
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                if (_isSelectionMode) _exitSelectionMode();
              },
              behavior: HitTestBehavior.opaque,
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(Icons.menu, color: colors.textMain),
                            onPressed: () =>
                                _scaffoldKey.currentState?.openDrawer(),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon:
                                    Icon(Icons.search, color: colors.textMain),
                                onPressed: () {},
                              ),
                              KababMenu(
                                colors: colors,
                                isSlimView: _isSlimView,
                                onThemeChanged: () =>
                                    ThemeController.instance.toggleMode(),
                                onSelectMode: _enterSelectionMode,
                                onViewChanged: () =>
                                    setState(() => _isSlimView = !_isSlimView),
                                onSortChanged: (option) =>
                                    setState(() => _currentSort = option),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),

                    if (!_isSelectionMode)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Center(
                          child: Transform.scale(
                            scale: 0.8,
                            child: ProfileBubble(
                                colors: colors, userName: displayName),
                          ),
                        ),
                      ),

                    const SizedBox(height: 10),

                    // Folder Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              folderName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.textMain,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isAscending
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: colors.textSecondary,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _isAscending = !_isAscending),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 5),

                    // List
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors.bgBottom,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(30)),
                        ),
                        child: displayNotes.isEmpty
                            ? _buildEmptyState(colors)
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 20, 20, 100),
                                itemCount: displayNotes.length,
                                itemBuilder: (context, index) {
                                  final note = displayNotes[index];
                                  return _buildDismissibleNote(note, colors);
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. FAB (Only show when NOT selecting)
          if (!_isSelectionMode)
            Positioned(
              bottom: 131,
              right: 26,
              child: CreateTaskButton(
                isMenuEnabled: false,
                onPressed: _createNote,
              ),
            ),

          // 3. SELECTION BAR (Animated "Kickback" Entrance)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            // "Kickback" effect: easeOutBack when showing, easeInBack when hiding
            curve: _showActionBar ? Curves.easeOutBack : Curves.easeInBack,

            // Hidden = -100, Visible = 0 (bottom aligned)
            bottom: _showActionBar ? 0 : -100,
            left: 0,
            right: 0,
            child: _buildSelectionBar(colors),
          ),
        ],
      ),
    );
  }

  Widget _buildDismissibleNote(NoteModel note, AppColors colors) {
    if (_isSelectionMode) {
      return _buildNoteCard(note, colors);
    }

    return SwipeableTile(
      keyId: note.id,
      leadingOptions: [
        SwipeOption(
          icon: Icons.archive,
          color: colors.completedWork,
          label: "Archive",
          onTap: () => _archiveNote(note),
        ),
        SwipeOption(
          icon: Icons.delete,
          color: colors.priorityHigh,
          label: "Delete",
          onTap: () => _deleteSingle(note),
        ),
      ],
      trailingOptions: [
        SwipeOption(
          icon: note.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
          color: colors.priorityMedium,
          label: note.isPinned ? "Unpin" : "Pin",
          onTap: () => _togglePin(note),
        ),
        SwipeOption(
          icon: Icons.drive_file_move,
          color: colors.priorityLow,
          label: "Move",
          onTap: () => _moveSingleNote(colors, note),
        ),
      ],
      child: _buildNoteCard(note, colors),
    );
  }

  Widget _buildNoteCard(NoteModel note, AppColors colors) {
    final bool isSelected = _selectedIds.contains(note.id);

    return GestureDetector(
      onLongPress: () => _toggleSelection(note.id),
      onTap: () => _openNote(note),
      child: Stack(
        children: [
          NoteCard(
            note: note,
            isSlimView: _isSlimView,
            colors: colors,
            onTap: () => _openNote(note),
          ),
          if (_isSelectionMode)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? colors.highlight
                      : colors.bgMain.withOpacity(0.5),
                  border: Border.all(color: colors.highlight, width: 2),
                ),
                padding: const EdgeInsets.all(4),
                child: isSelected
                    ? Icon(Icons.check, size: 16, color: colors.textHighlighted)
                    : const SizedBox(width: 16, height: 16),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectionBar(AppColors colors) {
    return Container(
      height: 80,
      decoration: BoxDecoration(color: colors.bgMiddle, boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, -5),
        )
      ]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // MOVE
          IconButton(
            onPressed: () => _moveSelectedNotes(colors),
            icon: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.drive_file_move, color: colors.textMain),
                Text("Move",
                    style: TextStyle(color: colors.textMain, fontSize: 10))
              ],
            ),
          ),

          // ARCHIVE
          IconButton(
            onPressed: () => _performBulkAction((id) async {
              final n = _repo.getById(id);
              if (n != null) {
                n.isArchived = true;
                await n.save();
              }
            }, "Archived"),
            icon: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.archive, color: colors.textMain),
                Text("Archive",
                    style: TextStyle(color: colors.textMain, fontSize: 10))
              ],
            ),
          ),

          // DELETE
          IconButton(
            onPressed: _deleteSelected,
            icon: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete, color: colors.priorityHigh),
                Text("Delete",
                    style: TextStyle(color: colors.priorityHigh, fontSize: 10))
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_alt_outlined,
              size: 60, color: colors.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 10),
          Text("No notes here", style: TextStyle(color: colors.textSecondary)),
        ],
      ),
    );
  }
}
