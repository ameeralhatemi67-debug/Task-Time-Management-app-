import 'package:flutter/material.dart';

// -----------------------------------------------------------------------------
// 1. DATA MODELS & ENUMS
// -----------------------------------------------------------------------------

/// Defines the category of the chip for icon/color logic
/// Added: [location] for places, [split] for multi-intent detection
enum ChipType { focus, habit, priority, time, location, folder, date, split }

/// Defines the visual appearance and interaction state
enum ChipVisualState {
  suggested, // Transparent with '?' (e.g. "Work?") - Low/Med Confidence
  confirmed, // Solid/Tinted (e.g. "Work") - High Confidence
  dismissible, // "Work?" with a floating 'X' button - After 3 seconds
}

/// A data holder for chips in the Review Card (Controller Pattern)
class ChipCandidate {
  final String id;
  final ChipType type;
  final String label;
  final IconData icon;
  final dynamic value; // Stores the actual data (e.g., DateTime, int minutes)

  // Confidence Score (0.0 - 1.0)
  // Used to determine initial visual state or sorting
  final double confidence;

  // Mutable State
  ChipVisualState state;
  bool isAccepted;

  ChipCandidate({
    required this.id,
    required this.type,
    required this.label,
    required this.icon,
    this.value,
    this.confidence = 1.0, // Default to high confidence
    this.state = ChipVisualState.suggested,
    this.isAccepted = false,
  });
}

// -----------------------------------------------------------------------------
// 2. UNIVERSAL WIDGET
// -----------------------------------------------------------------------------

class UniversalSmartChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final ChipVisualState state;
  final VoidCallback onTap;
  final VoidCallback? onDelete; // Required if state becomes dismissible

  const UniversalSmartChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.state,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Determine Visuals based on State
    final isConfirmed = state == ChipVisualState.confirmed;
    final isDismissible = state == ChipVisualState.dismissible;

    // Suggested/Dismissible are "Ghost" style (outlined/transparent)
    // Confirmed is "Solid" style
    final isGhost = !isConfirmed;

    // Visual Props - Refined for better "Ghost" feel
    // Ghost: Very transparent BG (0.05), Visible Border (0.4), Slightly faded text (0.8)
    // Confirmed: Richer BG (0.2), No Border, Solid Text (1.0)
    final bg = isGhost ? color.withOpacity(0.05) : color.withOpacity(0.2);
    final border = isGhost ? color.withOpacity(0.4) : Colors.transparent;
    final textColor = isGhost ? color.withOpacity(0.8) : color;

    String displayText = label;
    // Add '?' for suggestions (unless it's dismissible, usually we keep it or change it)
    if (state == ChipVisualState.suggested) {
      displayText += "?";
    }

    Widget chipContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // FIX: Use the 'textColor' variable here
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          // FIX: Use the 'textColor' variable here
          Text(
            displayText,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold, // Always bold for readability
            ),
          ),
        ],
      ),
    );

    // Wrap in Tap Detector
    Widget interactiveChip = GestureDetector(
      onTap: onTap,
      child: chipContent,
    );

    // 2. Add Floating 'X' if Dismissible
    // This allows the user to reject a suggestion explicitly
    if (isDismissible) {
      return Stack(
        clipBehavior: Clip.none, // Allow X to float outside bounds
        children: [
          interactiveChip,
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 2)
                    ]),
                child: const Icon(Icons.close, size: 10, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    }

    return interactiveChip;
  }
}
