import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

const String hostedBaseUrl = 'https://e72d-196-229-218-90.ngrok-free.app';
const String localBaseUrl = 'http://localhost:9000';
 
// ✅ Web / PC
const String baseUrlWeb = localBaseUrl;
 
// ✅ Téléphone Android réel — utilise localhost avec ADB reverse
const String baseUrlAndroid = localBaseUrl;
 
// ✅ ngrok (optionnel, si WiFi ne fonctionne pas)
const String baseUrlRealDevice = localBaseUrl;
// ✅ iOS Simulator
const String baseUrlIOS = localBaseUrl;
 
/// Mettre à true uniquement si tu veux forcer ngrok
const bool useRealDevice = false;
 
/// ============================================================================
/// DÉTECTION AUTOMATIQUE — ne pas modifier
/// ============================================================================
String get baseUrl {
  if (useRealDevice) return baseUrlRealDevice;
  if (kIsWeb) return baseUrlWeb;
  if (Platform.isAndroid) return baseUrlAndroid;
  if (Platform.isIOS) return baseUrlIOS;
  return baseUrlWeb;
}
 
/// URL fichiers uploadés
String get fileUrl => '$baseUrl/uploads';
 