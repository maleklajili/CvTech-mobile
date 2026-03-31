import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cv_tech/data/models/profile/cv_theme_model.dart';

class CvThemeViewModel extends ChangeNotifier {
  static const String _storageKey = 'cv_theme';

  CvThemeModel _theme = CvThemeModel.classic;
  int _selectedPresetIndex = 0;
  bool _showColorPicker = false;

  CvThemeModel get theme => _theme;
  int get selectedPresetIndex => _selectedPresetIndex;
  bool get showColorPicker => _showColorPicker;

  CvThemeViewModel() {
    _loadFromPrefs();
  }

  void selectPreset(int index) {
    if (index < 0 || index >= CvThemeModel.presets.length) return;
    _selectedPresetIndex = index;
    _theme = CvThemeModel.presets[index].theme;
    _saveToPrefs();
    notifyListeners();
  }

  void setPrimaryColor(Color color) {
    _theme = _theme.copyWith(
      primaryColor: color,
      headerBgColor: color,
      sectionTitleColor: color,
    );
    _selectedPresetIndex = -1;
    _saveToPrefs();
    notifyListeners();
  }

  void setAccentColor(Color color) {
    _theme = _theme.copyWith(
      accentColor: color,
      skillBarColor: color,
    );
    _selectedPresetIndex = -1;
    _saveToPrefs();
    notifyListeners();
  }

  void toggleColorPicker() {
    _showColorPicker = !_showColorPicker;
    notifyListeners();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_storageKey);
      if (json != null) {
        final data = jsonDecode(json) as Map<String, dynamic>;
        _theme = CvThemeModel.fromJson(data['theme'] as Map<String, dynamic>);
        _selectedPresetIndex = data['presetIndex'] as int? ?? -1;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode({
          'theme': _theme.toJson(),
          'presetIndex': _selectedPresetIndex,
        }),
      );
    } catch (_) {}
  }
}
