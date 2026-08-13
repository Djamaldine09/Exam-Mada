import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';

class ThemeModeNotifier extends ChangeNotifier {
  ThemeModeNotifier(this._mode);

  ThemeMode _mode;

  ThemeMode get mode => _mode;

  Future<void> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.themeModeKey);

    if (raw == null) {
      return;
    }

    _mode = ThemeMode.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => ThemeMode.system,
    );

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode newMode) async {
    if (_mode == newMode) {
      return;
    }

    _mode = newMode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.themeModeKey, newMode.name);
  }

  Future<void> toggleThemeMode() async {
    final nextMode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(nextMode);
  }
}

class ThemeModeProvider extends InheritedNotifier<ThemeModeNotifier> {
  const ThemeModeProvider({
    required ThemeModeNotifier notifier,
    required Widget child,
    super.key,
  }) : super(notifier: notifier, child: child);

  static ThemeModeNotifier of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<ThemeModeProvider>();
    assert(
        provider != null, 'Aucun ThemeModeProvider trouvé dans le contexte.');
    return provider!.notifier!;
  }
}
