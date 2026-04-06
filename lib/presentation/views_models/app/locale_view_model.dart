import 'package:flutter/material.dart';
import 'package:cv_tech/core/utils/preferences/locale_preference.dart';
import '../base/base_view_model.dart';

class LocaleViewModel extends BaseViewModel {
  Locale _locale;

  LocaleViewModel(super.context, String langCode)
      : _locale = Locale(langCode);

  Locale get locale => _locale;

  void setLocale(String langCode) async {
    _locale = Locale(langCode);
    await LocalePreference.shared.save(langCode);
    update();
  }
}
