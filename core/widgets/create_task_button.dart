import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import 'package:task_manager_app/features/smart_add/widgets/smart_add_sheet.dart';
import 'package:task_manager_app/features/smart_add/widgets/smart_scan_overlay.dart';
import 'package:task_manager_app/features/smart_add/services/ocr_service.dart';
import 'package:task_manager_app/features/smart_add/widgets/smart_review_overlay.dart';

class CreateTaskButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isMenuEnabled;

  const CreateTaskButton({
    super.key,
    this.onPressed,
    this.isMenuEnabled = false,
  });

  @override
  State<CreateTaskButton> createState() => _CreateTaskButtonState();
}

class _CreateTaskButtonState extends State<CreateTaskButton>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  final ImagePicker _picker = ImagePicker();

  // --- ANIMATIONS ---
  late AnimationController _hubController;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _hubController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _expandAnimation = CurvedAnimation(
      parent: _hubController,
      curve: Curves.easeOutBack, // The signature "Kickback"
      reverseCurve: Curves.easeInBack,
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(parent: _hubController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hubController.dispose();
    super.dispose();
  }

  void _toggleHub() {
    if (!widget.isMenuEnabled) {
      widget.onPressed?.call();
      return;
    }

    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _hubController.forward();
      } else {
        _hubController.reverse();
      }
    });
    HapticFeedback.mediumImpact();
  }

  // --- REFACTORED: HANDLES BOTH CAMERA AND GALLERY ---
  Future<void> _handleScanAction(ImageSource source) async {
    _toggleHub(); // Collapse menu

    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (photo == null) return;

      OverlayEntry? loader;
      if (mounted) {
        loader = OverlayEntry(builder: (context) => const SmartScanOverlay());
        Overlay.of(context).insert(loader);
      }

      final String text = await OCRService.instance.recognizeText(photo.path);
      loader?.remove();

      if (mounted) {
        Navigator.push(
          context,
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (_, __, ___) => SmartReviewOverlay(
              rawText: text,
              onRetake: () {
                Navigator.pop(context);
                _handleScanAction(source); // Retake using same method
              },
            ),
            transitionsBuilder: (_, anim, __, child) {
              return FadeTransition(opacity: anim, child: child);
            },
          ),
        );
      }
    } catch (e) {
      // In case of error (e.g. permission denied), just close hub
      debugPrint("Scan Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: _toggleHub,
          child: AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return Container(
                width: 75,
                height: 75 + (_expandAnimation.value * 410),
                decoration: BoxDecoration(
                  color: _isExpanded ? colors.bgMiddle : colors.highlight,
                  borderRadius: BorderRadius.circular(40),
                  border: _isExpanded
                      ? Border.all(color: colors.bgBottom, width: 2)
                      : null,
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    reverse: true,
                    child: SizedBox(
                      height: 75 + (1.0 * 410),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // 1. THE 6 OPTION ICONS
                          Expanded(
                            child: FadeTransition(
                              opacity: _expandAnimation,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  const SizedBox(height: 15),
                                  // Manual Text Entry
                                  _buildIcon(Icons.auto_awesome, colors, () {
                                    _toggleHub();
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) =>
                                          const SmartAddSheet(),
                                    );
                                  }),
                                  _buildIcon(
                                      Icons.check_box_outlined, colors, () {}),
                                  _buildIcon(
                                      Icons.filter_center_focus, colors, () {}),

                                  // NEW: GALLERY BUTTON (Replaced Icons.cached)
                                  _buildIcon(
                                      Icons.image,
                                      colors,
                                      () => _handleScanAction(
                                          ImageSource.gallery)),

                                  _buildIcon(Icons.edit_note, colors, () {}),

                                  // EXISTING: CAMERA BUTTON
                                  _buildIcon(
                                      Icons.camera_alt,
                                      colors,
                                      () => _handleScanAction(
                                          ImageSource.camera)),
                                ],
                              ),
                            ),
                          ),

                          // 2. THE MAIN TRIGGER ICON
                          SizedBox(
                            height: 75,
                            width: 75,
                            child: Center(
                              child: RotationTransition(
                                turns: _rotationAnimation,
                                child: Icon(
                                  Icons.add,
                                  size: 40,
                                  color: _isExpanded
                                      ? colors.textMain
                                      : colors.textHighlighted,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIcon(IconData icon, AppColors colors, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Icon(icon, color: colors.textMain, size: 28),
      ),
    );
  }
}
