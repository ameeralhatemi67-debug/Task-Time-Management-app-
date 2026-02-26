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
    // --- NEW: Listen to Guest State ---
    return StreamBuilder<bool>(
        stream: AuthService.instance.guestStateChanges,
        initialData: false,
        builder: (context, guestSnapshot) {
          final bool isGuest = guestSnapshot.data ?? false;

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

              // 2. User is Logged Out AND Not a Guest -> Show Login Page
              if (user == null && !isGuest) {
                return const LoginPage();
              }

              // --- NEW: Determine Storage ID (UID or Default for Guest) ---
              final String storageId = user?.uid ?? 'default_user';

              // 3. User is Logged In OR Guest -> Initialize Storage & Show App
              return FutureBuilder(
                // Pass the Storage ID to open specific boxes
                future: StorageService.instance.openUserBoxes(storageId),
                builder: (context, storageSnap) {
                  // A. Check for ERRORS first (Kept exactly as you built it)
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
        });
  }
}
