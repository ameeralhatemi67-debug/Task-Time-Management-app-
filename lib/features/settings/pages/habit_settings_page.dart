import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';
import 'package:task_manager_app/data/repositories/habit_repository.dart';

class HabitSettingsPage extends StatefulWidget {
  const HabitSettingsPage({super.key});

  @override
  State<HabitSettingsPage> createState() => _HabitSettingsPageState();
}

class _HabitSettingsPageState extends State<HabitSettingsPage> {
  final HabitRepository _repo = HabitRepository();
  int _dailyGoal = 3;

  // State for toggles
  bool _isStreakGlobal = true;
  bool _showStreakCounter = true;
  bool _showHabitBadges = true; // NEW

  @override
  void initState() {
    super.initState();
    _dailyGoal = _repo.getDailyGoal();
    // Fetch settings from Repo
    _isStreakGlobal = _repo.getStreakMode();
    _showStreakCounter = _repo.getShowStreakCounter();
    _showHabitBadges = _repo.getShowHabitBadges(); // NEW
  }

  void _saveGoal(int newGoal) {
    setState(() => _dailyGoal = newGoal);
    _repo.setDailyGoal(newGoal);
  }

  // Toggle Handlers
  void _toggleStreakMode(bool val) {
    setState(() => _isStreakGlobal = val);
    _repo.setStreakMode(val);
  }

  void _toggleShowCounter(bool val) {
    setState(() => _showStreakCounter = val);
    _repo.setShowStreakCounter(val);
  }

  // NEW HANDLER
  void _toggleShowBadges(bool val) {
    setState(() => _showHabitBadges = val);
    _repo.setShowHabitBadges(val);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: colors.bgMain,
      appBar: AppBar(
        backgroundColor: colors.bgMain,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Habit Settings",
          style: TextStyle(color: colors.textMain, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADING 1
            Text(
              "Daily Streak Goal",
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 15),

            // CARD 1 (Slider)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.bgMiddle,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_fire_department,
                          color: colors.priorityMedium, size: 30),
                      const SizedBox(width: 10),
                      Text(
                        "$_dailyGoal Habits / Day",
                        style: TextStyle(
                          color: colors.textMain,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "How many habits do you want to complete to keep your streak alive?",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 30),

                  // SLIDER
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: colors.highlight,
                      inactiveTrackColor: colors.bgBottom,
                      thumbColor: colors.textHighlighted,
                      overlayColor: colors.highlight.withOpacity(0.2),
                      trackHeight: 6.0,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 12.0),
                    ),
                    child: Slider(
                      value: _dailyGoal.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: "$_dailyGoal",
                      onChanged: (val) => _saveGoal(val.toInt()),
                    ),
                  ),

                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("1", style: TextStyle(color: colors.textSecondary)),
                      Text("10", style: TextStyle(color: colors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // HEADING 2
            Text(
              "Appearance & Logic",
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 15),

            // CARD 2 (Toggles)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.bgMiddle,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  // Global Mode
                  _buildSwitchTile(
                    colors: colors,
                    icon: Icons.public,
                    title: "Global Streak Mode",
                    subtitle: "Count habits from all folders",
                    value: _isStreakGlobal,
                    onChanged: _toggleStreakMode,
                  ),
                  Divider(
                      color: colors.textSecondary.withOpacity(0.1), height: 30),

                  // Show Counter
                  _buildSwitchTile(
                    colors: colors,
                    icon: Icons.numbers,
                    title: "Show Counter",
                    subtitle: "Display '1/3' under streak rings",
                    value: _showStreakCounter,
                    onChanged: _toggleShowCounter,
                  ),
                  Divider(
                      color: colors.textSecondary.withOpacity(0.1), height: 30),

                  // Show Badges (NEW)
                  _buildSwitchTile(
                    colors: colors,
                    icon: Icons.sell_outlined,
                    title: "Show Card Details",
                    subtitle: "Display focus time, reminders, etc.",
                    value: _showHabitBadges,
                    onChanged: _toggleShowBadges,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required AppColors colors,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.bgTop,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: colors.textMain, size: 20),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colors.textMain,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeColor: colors.highlight,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
