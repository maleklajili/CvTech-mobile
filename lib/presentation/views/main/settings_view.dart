import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/core/config/network_config.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/core/l10n/app_localizations.dart';
import 'package:cv_tech/core/services/sound_service.dart';
import 'package:cv_tech/presentation/views_models/app/locale_view_model.dart';
import 'package:cv_tech/presentation/views_models/app/theme_view_model.dart';
import 'package:cv_tech/theme/app_theme.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  // Only the three languages used in the app
  static const _languageLabels = {
    'fr': 'Français',
    'en': 'English',
    'ar': 'العربية',
  };

  bool _notifSoundEnabled = true;
  bool _msgSoundEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSoundPrefs();
  }

  Future<void> _loadSoundPrefs() async {
    await SoundService.instance.init();
    if (mounted) {
      setState(() {
        _notifSoundEnabled = SoundService.instance.notifEnabled;
        _msgSoundEnabled = SoundService.instance.msgEnabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeVm = context.watch<ThemeViewModel>();
    final localeVm = context.watch<LocaleViewModel>();
    final t = AppLocalizations.of(context);
    final isDark = !AppTheme.isLight;

    return Scaffold(
      appBar: AppBar(title: Text(t.settings)),
      body: ListView(
        children: [
          // ── Apparence ────────────────────────────────────────────────
          _sectionHeader(context, Icons.palette_outlined, 'Apparence'),
          _buildThemeTile(
            context,
            isDark: isDark,
            label: t.lightMode,
            icon: Icons.light_mode_outlined,
            value: ThemeMode.light,
            group: themeVm.themeMode,
            onTap: () => themeVm.setTheme(ThemeMode.light),
          ),
          _buildThemeTile(
            context,
            isDark: isDark,
            label: t.darkMode,
            icon: Icons.dark_mode_outlined,
            value: ThemeMode.dark,
            group: themeVm.themeMode,
            onTap: () => themeVm.setTheme(ThemeMode.dark),
          ),
          _buildThemeTile(
            context,
            isDark: isDark,
            label: t.systemMode,
            icon: Icons.settings_brightness_outlined,
            value: ThemeMode.system,
            group: themeVm.themeMode,
            onTap: () => themeVm.setTheme(ThemeMode.system),
          ),

          // ── Langue ───────────────────────────────────────────────────
          _sectionHeader(context, Icons.language_outlined, t.language),
          ..._languageLabels.entries.map(
            (entry) => _buildLangTile(
              context,
              isDark: isDark,
              langCode: entry.key,
              label: entry.value,
              selected: localeVm.locale.languageCode == entry.key,
              onTap: () => localeVm.setLocale(entry.key),
            ),
          ),

          // ── Sons ─────────────────────────────────────────────────────
          _sectionHeader(context, Icons.volume_up_outlined, 'Sons'),
          _buildSoundTile(
            context,
            isDark: isDark,
            icon: Icons.notifications_outlined,
            label: 'Son des notifications',
            subtitle: 'Double bip à chaque nouvelle notification',
            value: _notifSoundEnabled,
            onChanged: (v) async {
              await SoundService.instance.setNotifEnabled(v);
              setState(() => _notifSoundEnabled = v);
              if (v) SoundService.instance.playNotification();
            },
          ),
          _buildSoundTile(
            context,
            isDark: isDark,
            icon: Icons.chat_bubble_outline,
            label: 'Son des messages',
            subtitle: 'Bip à chaque message reçu',
            value: _msgSoundEnabled,
            onChanged: (v) async {
              await SoundService.instance.setMsgEnabled(v);
              setState(() => _msgSoundEnabled = v);
              if (v) SoundService.instance.playMessage();
            },
          ),

          // ── Interface ────────────────────────────────────────────────
          _sectionHeader(context, Icons.info_outline, t.feedbackUiGlobal),
          ListTile(
            leading: Icon(Icons.info_outline,
                color: isDark ? Colors.grey[400] : Colors.grey[600]),
            title: Text(t.alertsThemeInfo),
          ),

          // ── Réseau ───────────────────────────────────────────────────
          const _NetworkConfigSection(),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryColor),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeTile(
    BuildContext context, {
    required bool isDark,
    required String label,
    required IconData icon,
    required ThemeMode value,
    required ThemeMode group,
    required VoidCallback onTap,
  }) {
    final selected = value == group;
    return ListTile(
      leading: Icon(icon,
          color: selected ? AppColors.primaryColor : AppTheme.textMutedColor),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          color: selected ? AppColors.primaryColor : AppTheme.textColor,
        ),
      ),
      trailing: selected
          ? Icon(Icons.check_circle_rounded,
              color: AppColors.primaryColor, size: 20)
          : Icon(Icons.circle_outlined,
              color: AppTheme.textMutedColor, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildLangTile(
    BuildContext context, {
    required bool isDark,
    required String langCode,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: selected
            ? AppColors.primaryColor
            : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
        child: Text(
          langCode.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : AppTheme.textMutedColor,
          ),
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          color: selected ? AppColors.primaryColor : AppTheme.textColor,
        ),
      ),
      trailing: selected
          ? Icon(Icons.check_circle_rounded,
              color: AppColors.primaryColor, size: 20)
          : null,
      onTap: onTap,
    );
  }

  Widget _buildSoundTile(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: value
              ? AppColors.primaryColor.withValues(alpha: 0.12)
              : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            color: value ? AppColors.primaryColor : AppTheme.textMutedColor,
            size: 20),
      ),
      title: Text(label,
          style: TextStyle(
            fontWeight: value ? FontWeight.w600 : FontWeight.normal,
            color: AppTheme.textColor,
          )),
      subtitle: Text(subtitle,
          style:
              TextStyle(fontSize: 12, color: AppTheme.textMutedColor)),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primaryColor,
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
