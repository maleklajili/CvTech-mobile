// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import '../../../core/utils/preferences/theme_preference.dart';
import '../base/base_view_model.dart';

class ThemeViewModel extends BaseViewModel {
  ThemeMode themeMode;

  ThemeViewModel(super.context, this.themeMode);

  void setTheme(ThemeMode? mode) async {
    if (mode != null) {
      themeMode = mode;
      print(mode);
      await ThemePreference.shared.save(mode);
      update();
    }
  }
}
