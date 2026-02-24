import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:task_manager_app/core/services/notification_service.dart';
import 'package:task_manager_app/core/theme/theme_controller.dart';
import 'package:task_manager_app/core/widgets/auth_wrapper.dart';

// --- Services ---
import 'core/services/storage_service.dart';

void main() async {
  // 1. Ensure Flutter bindings are ready
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase
  // This fixes the "[core/no-app] No Firebase App" crash.
  // The AuthService accesses FirebaseAuth, so this must run before the UI builds.
  await Firebase.initializeApp();

  // 3. Initialize Database Core (Adapters & Prefs)
  await StorageService.instance.initialize();

  // 4. CRITICAL FIX: Open the specific User Boxes
  // Since we don't have Auth yet, we use a static ID 'default_user'.
  // In the future, this moves to a Login Screen.
  await StorageService.instance.openUserBoxes('default_user');

  await NotificationService().init(); // <--- ADD THIS LINE

  // 5. Run App
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to ThemeController for light/dark mode changes
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, child) {
        final controller = ThemeController.instance;

        return MaterialApp(
          title: 'Time & Task App',
          debugShowCheckedModeBanner: false,

          // Theme Mode (Light/Dark/System)
          themeMode: controller.currentMode,

          // --- LIGHT THEME ---
          theme: ThemeData.light().copyWith(
            scaffoldBackgroundColor:
                controller.currentLightColors.bgMain, // Global Background
            extensions: <ThemeExtension<dynamic>>[
              controller.currentLightColors,
            ],
          ),

          // --- DARK THEME ---
          darkTheme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor:
                controller.currentDarkColors.bgMain, // Global Background
            extensions: <ThemeExtension<dynamic>>[controller.currentDarkColors],
          ),

          // Point to our new Navigation Shell
          home: const AuthWrapper(),
        );
      },
    );
  }
}
