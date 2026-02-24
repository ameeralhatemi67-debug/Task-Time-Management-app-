import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import 'package:task_manager_app/features/smart_add/widgets/smart_add_sheet.dart';
import 'package:task_manager_app/features/smart_add/widgets/smart_scan_overlay.dart';
import 'package:task_manager_app/features/smart_add/services/ocr_service.dart';

class SmartActionHub extends StatefulWidget {
  const SmartActionHub({super.key});

  @override
  State<SmartActionHub> createState() => _SmartActionHubState();
}

class _SmartActionHubState extends State<SmartActionHub>
    with TickerProviderStateMixin {
  // --- STATE ---
  bool _isOpen = false;
  final ImagePicker _picker = ImagePicker();

  // --- ANIMATIONS ---
  late AnimationController _hubController;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _hubController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Expand menu from bottom to top
    _expandAnimation = CurvedAnimation(
      parent: _hubController,
      curve: Curves.easeOutBack,
    );

    // Fade and scale for the grid
    _fadeAnimation = CurvedAnimation(
      parent: _hubController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
    );

    // Rotate + icon to x (0.125 turns = 45 degrees)
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(parent: _hubController, curve: Curves.easeInOutBack),
    );
  }

  @override
  void dispose() {
    _hubController.dispose();
    super.dispose();
  }

  void _toggleHub() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _hubController.forward();
      } else {
        _hubController.reverse();
      }
    });
    HapticFeedback.mediumImpact();
  }

  // --- ACTIONS ---

  Future<void> _handleCameraAction() async {
    _toggleHub(); // Close the hub first

    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (photo == null) return;

    OverlayEntry? loader;
    if (mounted) {
      loader = OverlayEntry(builder: (context) => const SmartScanOverlay());
      Overlay.of(context).insert(loader);
    }

    try {
      final String extractedText =
          await OCRService.instance.recognizeText(photo.path);
      loader?.remove();

      if (extractedText.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("AI could not read text. Please try again.")),
        );
        return;
      }

      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => SmartAddSheet(initialText: extractedText),
        );
      }
    } catch (e) {
      loader?.remove();
      debugPrint("OCR Hub Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 1. THE GRID MENU (Appears above the button)
        SizeTransition(
          sizeFactor: _expandAnimation,
          axisAlignment: 1.0,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _expandAnimation,
              alignment: Alignment.bottomRight,
              child: _buildGridMenu(colors),
            ),
          ),
        ),

        const SizedBox(height: 15),

        // 2. THE MAIN TRIGGER BUTTON (+ to x)
        _buildTrigger(colors, isDark),
      ],
    );
  }

  Widget _buildTrigger(AppColors colors, bool isDark) {
    return GestureDetector(
      onTap: _toggleHub,
      child: Container(
        width: 75,
        height: 75,
        decoration: BoxDecoration(
          color: colors.highlight,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: RotationTransition(
            turns: _rotationAnimation,
            child: Icon(
              Icons.add,
              size: 40,
              color: colors.textHighlighted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridMenu(AppColors colors) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgMiddle,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.bgBottom, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.1,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildMenuIcon(context, Icons.auto_awesome, "Smart Task", colors, () {
            _toggleHub();
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const SmartAddSheet(),
            );
          }),
          _buildMenuIcon(
              context, Icons.check_box_outlined, "Task", colors, () {}),
          _buildMenuIcon(
              context, Icons.filter_center_focus, "Focus", colors, () {}),
          _buildMenuIcon(context, Icons.cached, "Habits", colors, () {}),
          _buildMenuIcon(context, Icons.edit_note, "Note", colors, () {}),
          _buildMenuIcon(
              context, Icons.camera_alt, "Camera", colors, _handleCameraAction),
        ],
      ),
    );
  }

  Widget _buildMenuIcon(BuildContext context, IconData icon, String label,
      AppColors colors, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.bgMain,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: colors.textMain, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
