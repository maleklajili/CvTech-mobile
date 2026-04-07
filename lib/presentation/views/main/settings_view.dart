import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/core/config/network_config.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
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
          const Divider(),
          // ── Network Configuration ───────────────────────────────────────
          const _NetworkConfigSection(),
        ],
      ),
    );
  }
}

/// Standalone stateful section for configuring the backend server URL.
/// This lets the user update the IP when their machine's address changes.
class _NetworkConfigSection extends StatefulWidget {
  const _NetworkConfigSection();

  @override
  State<_NetworkConfigSection> createState() => _NetworkConfigSectionState();
}

class _NetworkConfigSectionState extends State<_NetworkConfigSection> {
  final TextEditingController _urlController = TextEditingController();
  bool _saving = false;
  String? _savedMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentUrl();
  }

  Future<void> _loadCurrentUrl() async {
    final url = await NetworkConfig.getBackendUrl();
    if (mounted) {
      _urlController.text = url;
    }
  }

  Future<void> _save() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _saving = true;
      _savedMessage = null;
    });
    await NetworkConfig.setCustomBackendUrl(url);
    if (mounted) {
      setState(() {
        _saving = false;
        _savedMessage = 'URL sauvegardée';
      });
    }
  }

  Future<void> _reset() async {
    await NetworkConfig.resetToDefault();
    await _loadCurrentUrl();
    if (mounted) {
      setState(() => _savedMessage = 'Réinitialisé');
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configuration serveur',
            style: TextStyle(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Adresse IP de votre machine (ex: http://192.168.1.x:9000)',
            style: TextStyle(fontSize: 12, color: AppColors.textMutedColor),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    hintText: 'http://192.168.1.104:9000',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _saving
                  ? const SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: const Icon(Icons.save_outlined,
                          color: AppColors.primaryColor),
                      tooltip: 'Sauvegarder',
                      onPressed: _save,
                    ),
            ],
          ),
          if (_savedMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _savedMessage!,
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 4),
          TextButton.icon(
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Réinitialiser par défaut'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: AppColors.textMutedColor,
              textStyle: const TextStyle(fontSize: 12),
            ),
            onPressed: _reset,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
