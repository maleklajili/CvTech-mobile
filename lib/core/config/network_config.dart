import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

/// Configuration réseau dynamique qui s'adapte automatiquement
/// et permet de changer l'URL backend sans recompiler
class NetworkConfig {
  static const String _backendUrlKey = 'backend_url';
  static const String _useCustomUrlKey = 'use_custom_url';
  static const bool useHostedBackendByDefault = false;
  
  // URLs par défaut selon la plateforme
  static const String defaultWebUrl = 'http://localhost:9000';
  static const String defaultAndroidEmulatorUrl = 'http://10.0.2.2:9000';
  static const String defaultRealDeviceUrl = 'http://192.168.1.104:9000';
  static const String defaultIOSUrl = 'http://127.0.0.1:9000';
  static const String defaultHostedUrl =
      'https://e72d-196-229-218-90.ngrok-free.app';
  static const String defaultSocketPort = '6000';
  
  static String? _cachedUrl;
  static bool? _cachedUseCustom;

  static bool _isLegacyHostedUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('ngrok') || lower.contains('ngrok-free.app');
  }

  static bool _isAndroidInvalidLocalBackendUrl(String url) {
    if (kIsWeb || !Platform.isAndroid) return false;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return uri.host == 'localhost' ||
        uri.host == '127.0.0.1' ||
        uri.host == '10.0.2.2';
  }
  
  /// Obtenir l'URL du backend selon la plateforme
  static Future<String> getBackendUrl() async {
    if (useHostedBackendByDefault) {
      return defaultHostedUrl;
    }

    // Utiliser le cache si disponible, mais invalider les anciennes valeurs
    // non joignables sur Android réel ou legacy hosted URL.
    if (_cachedUrl != null && _cachedUseCustom == true) {
      final cachedUrl = _cachedUrl!;
      final mustInvalidateCached =
          _isLegacyHostedUrl(cachedUrl) ||
          _isAndroidInvalidLocalBackendUrl(cachedUrl);

      if (!mustInvalidateCached) {
        return cachedUrl;
      }

      _cachedUrl = null;
      _cachedUseCustom = null;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final useCustomUrl = prefs.getBool(_useCustomUrlKey) ?? false;
    final customUrl = prefs.getString(_backendUrlKey);

    // Migration: si le mode hébergé est désactivé, ignorer les anciennes URLs ngrok
    // enregistrées pour éviter les erreurs SSL inattendues.
    if (!useHostedBackendByDefault &&
        useCustomUrl &&
        customUrl != null &&
        _isLegacyHostedUrl(customUrl)) {
      await prefs.setBool(_useCustomUrlKey, false);
      await prefs.remove(_backendUrlKey);
      _cachedUseCustom = false;
      _cachedUrl = null;
      return _getDefaultUrl();
    }

    // Migration Android vrai téléphone: corriger les anciennes URLs non joignables.
    if (!useHostedBackendByDefault &&
        useCustomUrl &&
        customUrl != null &&
        _isAndroidInvalidLocalBackendUrl(customUrl)) {
      await prefs.setString(_backendUrlKey, defaultRealDeviceUrl);
      _cachedUrl = defaultRealDeviceUrl;
      _cachedUseCustom = true;
      return defaultRealDeviceUrl;
    }
    
    // Si une URL personnalisée est définie, l'utiliser
    if (useCustomUrl && customUrl != null && customUrl.isNotEmpty) {
      _cachedUrl = customUrl;
      _cachedUseCustom = true;
      return customUrl;
    }
    
    // Sinon, détecter automatiquement selon la plateforme
    return _getDefaultUrl();
  }
  
  /// URL par défaut selon la plateforme
  static String _getDefaultUrl() {
    if (useHostedBackendByDefault) {
      return defaultHostedUrl;
    }

    if (kIsWeb) {
      return defaultWebUrl;
    }
    
    if (Platform.isAndroid) {
      // Détecter émulateur vs vrai téléphone
      final isEmulator = Platform.operatingSystemVersion.contains('generic') ||
          Platform.operatingSystemVersion.toLowerCase().contains('emulator');
      
      if (isEmulator) {
        return defaultAndroidEmulatorUrl;
      }
      // Pour vrai téléphone sur WiFi
      return defaultRealDeviceUrl;
    }
    
    if (Platform.isIOS) {
      return defaultIOSUrl;
    }
    
    // Desktop (Windows, macOS, Linux)
    return defaultWebUrl;
  }
  
  /// Définir une URL personnalisée
  static Future<void> setCustomBackendUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backendUrlKey, url);
    await prefs.setBool(_useCustomUrlKey, true);
    _cachedUrl = url;
    _cachedUseCustom = true;
  }
  
  /// Activer/Désactiver l'URL personnalisée
  static Future<void> setUseCustomUrl(bool use) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useCustomUrlKey, use);
    _cachedUseCustom = use;
    if (!use) {
      _cachedUrl = null;
    }
  }
  
  /// Réinitialiser à l'URL par défaut
  static Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_backendUrlKey);
    await prefs.setBool(_useCustomUrlKey, false);
    _cachedUrl = null;
    _cachedUseCustom = false;
  }
  
  /// Obtenir l'URL personnalisée stockée (si définie)
  static Future<String?> getSavedCustomUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_backendUrlKey);
  }
  
  /// Vérifier si une URL personnalisée est utilisée
  static Future<bool> isUsingCustomUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_useCustomUrlKey) ?? false;
  }
  
  /// Obtenir l'IP locale du PC (pour affichage dans les paramètres)
  static String getLocalIPHint() {
    if (kIsWeb || Platform.isAndroid) {
      return 'Exemple: http://192.168.1.120:9000';
    }
    return 'Utilisez l\'adresse IP de votre PC';
  }
  
  /// Valider le format de l'URL
  static bool isValidUrl(String url) {
    if (url.isEmpty) return false;
    
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && 
             (uri.scheme == 'http' || uri.scheme == 'https') &&
             uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  /// Nettoyer le cache
  static void clearCache() {
    _cachedUrl = null;
    _cachedUseCustom = null;
  }
}
