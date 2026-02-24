import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart'; // Ensure flutter_colorpicker is in pubspec.yaml
import 'package:task_manager_app/core/theme/theme_controller.dart';
import 'package:uuid/uuid.dart'; // Ensure uuid is in pubspec.yaml
import 'package:task_manager_app/core/theme/colorsettings.dart';
import '../../../core/widgets/theme_test_view.dart'; // Helper for preview

class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final controller = ThemeController.instance;
        final themes = controller.availableThemes;
        final colors = Theme.of(context).extension<AppColors>()!;

        return Scaffold(
          backgroundColor: colors.bgMain,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: BackButton(color: colors.textMain),
            title: Text(
              "Appearance",
              style: TextStyle(color: colors.textMain),
            ),
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: themes.length + 1,
            itemBuilder: (context, index) {
              // "Create New" Button at the bottom
              if (index == themes.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.highlight,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: () => _showThemeEditor(context, null),
                    icon: Icon(Icons.add, color: colors.textHighlighted),
                    label: Text(
                      "Create New Theme",
                      style: TextStyle(
                        color: colors.textHighlighted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }

              // Theme Item
              final theme = themes[index];
              final isActive = theme.id == controller.currentTheme.id;

              return Card(
                color: colors.bgMiddle,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: isActive
                      ? BorderSide(color: colors.highlight, width: 2)
                      : BorderSide.none,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  title: Text(
                    theme.name,
                    style: TextStyle(
                      color: colors.textMain,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    theme.isLocked ? "System Default" : "User Custom",
                    style: TextStyle(color: colors.textSecondary),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // "Use" Button
                      if (!isActive)
                        TextButton(
                          onPressed: () => controller.setActiveTheme(theme.id),
                          child: const Text("Use"),
                        ),

                      // Edit Button (Only for custom themes)
                      if (!theme.isLocked)
                        IconButton(
                          icon: Icon(Icons.edit, color: colors.textMain),
                          onPressed: () => _showThemeEditor(context, theme),
                        ),

                      // Delete Button (Only for custom themes)
                      if (!theme.isLocked)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => controller.deleteTheme(theme.id),
                        ),

                      // Active Indicator
                      if (isActive)
                        Icon(Icons.check_circle, color: colors.done),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ===========================================================================
  // THEME EDITOR DIALOG (Fully Integrated)
  // ===========================================================================
  void _showThemeEditor(BuildContext context, ThemePreset? existingTheme) {
    final isEditing = existingTheme != null;
    final String tempId = existingTheme?.id ?? const Uuid().v4();
    String tempName = existingTheme?.name ?? "My New Theme";

    // Create deep copies so we don't mutate live data until "Save" is clicked
    AppColors tempLight =
        existingTheme?.lightColors.copyWith() ?? AppColors.light.copyWith();
    AppColors tempDark =
        existingTheme?.darkColors.copyWith() ?? AppColors.dark.copyWith();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Helper: Color Row Widget
            Widget buildColorRow(
              String label,
              Color currentColor,
              Function(Color) onColorChanged,
            ) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: currentColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.color_lens),
                      onPressed: () {
                        // Show the Color Picker
                        showDialog(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text("Pick a color"),
                            content: SingleChildScrollView(
                              child: ColorPicker(
                                pickerColor: currentColor,
                                onColorChanged: (c) => onColorChanged(c),
                                enableAlpha: false,
                                displayThumbColor: true,
                              ),
                            ),
                            actions: [
                              TextButton(
                                child: const Text("Done"),
                                onPressed: () {
                                  Navigator.of(c).pop();
                                  // Rebuild the main dialog to update preview
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }

            // Helper: List of all editable colors
            Widget buildColorList(
              AppColors colors,
              Function(AppColors) onUpdate,
            ) {
              return ListView(
                shrinkWrap: true,
                children: [
                  buildColorRow(
                    "Main Background",
                    colors.bgMain,
                    (c) => onUpdate(colors.copyWith(bgMain: c)),
                  ),
                  buildColorRow(
                    "Bottom Layer",
                    colors.bgBottom,
                    (c) => onUpdate(colors.copyWith(bgBottom: c)),
                  ),
                  buildColorRow(
                    "Middle Layer",
                    colors.bgMiddle,
                    (c) => onUpdate(colors.copyWith(bgMiddle: c)),
                  ),
                  buildColorRow(
                    "Top Layer",
                    colors.bgTop,
                    (c) => onUpdate(colors.copyWith(bgTop: c)),
                  ),
                  const Divider(),
                  buildColorRow(
                    "Text Main",
                    colors.textMain,
                    (c) => onUpdate(colors.copyWith(textMain: c)),
                  ),
                  buildColorRow(
                    "Text Secondary",
                    colors.textSecondary,
                    (c) => onUpdate(colors.copyWith(textSecondary: c)),
                  ),
                  buildColorRow(
                    "Text Highlighted",
                    colors.textHighlighted,
                    (c) => onUpdate(colors.copyWith(textHighlighted: c)),
                  ),
                  const Divider(),
                  buildColorRow(
                    "Highlight Color",
                    colors.highlight,
                    (c) => onUpdate(colors.copyWith(highlight: c)),
                  ),
                  buildColorRow(
                    "Task Done",
                    colors.done,
                    (c) => onUpdate(colors.copyWith(done: c)),
                  ),
                  buildColorRow(
                    "Task Undone",
                    colors.undone,
                    (c) => onUpdate(colors.copyWith(undone: c)),
                  ),
                ],
              );
            }

            return Dialog(
              insetPadding: const EdgeInsets.all(10),
              child: Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Header
                    Row(
                      children: [
                        const Text(
                          "Customize Theme",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Name Input
                    TextField(
                      decoration: const InputDecoration(
                        labelText: "Theme Name",
                      ),
                      controller: TextEditingController(text: tempName)
                        ..selection = TextSelection.fromPosition(
                          TextPosition(offset: tempName.length),
                        ),
                      onChanged: (val) => tempName = val,
                    ),
                    const SizedBox(height: 10),

                    // TABS
                    Expanded(
                      child: DefaultTabController(
                        length: 3,
                        child: Column(
                          children: [
                            const TabBar(
                              labelColor: Colors.black,
                              unselectedLabelColor: Colors.grey,
                              tabs: [
                                Tab(text: "Light Mode"),
                                Tab(text: "Dark Mode"),
                                Tab(
                                  text: "Preview",
                                  icon: Icon(Icons.visibility),
                                ),
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  // Tab 1: Light Editor
                                  buildColorList(
                                    tempLight,
                                    (newColors) => tempLight = newColors,
                                  ),

                                  // Tab 2: Dark Editor
                                  buildColorList(
                                    tempDark,
                                    (newColors) => tempDark = newColors,
                                  ),

                                  // Tab 3: LIVE PREVIEW
                                  SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        const SizedBox(height: 10),
                                        const Text("Light Mode Preview"),
                                        Theme(
                                          data: ThemeData.light().copyWith(
                                            extensions: [tempLight],
                                          ),
                                          child: const ThemeTestView(
                                            pageName: "Preview Light",
                                          ),
                                        ),
                                        const Divider(height: 40),
                                        const Text("Dark Mode Preview"),
                                        Theme(
                                          data: ThemeData.dark().copyWith(
                                            extensions: [tempDark],
                                          ),
                                          child: Container(
                                            color: Colors.black54,
                                            padding: const EdgeInsets.all(10),
                                            child: const ThemeTestView(
                                              pageName: "Preview Dark",
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                        onPressed: () {
                          final newPreset = ThemePreset(
                            id: tempId,
                            name: tempName,
                            lightColors: tempLight,
                            darkColors: tempDark,
                            isLocked: false,
                          );

                          if (isEditing) {
                            ThemeController.instance.updateTheme(newPreset);
                          } else {
                            ThemeController.instance.addTheme(newPreset);
                          }
                          Navigator.pop(context);
                        },
                        child: const Text("Save Theme"),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
