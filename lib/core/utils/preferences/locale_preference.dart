import 'package:shared_preferences/shared_preferences.dart';
import 'base/base_preference.dart';

const _kLocaleKey = 'SELECTED_LOCALE_KEY';
const kDefaultLocale = 'fr';

class LocalePreference extends BasePreference<String?> {
  static final LocalePreference _instance = LocalePreference._();
  static LocalePreference get shared => _instance;
  LocalePreference._();

  @override
  String get key => _kLocaleKey;

  @override
  Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key) ?? kDefaultLocale;
  }

  @override
  Future<bool> save(String? value) async {
    return await (await SharedPreferences.getInstance())
        .setString(key, value ?? kDefaultLocale);
  }
}
