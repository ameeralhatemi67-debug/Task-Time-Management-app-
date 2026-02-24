import 'package:flutter/material.dart';
import 'package:task_manager_app/core/services/auth_service.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      // 1. Attempt Sign In
      final user = await AuthService.instance.signInWithGoogle();

      // 2. If null, it means it failed (or was canceled)
      if (user == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Login Failed. Check console for error details."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // 3. Catch unexpected errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access your semantic colors
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: colors.bgMain,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. LOGO / BRANDING
              Icon(Icons.check_circle_outline,
                  size: 80, color: colors.highlight),
              const SizedBox(height: 20),
              Text(
                "Task Master",
                style: TextStyle(
                  color: colors.textMain,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Focus. Organize. Achieve.",
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 60),

              // 2. GOOGLE SIGN IN BUTTON
              _isLoading
                  ? CircularProgressIndicator(color: colors.highlight)
                  : SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.bgMiddle,
                          foregroundColor: colors.textMain,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(color: colors.bgBottom),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.login, size: 24),
                        // Note: In a real app, use a proper Google G logo asset
                        label: const Text(
                          "Continue with Google",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _handleGoogleSignIn,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
