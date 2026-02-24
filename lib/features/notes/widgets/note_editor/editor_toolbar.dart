import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';

class EditorToolbar extends StatelessWidget {
  final AppColors colors;
  final QuillController controller;

  // Callbacks for the complex menus (Phase C implementation)
  final VoidCallback onColorPressed;
  final VoidCallback onSizePressed;
  final VoidCallback onAlignPressed;

  const EditorToolbar({
    super.key,
    required this.colors,
    required this.controller,
    required this.onColorPressed,
    required this.onSizePressed,
    required this.onAlignPressed,
  });

  @override
  Widget build(BuildContext context) {
    // We use a Container with bgMiddle to match the keyboard integration look
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: colors.bgMiddle,
        border: Border(top: BorderSide(color: colors.bgBottom, width: 1)),
      ),
      // Use a ListView to ensure it scrolls if screens are narrow
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // 1. Checkbox
          _buildToggleIcon(Attribute.unchecked, Icons.check_box_outlined),

          // 2. Color (Custom Callback)
          _buildActionIcon(Icons.format_color_text, onColorPressed),

          // 3. Size (Custom Callback)
          _buildActionIcon(Icons.format_size, onSizePressed),

          _buildVerticalDivider(),

          // 4. Bold
          _buildToggleIcon(Attribute.bold, Icons.format_bold),

          // 5. Italic
          _buildToggleIcon(Attribute.italic, Icons.format_italic),

          // 6. Underline
          _buildToggleIcon(Attribute.underline, Icons.format_underline),

          // 7. Strike (Line cutting text)
          _buildToggleIcon(Attribute.strikeThrough, Icons.format_strikethrough),

          _buildVerticalDivider(),

          // 8. Numbered List
          _buildToggleIcon(Attribute.ol, Icons.format_list_numbered),

          // 9. Bullet List
          _buildToggleIcon(Attribute.ul, Icons.format_list_bulleted),

          // 10. Alignment (Custom Callback)
          _buildActionIcon(Icons.format_align_left, onAlignPressed),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildVerticalDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
      width: 1,
      color: colors.textSecondary.withOpacity(0.2),
    );
  }

  // Used for simple toggles (Bold, Italic, Lists) handled by Quill
  Widget _buildToggleIcon(Attribute attribute, IconData icon) {
    // We listen to the controller to highlight the icon if active
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isToggled = controller.getSelectionStyle().attributes.containsKey(
          attribute.key,
        );
        return IconButton(
          icon: Icon(icon, size: 22),
          color: isToggled ? colors.highlight : colors.textMain,
          onPressed: () {
            final isCurrentlyToggled = controller
                .getSelectionStyle()
                .attributes
                .containsKey(attribute.key);
            if (isCurrentlyToggled) {
              controller.formatSelection(
                Attribute.clone(attribute, null),
              ); // Remove
            } else {
              controller.formatSelection(attribute); // Add
            }
          },
        );
      },
    );
  }

  // Used for complex actions that open a popup (Color, Size, Align)
  Widget _buildActionIcon(IconData icon, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, size: 22),
      color: colors.textMain,
      onPressed: onPressed,
    );
  }
}
