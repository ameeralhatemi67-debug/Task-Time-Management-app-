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

  // KEY TO ACCESS NOTE CARD STATE
  final GlobalKey<NoteReviewCardState> _noteCardKey = GlobalKey();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // --- SAVE LOGIC ---
  Future<void> _handleSend() async {
    // 1. If on Note Page, save Note
    if (_currentPage == 0) {
      if (_noteCardKey.currentState != null) {
        await _noteCardKey.currentState!.saveNoteToRepo();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Note saved successfully!")),
          );
          Navigator.pop(context); // Close Overlay
        }
      }
    }
    // 2. If on Structure Page (Future Implementation)
    else {
      // Future Logic for Pillars 1-3
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Structure Save coming soon!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    // KEYBOARD DETECTION logic
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: colors.bgMain.withOpacity(0.95),
      // Prevent the scaffold from resizing (squishing cards) when keyboard opens
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. CARDS (Moved up slightly when keyboard is open to keep focus)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              top: isKeyboardVisible ? 20 : 0, // Slight shift
              bottom: isKeyboardVisible
                  ? MediaQuery.of(context).viewInsets.bottom + 20
                  : 0,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  // When keyboard is open, let the card take available space
                  height: isKeyboardVisible
                      ? null
                      : MediaQuery.of(context).size.height * 0.75,
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    physics: isKeyboardVisible
                        ? const NeverScrollableScrollPhysics() // Lock swipe while typing
                        : const BouncingScrollPhysics(),
                    children: [
                      // Pass the Key to the Note Card
                      NoteReviewCard(key: _noteCardKey, text: widget.rawText),
                      StructuredReviewCard(text: widget.rawText),
                    ],
                  ),
                ),
              ),
            ),

            // 2. PATH INDICATOR (Only visible when keyboard is CLOSED)
            if (!isKeyboardVisible)
              Positioned(
                top: 80, // Moved up to not overlap with card top
                left: 0,
                right: 0,
                child: Center(
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

            // 3. CORNER CONTROLS (Only visible when keyboard is CLOSED)
            if (!isKeyboardVisible) _buildCornerControls(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerControls(AppColors colors) {
    return Column(
      children: [
        // Top Row
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.close, color: colors.textMain, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
              IconButton(
                icon: Icon(Icons.camera_alt, color: colors.textMain, size: 30),
                onPressed: widget.onRetake,
              ),
            ],
          ),
        ),
        const Spacer(),
        // Bottom Row
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.red, size: 35),
                onPressed: () {
                  // Optional: Add logic to clear text if needed
                },
              ),
              // SEND BUTTON with Logic
              GestureDetector(
                onTap: _handleSend, // CONNECTED
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: colors.highlight,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ]),
                  child:
                      Icon(Icons.send, color: colors.textHighlighted, size: 30),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
