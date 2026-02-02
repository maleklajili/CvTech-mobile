/// Classe utilitaire pour les validations de formulaires
class FormValidators {
  FormValidators._();

  /// Valide un email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'email est requis';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Format d\'email invalide';
    }
    
    return null;
  }

  /// Valide un mot de passe
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }
    
    if (value.length < 6) {
      return 'Minimum 6 caractères requis';
    }
    
    // Vérifier la présence d'au moins une lettre majuscule
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Doit contenir au moins une lettre majuscule';
    }
    
    // Vérifier la présence d'au moins une lettre minuscule
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Doit contenir au moins une lettre minuscule';
    }
    
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Doit contenir au moins un chiffre';
    }
    
    return null;
  }

  /// Valide la confirmation du mot de passe
  static String? Function(String?) validateConfirmPassword(String password) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'La confirmation est requise';
      }
      
      if (value != password) {
        return 'Les mots de passe ne correspondent pas';
      }
      
      return null;
    };
  }

  /// Valide un prénom ou nom
  static String? validateName(String? value, {String fieldName = 'Ce champ'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName est requis';
    }
    
    if (value.trim().length < 2) {
      return 'Minimum 2 caractères requis';
    }
    
    if (!RegExp(r'^[a-zA-ZÀ-ÿ\s\-]+$').hasMatch(value.trim())) {
      return 'Caractères invalides';
    }
    
    return null;
  }

  /// Valide un nom d'utilisateur
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le nom d\'utilisateur est requis';
    }
    
    if (value.trim().length < 3) {
      return 'Minimum 3 caractères requis';
    }
    
    if (value.trim().length > 20) {
      return 'Maximum 20 caractères';
    }
    
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
      return 'Uniquement lettres, chiffres et _';
    }
    
    return null;
  }

  /// Valide un champ requis
  static String? validateRequired(String? value, {String fieldName = 'Ce champ'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName est requis';
    }
    return null;
  }

  /// Valide un numéro de téléphone (optionnel)
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optionnel
    }
    
    final cleaned = value.replaceAll(RegExp(r'[\s\-\.\(\)]'), '');
    if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(cleaned)) {
      return 'Format de téléphone invalide';
    }
    
    return null;
  }

  /// Valide une URL (optionnel)
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optionnel
    }
    
    final urlRegex = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
      caseSensitive: false,
    );
    
    if (!urlRegex.hasMatch(value.trim())) {
      return 'URL invalide';
    }
    
    return null;
  }

  /// Valide un code OTP
  static String? validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le code OTP est requis';
    }
    
    if (value.length != 6) {
      return 'Le code doit contenir 6 chiffres';
    }
    
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Le code doit contenir uniquement des chiffres';
    }
    
    return null;
  }
}
