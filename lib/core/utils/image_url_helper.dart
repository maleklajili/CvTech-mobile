// Project imports:
import 'package:cv_tech/core/config/network_config.dart';

/// Helper pour générer les URLs complètes des images
class ImageUrlHelper {
  static String? _cachedBaseUrl;
  
  /// Obtenir l'URL de base (avec cache)
  static Future<String> _getBaseUrl() async {
    _cachedBaseUrl ??= await NetworkConfig.getBackendUrl();
    return _cachedBaseUrl!;
  }
  
  /// Construire l'URL complète d'une image de profil
  static Future<String?> getImageUrl(String? imageName, String? userId) async {
    if (imageName == null || imageName.isEmpty || userId == null || userId.isEmpty) {
      return null;
    }
    
    // Si c'est déjà une URL complète, la retourner telle quelle
    if (imageName.startsWith('http://') || imageName.startsWith('https://')) {
      return imageName;
    }
    
    final baseUrl = await _getBaseUrl();
    
    // Format du backend: /uploads/images-{userId}/{imageName}
    String cleanUserId = userId.trim();
    String cleanImageName = imageName.trim();
    
    return '$baseUrl/uploads/images-$cleanUserId/$cleanImageName';
  }
  
  /// Version synchrone pour compatibilité (utilise le cache)
  static String? getImageUrlSync(String? imageName, String? userId) {
    print('🔍 ImageUrlHelper.getImageUrlSync - imageName: $imageName, userId: $userId');
    
    if (imageName == null || imageName.isEmpty || userId == null || userId.isEmpty) {
      print('🔍 ImageUrlHelper.getImageUrlSync - Returning null (empty params)');
      return null;
    }

    // Si c'est déjà une URL complète, la retourner telle quelle
    if (imageName.startsWith('http://') || imageName.startsWith('https://')) {
      print('🔍 ImageUrlHelper.getImageUrlSync - Returning full URL: $imageName');
      return imageName;
    }

    // Utiliser l'URL en cache ou une URL par défaut
    final baseUrl = _cachedBaseUrl ?? 'http://localhost:9000';
    String cleanUserId = userId.trim();
    String cleanImageName = imageName.trim();
    
    final fullUrl = '$baseUrl/uploads/images-$cleanUserId/$cleanImageName';
    print('🔍 ImageUrlHelper.getImageUrlSync - Constructed URL: $fullUrl');
    return fullUrl;
  }

  /// Construire l'URL complète d'une image de couverture
  static Future<String?> getCoverUrl(String? coverName, String? userId) async {
    return getImageUrl(coverName, userId);
  }
  
  /// Version synchrone pour l'image de couverture
  static String? getCoverUrlSync(String? coverName, String? userId) {
    return getImageUrlSync(coverName, userId);
  }
  
  /// Construire l'URL complète d'un certificat
  static Future<String?> getCertificateUrl(String? certName, String? userId) async {
    if (certName == null || certName.isEmpty || userId == null || userId.isEmpty) {
      return null;
    }
    
    if (certName.startsWith('http://') || certName.startsWith('https://')) {
      return certName;
    }
    
    final baseUrl = await _getBaseUrl();
    String cleanUserId = userId.trim();
    String cleanCertName = certName.trim();
    
    return '$baseUrl/uploads/images-$cleanUserId/certfication/$cleanCertName';
  }
  
  /// Construire l'URL complète d'une image de projet
  static Future<String?> getProjectImageUrl(String? imageName, String? userId) async {
    if (imageName == null || imageName.isEmpty || userId == null || userId.isEmpty) {
      return null;
    }
    
    if (imageName.startsWith('http://') || imageName.startsWith('https://')) {
      return imageName;
    }
    
    final baseUrl = await _getBaseUrl();
    String cleanUserId = userId.trim();
    String cleanImageName = imageName.trim();
    
    return '$baseUrl/uploads/images-$cleanUserId/projects/$cleanImageName';
  }
  
  /// Effacer le cache de l'URL
  static void clearCache() {
    _cachedBaseUrl = null;
  }
}
