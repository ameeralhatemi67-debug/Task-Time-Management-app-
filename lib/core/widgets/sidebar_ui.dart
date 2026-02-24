import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import 'package:task_manager_app/core/widgets/profile_bubble.dart';
import 'package:task_manager_app/core/services/auth_service.dart';
import 'package:task_manager_app/features/settings/pages/settings_page.dart';

// --- MODELS ---

class SidebarItem {
  final String id;
  final String name;
  final IconData icon;
  final bool isCore;
  final List<SidebarItem>? children; // NEW: Supports Hierarchy

  const SidebarItem({
    required this.id,
    required this.name,
    required this.icon,
    this.isCore = false,
    this.children,
  });
}

class SidebarSection {
  final String title;
  final List<SidebarItem> items;
  final int flex;

  const SidebarSection({
    required this.title,
    required this.items,
    required this.flex,
  });
}

// --- UI WIDGET ---

class SidebarUI extends StatefulWidget {
  final AppColors colors;

  // STATE
  final String currentFolderId;
  final String pinnedFolderId;
  final Map<String, int> folderCounts;

  // LAYOUT CONFIGURATION
  final int headerFlex;
  final int bottomFlex;
  final List<SidebarSection> sections;

  // ACTIONS
  final Function(SidebarItem item) onSelect;
  final Function(SidebarItem item) onPin;
  final Function(SidebarItem item) onDelete;
  final Function(SidebarItem item, String newName) onRename;
  final Function(String name, bool isSubFolder) onAdd;

  const SidebarUI({
    super.key,
    required this.colors,
    required this.currentFolderId,
    required this.pinnedFolderId,
    required this.folderCounts,
    required this.headerFlex,
    required this.bottomFlex,
    required this.sections,
    required this.onSelect,
    required this.onPin,
    required this.onDelete,
    required this.onRename,
    required this.onAdd,
  });

  @override
  State<SidebarUI> createState() => _SidebarUIState();
}

class _SidebarUIState extends State<SidebarUI> {
  bool _isEditMode = false;
  final Set<String> _expandedIds = {}; // NEW: Track expanded folders

  // --- DIALOGS (UI Logic) ---

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.colors.bgMiddle,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.create_new_folder_outlined,
                  color: widget.colors.textMain),
              title: Text("New Folder",
                  style: TextStyle(color: widget.colors.textMain)),
              onTap: () {
                Navigator.pop(context);
                _showNameInput(isSubFolder: false);
              },
            ),
            ListTile(
              leading: Icon(Icons.subdirectory_arrow_right,
                  color: widget.colors.textMain),
              title: Text("New Sub-folder",
                  style: TextStyle(color: widget.colors.textMain)),
              onTap: () {
                Navigator.pop(context);
                _showNameInput(isSubFolder: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNameInput({required bool isSubFolder}) {
    String newName = "";
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.colors.bgMiddle,
        title: Text(isSubFolder ? "New Sub-folder" : "New Folder",
            style: TextStyle(color: widget.colors.textMain)),
        content: TextField(
          autofocus: true,
          style: TextStyle(color: widget.colors.textMain),
          decoration: InputDecoration(
            hintText: "Name",
            hintStyle: TextStyle(color: widget.colors.textSecondary),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: widget.colors.textSecondary)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: widget.colors.highlight)),
          ),
          onChanged: (v) => newName = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel",
                style: TextStyle(color: widget.colors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              if (newName.isNotEmpty) {
                widget.onAdd(newName, isSubFolder);
                Navigator.pop(context);
              }
            },
            child: Text("Create",
                style: TextStyle(
                    color: widget.colors.highlight,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(SidebarItem item) {
    String newName = item.name;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.colors.bgMiddle,
        title: Text("Rename Folder",
            style: TextStyle(color: widget.colors.textMain)),
        content: TextField(
          controller: TextEditingController(text: item.name),
          style: TextStyle(color: widget.colors.textMain),
          onChanged: (v) => newName = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel",
                style: TextStyle(color: widget.colors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              if (newName.isNotEmpty) {
                widget.onRename(item, newName);
                Navigator.pop(ctx);
              }
            },
            child:
                Text("Save", style: TextStyle(color: widget.colors.highlight)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(SidebarItem item) {
    int count = widget.folderCounts[item.id] ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.colors.bgMiddle,
        title: Text("Delete '${item.name}'?",
            style: TextStyle(color: widget.colors.textMain)),
        content: Text(
            count > 0
                ? "This folder contains $count items."
                : "This folder is empty.",
            style: TextStyle(color: widget.colors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                widget.onDelete(item);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  // --- BUILD ---

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    String rawName = user?.displayName ?? "User";
    final String displayName =
        rawName.length > 13 ? "${rawName.substring(0, 10)}..." : rawName;

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.80,
      child: Drawer(
        backgroundColor: widget.colors.bgBottom,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(topRight: Radius.circular(30)),
        ),
        child: Column(
          children: [
            // 1. TOP HEADER
            Expanded(
              flex: widget.headerFlex,
              child: Container(
                padding: const EdgeInsets.only(top: 40, left: 10, right: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 45,
                      height: 45,
                      child: FittedBox(
                        child:
                            ProfileBubble(colors: widget.colors, userName: ""),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        displayName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: widget.colors.textMain,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search,
                            color: widget.colors.textMain, size: 22),
                        const SizedBox(width: 7),
                        Icon(Icons.notifications_none,
                            color: widget.colors.textMain, size: 22),
                        const SizedBox(width: 7),
                        GestureDetector(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SettingsPage())),
                          child: Icon(Icons.settings,
                              color: widget.colors.textMain, size: 22),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 2. DYNAMIC SECTIONS
            ...widget.sections.map((section) => Expanded(
                  flex: section.flex,
                  child: Container(
                    padding: const EdgeInsets.only(
                        top: 10, bottom: 5, left: 15, right: 15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              section.title,
                              style: TextStyle(
                                color: widget.colors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            if (_isEditMode && section == widget.sections.last)
                              Text("Edit Mode",
                                  style: TextStyle(
                                      color: widget.colors.priorityHigh,
                                      fontSize: 10)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: section.flex > 4
                              ? SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      if (section.items.isEmpty)
                                        Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Text("No items yet.",
                                              style: TextStyle(
                                                  color: widget
                                                      .colors.textSecondary)),
                                        ),
                                      ...section.items.map((item) =>
                                          _buildFolderTile(item, depth: 0)),
                                    ],
                                  ),
                                )
                              : Column(
                                  children: section.items
                                      .map((item) =>
                                          _buildFolderTile(item, depth: 0))
                                      .toList(),
                                ),
                        ),
                      ],
                    ),
                  ),
                )),

            // 3. BOTTOM ACTIONS
            Expanded(
              flex: widget.bottomFlex,
              child: Container(
                child: _buildBottomActions(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- RECURSIVE FOLDER BUILDER ---

  Widget _buildFolderTile(SidebarItem item, {required int depth}) {
    final bool isSelected = widget.currentFolderId == item.id;
    final bool isPinned = widget.pinnedFolderId == item.id;
    final int count = widget.folderCounts[item.id] ?? 0;

    final bool hasChildren = item.children != null && item.children!.isNotEmpty;
    final bool isExpanded = _expandedIds.contains(item.id);

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            if (_isEditMode && !item.isCore) {
              _showRenameDialog(item);
            } else {
              widget.onSelect(item);
            }
          },
          onLongPress: (!_isEditMode) ? () => widget.onPin(item) : null,
          child: Container(
            margin: const EdgeInsets.only(bottom: 5),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? widget.colors.highlight : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                // Indentation
                SizedBox(width: depth * 12.0),

                // Chevron (Toggle Expansion)
                if (hasChildren)
                  GestureDetector(
                    onTap: () => setState(() {
                      if (isExpanded) {
                        _expandedIds.remove(item.id);
                      } else {
                        _expandedIds.add(item.id);
                      }
                    }),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_right,
                        size: 18,
                        color: isSelected
                            ? widget.colors.textHighlighted
                            : widget.colors.textSecondary,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 24), // Placeholder for alignment

                Icon(
                  item.icon,
                  color: isSelected
                      ? widget.colors.textHighlighted
                      : widget.colors.textMain,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected
                          ? widget.colors.textHighlighted
                          : widget.colors.textMain,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),

                if (_isEditMode && !item.isCore) ...[
                  GestureDetector(
                    onTap: () => _showDeleteDialog(item),
                    child: Icon(Icons.delete_outline,
                        size: 18, color: widget.colors.priorityHigh),
                  ),
                ] else ...[
                  if (isPinned)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Icon(Icons.push_pin,
                          size: 14, color: widget.colors.priorityMedium),
                    ),
                  if (isSelected && !isPinned)
                    GestureDetector(
                      onTap: () => widget.onPin(item),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Icon(Icons.push_pin_outlined,
                            size: 14, color: widget.colors.textHighlighted),
                      ),
                    ),
                  Text(
                    "$count",
                    style: TextStyle(
                      color: isSelected
                          ? widget.colors.textHighlighted
                          : widget.colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Recursive Children
        if (hasChildren && isExpanded)
          ...item.children!
              .map((child) => _buildFolderTile(child, depth: depth + 1)),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      decoration: BoxDecoration(
          border: Border(
              top: BorderSide(
                  color: widget.colors.textSecondary.withOpacity(0.1)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionBtn("Add", Icons.add, _showAddDialog),
          _buildActionBtn(
              _isEditMode ? "Done" : "Edit",
              _isEditMode ? Icons.check : Icons.edit,
              () => setState(() => _isEditMode = !_isEditMode)),
        ],
      ),
    );
  }

  Widget _buildActionBtn(String label, IconData icon, VoidCallback onTap) {
    bool isActive = (label == "Edit" || label == "Done") && _isEditMode;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color:
                  isActive ? widget.colors.highlight : widget.colors.textMain,
              size: 22),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  color: isActive
                      ? widget.colors.highlight
                      : widget.colors.textSecondary,
                  fontSize: 10)),
        ],
      ),
    );
  }
}
