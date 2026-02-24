import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

/// Model for a single swipe action button
class SwipeOption {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const SwipeOption({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });
}

/// A wrapper around flutter_slidable to maintain your app's API structure
class SwipeableTile extends StatelessWidget {
  final Widget child;
  final String keyId; // Unique ID for keying
  final List<SwipeOption> leadingOptions; // Left-side actions (Start)
  final List<SwipeOption> trailingOptions; // Right-side actions (End)

  const SwipeableTile({
    super.key,
    required this.child,
    required this.keyId,
    this.leadingOptions = const [],
    this.trailingOptions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      // The key is essential for Slidable to track state
      key: ValueKey(keyId),

      // LEFT SIDE ACTIONS (Archive/Delete)
      startActionPane: leadingOptions.isNotEmpty
          ? ActionPane(
              motion: const ScrollMotion(),
              dismissible:
                  null, // Set this if you want swipe-to-dismiss behavior
              children: leadingOptions.map((opt) => _buildAction(opt)).toList(),
            )
          : null,

      // RIGHT SIDE ACTIONS (Pin/Move)
      endActionPane: trailingOptions.isNotEmpty
          ? ActionPane(
              motion: const ScrollMotion(),
              children:
                  trailingOptions.map((opt) => _buildAction(opt)).toList(),
            )
          : null,

      // THE CONTENT
      child: child,
    );
  }

  /// Helper to map your SwipeOption to SlidableAction
  Widget _buildAction(SwipeOption opt) {
    return SlidableAction(
      onPressed: (context) => opt.onTap(),
      backgroundColor: opt.color,
      foregroundColor: Colors.white,
      icon: opt.icon,
      label: opt.label,
      // You can adjust padding/spacing here if needed
      borderRadius: BorderRadius.zero,
    );
  }
}
