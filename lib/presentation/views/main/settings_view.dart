import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/core/l10n/app_localizations.dart';
import 'package:cv_tech/presentation/views_models/app/locale_view_model.dart';
import 'package:cv_tech/presentation/views_models/app/theme_view_model.dart';
import 'package:cv_tech/theme/app_theme.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  static const _languageLabels = {
    'fr': 'Français',
    'en': 'English',
    'ar': 'العربية',
    'es': 'Español',
    'de': 'Deutsch',
  };

  @override
  Widget build(BuildContext context) {
    final themeVm = context.watch<ThemeViewModel>();
    final localeVm = context.watch<LocaleViewModel>();
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.settings),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(t.lightMode),
            trailing: Radio<ThemeMode>(
              value: ThemeMode.light,
              groupValue: themeVm.themeMode,
              onChanged: (_) => themeVm.setTheme(ThemeMode.light),
            ),
          ),
          ListTile(
            title: Text(t.darkMode),
            trailing: Radio<ThemeMode>(
              value: ThemeMode.dark,
              groupValue: themeVm.themeMode,
              onChanged: (_) => themeVm.setTheme(ThemeMode.dark),
            ),
          ),
          ListTile(
            title: Text(t.systemMode),
            trailing: Radio<ThemeMode>(
              value: ThemeMode.system,
              groupValue: themeVm.themeMode,
              onChanged: (_) => themeVm.setTheme(ThemeMode.system),
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              t.language,
              style: TextStyle(
                color: AppTheme.textMutedColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          ..._languageLabels.entries.map((entry) => ListTile(
                title: Text(entry.value),
                trailing: Radio<String>(
                  value: entry.key,
                  groupValue: localeVm.locale.languageCode,
                  onChanged: (val) {
                    if (val != null) localeVm.setLocale(val);
                  },
                ),
              )),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              t.feedbackUiGlobal,
              style: TextStyle(
                color: AppTheme.textMutedColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(t.alertsThemeInfo),
          ),
        ],
      ),
    );
  }
}
