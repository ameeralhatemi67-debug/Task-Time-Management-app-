import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import 'package:task_manager_app/features/smart_add/widgets/review_cards/note_review_card.dart';
import 'package:task_manager_app/features/smart_add/widgets/review_cards/structured_review_card.dart';

class SmartReviewOverlay extends StatefulWidget {
  final String rawText;
  final VoidCallback onRetake;

  const SmartReviewOverlay({
    super.key,
    required this.rawText,
    required this.onRetake,
  });

  @override
  State<SmartReviewOverlay> createState() => _SmartReviewOverlayState();
}

class _SmartReviewOverlayState extends State<SmartReviewOverlay> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;

  // KEYS TO ACCESS CARD STATES (For Save Logic)
  final GlobalKey<NoteReviewCardState> _noteCardKey = GlobalKey();
  final GlobalKey<StructuredReviewCardState> _structuredCardKey = GlobalKey();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // --- SAVE LOGIC ---
  Future<void> _handleSend() async {
    // Path 1: Note
    if (_currentPage == 0) {
      if (_noteCardKey.currentState != null) {
        await _noteCardKey.currentState!.saveNoteToRepo();
        if (mounted) {
          Navigator.pop(context);
        }
      }
    }
    // Path 2: Structured
    else {
      if (_structuredCardKey.currentState != null) {
        await _structuredCardKey.currentState!.saveAllToRepo();
        if (mounted) {
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: colors.bgMain.withOpacity(0.95),
      resizeToAvoidBottomInset:
          false, // Prevent resizing, we handle layout manually
      body: SafeArea(
        child: Stack(
          children: [
            // 1. THE CARDS (Animate up slightly when keyboard opens)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              top: isKeyboardVisible ? 20 : 0,
              bottom: isKeyboardVisible
                  ? MediaQuery.of(context).viewInsets.bottom + 20
                  : 0,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  height: isKeyboardVisible
                      ? null // Take available space
                      : MediaQuery.of(context).size.height * 0.75,
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    physics: isKeyboardVisible
                        ? const NeverScrollableScrollPhysics() // Lock swipe while typing
                        : const BouncingScrollPhysics(),
                    children: [
                      NoteReviewCard(
                        key: _noteCardKey,
                        text: widget.rawText,
                      ),
                      StructuredReviewCard(
                        key: _structuredCardKey,
                        text: widget.rawText,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. PATH INDICATOR (Fades out when keyboard opens)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isKeyboardVisible ? 0.0 : 1.0,
              child: Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Text(
                    _currentPage == 0
                        ? "PATH: UNSTRUCTURED NOTE"
                        : "PATH: SMART STRUCTURE",
                    style: TextStyle(
                      color: colors.highlight.withOpacity(0.5),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),

            // 3. TOP CONTROLS (Slide Up Animation)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: isKeyboardVisible ? -100 : 20, // Move off-screen
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: colors.textMain, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                  IconButton(
                    icon: Icon(Icons.camera_alt,
                        color: colors.textMain, size: 30),
                    onPressed: widget.onRetake,
                  ),
                ],
              ),
            ),

            // 4. BOTTOM CONTROLS (Slide Down Animation)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: isKeyboardVisible ? -100 : 20, // Move off-screen
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Delete Selected
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: colors.priorityHigh,
                        size: 35), // Using Theme Color
                    onPressed: () {
                      // Logic to clear/reset can be added here
                    },
                  ),
                  // Send Button
                  GestureDetector(
                    onTap: _handleSend,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.highlight,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colors.bgMain.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: Icon(Icons.send,
                          color: colors.textHighlighted, size: 30),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
