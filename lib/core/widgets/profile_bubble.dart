import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';

class ProfileBubble extends StatelessWidget {
  final AppColors colors;
  final String userName; // NEW: Dynamic Name

  const ProfileBubble({
    super.key,
    required this.colors,
    this.userName = "User", // Default
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // 1. Progress Ring
            SizedBox(
              width: 130,
              height: 130,
              child: CircularProgressIndicator(
                value: 0.75,
                strokeWidth: 8,
                valueColor: AlwaysStoppedAnimation<Color>(colors.done),
                backgroundColor: colors.undone,
              ),
            ),

            // 2. Avatar Circle
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: colors.bgTop,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                Icons.person,
                size: 50,
                color: colors.textSecondary.withOpacity(0.5),
              ),
            ),

            // 3. Level Badge
            Positioned(
              bottom: 0,
              child: Transform.rotate(
                angle: 0.785,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: colors.bgMiddle,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: colors.bgMain, width: 2),
                  ),
                  child: Center(
                    child: Transform.rotate(
                      angle: -0.785,
                      child: Text(
                        "1",
                        style: TextStyle(
                          color: colors.textMain,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 15),

        // 4. Dynamic Name Text
        Text(
          userName, // display dynamic name
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colors.textMain,
          ),
        ),
      ],
    );
  }
}
