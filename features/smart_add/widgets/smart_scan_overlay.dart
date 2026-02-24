import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';

class SmartScanOverlay extends StatelessWidget {
  const SmartScanOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Container(
      color: colors.bgMain.withOpacity(0.8), // Dim the background
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
          decoration: BoxDecoration(
            color: colors.bgMiddle,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Satistfying Circular Progress
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  color: colors.highlight,
                  strokeWidth: 5,
                  strokeCap: StrokeCap.round,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "AI is thinking...",
                style: TextStyle(
                  color: colors.textMain,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "Extracting your tasks",
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
