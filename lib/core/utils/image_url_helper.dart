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
    if (imageName == null || imageName.isEmpty || userId == null || userId.isEmpty) {
      return null;
    }

    // Si c'est déjà une URL complète, la retourner telle quelle
    if (imageName.startsWith('http://') || imageName.startsWith('https://')) {
      return imageName;
    }

    // Utiliser l'URL en cache ou une URL par défaut
    final baseUrl = _cachedBaseUrl ?? 'http://localhost:9001';
    String cleanUserId = userId.trim();
    String cleanImageName = imageName.trim();
    
    return '$baseUrl/uploads/images-$cleanUserId/$cleanImageName';
  }

  /// Resolve any potentially relative URL to an absolute backend URL.
  static String? resolveMaybeUrlSync(String? url) {
    if (url == null || url.isEmpty) return null;
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    final baseUrl = _cachedBaseUrl ?? 'http://localhost:9001';
    if (trimmed.startsWith('/')) {
      return '$baseUrl$trimmed';
    }
    return '$baseUrl/$trimmed';
  }

  /// Build message media URL when backend returns only a file name.
  static String? getMessageMediaUrlSync(
    String? mediaUrlOrName,
    String? senderId,
  ) {
    if (mediaUrlOrName == null || mediaUrlOrName.isEmpty) return null;

    final resolved = resolveMaybeUrlSync(mediaUrlOrName);
    if (resolved != null &&
        (mediaUrlOrName.startsWith('http://') ||
            mediaUrlOrName.startsWith('https://') ||
            mediaUrlOrName.startsWith('/'))) {
      return resolved;
    }

    if (senderId == null || senderId.isEmpty) {
      return resolved;
    }

    final baseUrl = _cachedBaseUrl ?? 'http://localhost:9001';
    final cleanSenderId = senderId.trim();
    final cleanName = mediaUrlOrName.trim();
    return '$baseUrl/uploads/images-$cleanSenderId/messages/$cleanName';
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
  
  /// Construire l'URL complète d'un média de post
  static String? getPostMediaUrlSync(String? fileName, String? authorId) {
    if (fileName == null || fileName.isEmpty) return null;
    
    // Si c'est déjà une URL complète, la retourner telle quelle
    if (fileName.startsWith('http://') || fileName.startsWith('https://')) {
      return fileName;
    }
    
    if (authorId == null || authorId.isEmpty) return null;
    
    final baseUrl = _cachedBaseUrl ?? 'http://localhost:9001';
    return '$baseUrl/uploads/images-$authorId/posts/$fileName';
  }

  /// Obtenir l'URL de base (publique)
  static String getBaseUrl() {
    return _cachedBaseUrl ?? 'http://localhost:9001';
  }

  /// Effacer le cache de l'URL
  static void clearCache() {
    _cachedBaseUrl = null;
  }
}
