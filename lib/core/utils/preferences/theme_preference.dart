// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Project imports:
import '../../constants/constants.dart';
import 'base/base_preference.dart';

class ThemePreference extends BasePreference<ThemeMode?> {
  // SINGLETON ----------------------------------------------------------------

  static final ThemePreference _instance = ThemePreference._();

  static ThemePreference get shared => _instance;

  ThemePreference._();

  // END SINGLETON ------------------------------------------------------------

  @override
  String get key => selectedThemePreferenceKey;

  @override
  Future<ThemeMode?> load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return ThemeMode.values.firstWhereOrNull(
          (e) => e.name == prefs.getString(key),
        ) ??
        kDefaultTheme;
  }

  @override
  Future<bool> save(ThemeMode? value) async {
    return await (await SharedPreferences.getInstance())
        .setString(key, value!.name);
  }
}
