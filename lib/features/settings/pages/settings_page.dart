import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import 'package:task_manager_app/core/services/auth_service.dart';
import 'package:task_manager_app/core/services/storage_service.dart';

// --- WIDGETS ---
import '../../../core/widgets/profile_bubble.dart';
import 'theme_settings_page.dart';
import 'notification_settings_page.dart';
import 'habit_settings_page.dart'; // <--- UNCOMMENTED

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _handleSignOut(BuildContext context) async {
    // FIX: Changed from closeBoxes() to closeUserBoxes()
    await StorageService.instance.closeUserBoxes();
    await AuthService.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final user = AuthService.instance.currentUser;

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
                            userName: user?.displayName ?? "User",
                            // Removed 'showName' and 'radius' to match existing widget
                          ),

                          // 2. Removed Duplicate Name Text
                          // The ProfileBubble already shows the name, so we removed the
                          // extra Text widget here to prevent repetition.

                          const SizedBox(height: 5),

                          // 3. Email Display
                          Text(
                            user?.email ?? "",
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
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

                    // PAGES (NEW SECTION)
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

                    // ACCOUNT
                    _buildSectionHeader("Account", colors),
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
