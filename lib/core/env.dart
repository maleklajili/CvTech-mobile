/// ============================================================================
/// CONFIGURATION DE L'ENVIRONNEMENT - À CHANGER SELON VOTRE PLATEFORME
/// ============================================================================

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Disponibilité des plateformes:
/// - Pour PC/Web: http://localhost:9000
/// - Pour téléphone réel sur le même Wi-Fi: http://192.168.1.120:9000
/// - Pour Android Emulator: http://10.0.2.2:9000
/// - Pour iOS Simulator: http://127.0.0.1:9000

// URL pour PC/Web (localhost)
const String baseUrlWeb = 'http://localhost:9000';
const String baseUrlAndroid = 'http://10.0.2.2:9000';

// URL pour téléphone réel sur le même Wi-Fi
// ⚠️ Si vous utilisez adb reverse (recommandé), utilisez localhost
// ⚠️ Sinon, remplacez par votre adresse IP du PC (ex: 192.168.x.x)
const String baseUrlRealDevice = 'http://localhost:9000';

// URL pour iOS Simulator
const String baseUrlIOS = 'http://127.0.0.1:9000';

/// ============================================================================
/// MODE DE CONFIGURATION
/// ============================================================================
/// Définir à `true` pour utiliser un téléphone réel connecté en Wi-Fi
/// Définir à `false` pour utiliser la détection automatique (emulator/web)
const bool useRealDevice = true;

/// ============================================================================
/// DÉTECTION AUTOMATIQUE DE LA PLATEFORME
/// ============================================================================
String get baseUrl {
  // Si mode téléphone réel activé, utiliser l'IP du réseau local
  if (useRealDevice) {
    return baseUrlRealDevice;
  }
  
  // Détection automatique de la plateforme
  if (kIsWeb) {
    return baseUrlWeb;
  }
  
  if (Platform.isAndroid) {
    // Android Emulator utilise 10.0.2.2 pour accéder à localhost du PC
    return baseUrlAndroid;
  }
  
  if (Platform.isIOS) {
    // iOS Simulator utilise 127.0.0.1
    return baseUrlIOS;
  }
  
  // Windows, macOS, Linux desktop
  return baseUrlWeb;
}

/// URL pour les fichiers (uploads)
String get fileUrl => '$baseUrl/uploads';

/// ============================================================================
/// CONSEILS DE CONFIGURATION
/// ============================================================================
/// 
/// 1. TÉLÉPHONE RÉEL:
///    - Décommentez: const String baseUrl = baseUrlRealDevice;
///    - Trouvez l'IP de votre PC: 
///      - Windows: ipconfig (cherchez "IPv4 Address")
///      - Mac/Linux: ifconfig ou hostname -I
///    - Remplacez 192.168.1.120 par l'IP trouvée
///    - Assurez-vous que le téléphone et le PC sont sur le MÊME Wi-Fi
///
/// 2. PC/WEB:
///    - Décommentez: const String baseUrl = baseUrlWeb;
///    - Le backend doit tourner sur localhost:9000
///
/// 3. ANDROID EMULATOR:
///    - Décommentez: const String baseUrl = baseUrlAndroid;
///    - Le backend doit tourner sur localhost:9000 du PC hôte
///
/// 4. iOS SIMULATOR:
///    - Décommentez: const String baseUrl = baseUrlIOS;
///    - Le backend doit tourner sur localhost:9000
