import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import 'package:task_manager_app/core/services/auth_service.dart';
import 'package:task_manager_app/core/services/storage_service.dart';

// --- WIDGETS ---
import '../../../core/widgets/profile_bubble.dart';
import 'theme_settings_page.dart';
import 'notification_settings_page.dart';
import 'habit_settings_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _handleSignOut(BuildContext context) async {
    await StorageService.instance.closeUserBoxes();
    await AuthService.instance.signOut();
  }

  // --- NEW: Handle Sign In from Settings ---
  Future<void> _handleSignIn(BuildContext context) async {
    try {
      final user = await AuthService.instance.signInWithGoogle();
      if (user != null) {
        // Since the user is now authenticated, the AuthWrapper stream
        // will automatically detect the change and rebuild the app,
        // loading their specific database ID.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Successfully Signed In!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final user = AuthService.instance.currentUser;
    final bool isGuest = user == null; // Determine if user is in Guest Mode

    return Scaffold(
      backgroundColor: colors.bgMain,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // App Bar with Back Button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Profile Section
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          // 1. Profile Bubble (Displays Name internally)
                          ProfileBubble(
                            colors: colors,
                            userName: isGuest
                                ? "Guest User"
                                : user.displayName ?? "User",
                          ),

                          const SizedBox(height: 5),

                          // 2. Email Display OR Guest Prompt
                          Text(
                            isGuest ? "Local Offline Mode" : user.email ?? "",
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 14,
                            ),
                          ),

                          // Optional: Add a subtle prompt for guests to backup data
                          if (isGuest) ...[
                            const SizedBox(height: 8),
                            Text(
                              "Sign in to backup your data to the cloud.",
                              style: TextStyle(
                                color: colors.highlight,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // GENERAL SETTINGS
                    _buildSectionHeader("General", colors),
                    _buildTile(
                      icon: Icons.palette,
                      title: "Appearance",
                      colors: colors,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ThemeSettingsPage()),
                        );
                      },
                    ),
                    _buildTile(
                      icon: Icons.notifications,
                      title: "Notifications",
                      colors: colors,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const NotificationSettingsPage()),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // PAGES
                    _buildSectionHeader("Pages", colors),
                    _buildTile(
                      icon: Icons.repeat,
                      title: "Habits",
                      colors: colors,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const HabitSettingsPage()),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // ACCOUNT - Dynamic Button
                    _buildSectionHeader("Account", colors),
                    if (isGuest)
                      _buildTile(
                        icon: Icons.login,
                        title: "Sign In with Google",
                        colors: colors,
                        onTap: () => _handleSignIn(context),
                      )
                    else
                      _buildTile(
                        icon: Icons.logout,
                        title: "Sign Out",
                        colors: colors,
                        onTap: () => _handleSignOut(context),
                      ),

                    // Add extra padding so the nav bar doesn't block the last item
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required AppColors colors,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.bgMiddle,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(icon, color: colors.textMain),
        title: Text(
          title,
          style: TextStyle(color: colors.textMain, fontWeight: FontWeight.w600),
        ),
        trailing: Icon(Icons.arrow_forward_ios,
            size: 16, color: colors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
