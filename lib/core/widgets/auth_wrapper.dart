import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:task_manager_app/core/services/auth_service.dart';
import 'package:task_manager_app/core/services/storage_service.dart';
import 'package:task_manager_app/core/widgets/main_scaffold.dart';
import 'package:task_manager_app/features/auth/pages/login_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        // 1. Loading State (Checking auth)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final User? user = snapshot.data;

        // 2. User is Logged Out -> Show Login Page
        if (user == null) {
          return const LoginPage();
        }

        // 3. User is Logged In -> Initialize Storage & Show App
        return FutureBuilder(
          // Pass the User ID to open specific boxes (e.g. "user123_tasks")
          future: StorageService.instance.openUserBoxes(user.uid),
          builder: (context, storageSnap) {
            // A. Check for ERRORS first
            if (storageSnap.hasError) {
              return Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 48),
                        const SizedBox(height: 20),
                        const Text(
                          "Database Initialization Failed",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Error: ${storageSnap.error}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            // Retry logic (Trigger rebuild)
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AuthWrapper()),
                            );
                          },
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // B. Still Loading
            if (storageSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // C. Storage is ready -> Launch Main App
            return const MainScaffold();
          },
        );
      },
    );
  }
}
