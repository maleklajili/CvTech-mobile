import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/presentation/views_models/app/theme_view_model.dart';
import 'package:cv_tech/theme/app_theme.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final themeVm = context.watch<ThemeViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Mode clair'),
            trailing: Radio<ThemeMode>(
              value: ThemeMode.light,
              groupValue: themeVm.themeMode,
              onChanged: (_) => themeVm.setTheme(ThemeMode.light),
            ),
          ),
          ListTile(
            title: const Text('Mode sombre'),
            trailing: Radio<ThemeMode>(
              value: ThemeMode.dark,
              groupValue: themeVm.themeMode,
              onChanged: (_) => themeVm.setTheme(ThemeMode.dark),
            ),
          ),
          ListTile(
            title: const Text('Mode système'),
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
              'Feedback UI global',
              style: TextStyle(
                color: AppTheme.textMutedColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Alerts et toasts utilisent maintenant le thème global.'),
          ),
        ],
      ),
    );
  }
}
