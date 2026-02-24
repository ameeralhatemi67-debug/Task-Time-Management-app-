import 'package:flutter/material.dart';
import 'package:task_manager_app/core/theme/colorsettings.dart';

class ThemeController extends ChangeNotifier {
  // Singleton approach for simplicity in this stage
  static final ThemeController instance = ThemeController._();
  ThemeController._();

  // 1. Data Source
  List<ThemePreset> availableThemes = [ThemePreset.original()];
  String _activeThemeId = 'original';

  // 2. State
  ThemeMode currentMode = ThemeMode.dark;

  // 3. Getters
  ThemePreset get currentTheme => availableThemes.firstWhere(
        (t) => t.id == _activeThemeId,
        orElse: () => availableThemes.first,
      );

  AppColors get currentLightColors => currentTheme.lightColors;
  AppColors get currentDarkColors => currentTheme.darkColors;

  // 4. Actions
  void toggleMode() {
    currentMode =
        currentMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setActiveTheme(String id) {
    _activeThemeId = id;
    notifyListeners();
  }

  void addTheme(ThemePreset newTheme) {
    availableThemes.add(newTheme);
    _activeThemeId = newTheme.id; // Auto-switch to new theme
    notifyListeners();
  }

  void updateTheme(ThemePreset updatedTheme) {
    final index = availableThemes.indexWhere((t) => t.id == updatedTheme.id);
    if (index != -1 && !availableThemes[index].isLocked) {
      availableThemes[index] = updatedTheme;
      notifyListeners();
    }
  }

  void deleteTheme(String id) {
    final theme = availableThemes.firstWhere((t) => t.id == id);
    if (theme.isLocked) return; // Cannot delete original

    availableThemes.removeWhere((t) => t.id == id);
    if (_activeThemeId == id) {
      _activeThemeId = 'original'; // Fallback
    }
    notifyListeners();
  }
}
