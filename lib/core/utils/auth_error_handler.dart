// Flutter imports:
import 'package:flutter/material.dart';

class AuthErrorType {
  // Erreurs de connexion
  static const invalidPassword = 'INVALID_PASSWORD';
  static const userNotFound = 'USER_NOT_FOUND';
  static const accountNotVerified = 'ACCOUNT_NOT_VERIFIED';
  static const accountLocked = 'ACCOUNT_LOCKED';
  static const tooManyAttempts = 'TOO_MANY_ATTEMPTS';

  // Erreurs d'inscription
  static const emailAlreadyExists = 'EMAIL_ALREADY_EXISTS';
  static const usernameAlreadyExists = 'USERNAME_ALREADY_EXISTS';
  static const invalidEmail = 'INVALID_EMAIL';
  static const weakPassword = 'WEAK_PASSWORD';
  static const passwordMismatch = 'PASSWORD_MISMATCH';
  static const requiredFieldMissing = 'REQUIRED_FIELD_MISSING';

  // Erreurs OTP
  static const invalidOtp = 'INVALID_OTP';
  static const otpExpired = 'OTP_EXPIRED';
  static const otpLimitExceeded = 'OTP_LIMIT_EXCEEDED';

  // Erreurs de réinitialisation mot de passe
  static const tokenExpired = 'TOKEN_EXPIRED';

  // Erreurs réseau
  static const noConnection = 'NO_CONNECTION';
  static const serverError = 'SERVER_ERROR';
  static const timeout = 'TIMEOUT';
  static const sendEmailError = 'SEND_EMAIL_ERROR';
  static const badRequest = 'BAD_REQUEST';
  static const unauthorized = 'UNAUTHORIZED';
  static const forbidden = 'FORBIDDEN';
  static const notFound = 'NOT_FOUND';

  // Erreurs génériques
  static const unknown = 'UNKNOWN';
}

class AuthErrorData {
  final String type;
  final String title;
  final String message;
  final IconData icon;
  final Color color;

  AuthErrorData({
    required this.type,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });
}

class AuthErrorHandler {
  /// Détecte le type d'erreur à partir du message du serveur
  static String detectErrorType(String errorMessage) {
    final lower = errorMessage.toLowerCase();

    // ===== ERREURS DE CONNEXION (Login) =====
    // Backend: "Invalid password" (401)
    if (lower.contains('invalid password') ||
        lower.contains('wrong password') ||
        lower.contains('mot de passe incorrect')) {
      return AuthErrorType.invalidPassword;
    }
    
    // Backend: "User not found" (404)
    if (lower.contains('user not found') ||
        lower.contains('utilisateur introuvable') ||
        lower.contains('no user found') ||
        lower.contains('user no longer exists')) {
      return AuthErrorType.userNotFound;
    }
    
    // Backend: "Email or username is required" (400)
    if (lower.contains('email or username is required') ||
        lower.contains('identifiant requis')) {
      return AuthErrorType.requiredFieldMissing;
    }
    
    if (lower.contains('not verified') ||
        lower.contains('non vérifié') ||
        lower.contains('email not verified')) {
      return AuthErrorType.accountNotVerified;
    }
    
    if (lower.contains('locked') || lower.contains('account locked')) {
      return AuthErrorType.accountLocked;
    }
    
    if (lower.contains('too many attempts') || lower.contains('trop de')) {
      return AuthErrorType.tooManyAttempts;
    }

    // ===== ERREURS D'INSCRIPTION (Register) =====
    // Backend: "User already exists with this email" (400)
    if (lower.contains('user already exists') ||
        lower.contains('already exists with this email') ||
        lower.contains('email already in use') ||
        lower.contains('cet email est déjà utilisé')) {
      return AuthErrorType.emailAlreadyExists;
    }
    
    if (lower.contains('username') &&
        (lower.contains('exist') || lower.contains('already'))) {
      return AuthErrorType.usernameAlreadyExists;
    }
    
    // Backend: "Invalid email format" (400)
    if (lower.contains('invalid email') || 
        lower.contains('invalid email format') ||
        lower.contains('email invalide')) {
      return AuthErrorType.invalidEmail;
    }
    
    if (lower.contains('weak password') ||
        (lower.contains('password') && lower.contains('weak'))) {
      return AuthErrorType.weakPassword;
    }
    
    if (lower.contains('password') && lower.contains('match')) {
      return AuthErrorType.passwordMismatch;
    }
    
    if (lower.contains('required') || lower.contains('missing') || lower.contains('complete all')) {
      return AuthErrorType.requiredFieldMissing;
    }

    // ===== ERREURS OTP =====
    // Backend: "Invalid OTP" (400)
    if (lower.contains('invalid otp') ||
        lower.contains('code invalide') ||
        lower.contains('wrong otp') ||
        lower.contains('code de vérification incorrect')) {
      return AuthErrorType.invalidOtp;
    }
    
    // Backend: "OTP expired" (400)
    if (lower.contains('otp expired') || 
        lower.contains('code expiré') ||
        lower.contains('code a expiré')) {
      return AuthErrorType.otpExpired;
    }
    
    if (lower.contains('otp limit') || lower.contains('too many otp')) {
      return AuthErrorType.otpLimitExceeded;
    }

    // ===== ERREURS DE RÉINITIALISATION MOT DE PASSE =====
    // Backend: "Invalid or expired reset token" (400)
    if (lower.contains('invalid or expired reset token') ||
        lower.contains('token invalide') ||
        lower.contains('lien expiré')) {
      return AuthErrorType.tokenExpired;
    }
    
    // Backend: "Reset token has expired" (410)
    if (lower.contains('reset token has expired') ||
        lower.contains('token expiré')) {
      return AuthErrorType.tokenExpired;
    }
    
    // Backend: "Failed to send verification email" (500)
    if (lower.contains('failed to send') ||
        lower.contains('send') && lower.contains('email') ||
        lower.contains('envoi') && lower.contains('email')) {
      return AuthErrorType.sendEmailError;
    }

    // ===== ERREURS HTTP =====
    if (lower.contains('400') || lower.contains('bad request')) {
      return AuthErrorType.badRequest;
    }
    if (lower.contains('401') || lower.contains('unauthorized')) {
      return AuthErrorType.unauthorized;
    }
    if (lower.contains('403') || 
        lower.contains('forbidden') ||
        lower.contains('refresh token not found')) {
      return AuthErrorType.forbidden;
    }
    if (lower.contains('404') || lower.contains('not found')) {
      return AuthErrorType.notFound;
    }

    // ===== ERREURS RÉSEAU =====
    if (lower.contains('no connection') ||
        lower.contains('aucune connexion') ||
        lower.contains('internet') ||
        lower.contains('network') ||
        lower.contains('impossible de joindre le serveur') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection refused')) {
      return AuthErrorType.noConnection;
    }

    if (lower.contains('ssl') ||
        lower.contains('tls') ||
        lower.contains('certificate') ||
        lower.contains('certificat') ||
        lower.contains('handshake')) {
      return AuthErrorType.serverError;
    }
    
    if (lower.contains('server error') ||
        lower.contains('500') ||
        lower.contains('internal server') ||
        lower.contains('erreur serveur')) {
      return AuthErrorType.serverError;
    }
    
    if (lower.contains('timeout') || 
        lower.contains('délai') ||
        lower.contains('délai de connexion')) {
      return AuthErrorType.timeout;
    }

    return AuthErrorType.unknown;
  }

  /// Retourne les données d'erreur personnalisées
  static AuthErrorData getErrorData(String errorType) {
    switch (errorType) {
      case AuthErrorType.invalidPassword:
        return AuthErrorData(
          type: AuthErrorType.invalidPassword,
          title: '🔐 Mot de passe incorrect',
          message:
              'Le mot de passe que vous avez saisi est incorrect. Essayez à nouveau.',
          icon: Icons.lock_outline,
          color: const Color(0xFFE53935),
        );

      case AuthErrorType.userNotFound:
        return AuthErrorData(
          type: AuthErrorType.userNotFound,
          title: '👤 Utilisateur introuvable',
          message:
              'Aucun compte trouvé avec cet identifiant. Vérifiez votre email ou créez un nouveau compte.',
          icon: Icons.person_outline,
          color: const Color(0xFFE53935),
        );

      case AuthErrorType.accountNotVerified:
        return AuthErrorData(
          type: AuthErrorType.accountNotVerified,
          title: '⚠️ Compte non vérifié',
          message:
              'Veuillez vérifier votre email pour activer votre compte avant de continuer.',
          icon: Icons.mail_outline,
          color: const Color(0xFFFFA726),
        );

      case AuthErrorType.accountLocked:
        return AuthErrorData(
          type: AuthErrorType.accountLocked,
          title: '🔒 Compte verrouillé',
          message:
              'Votre compte a été temporairement verrouillé pour des raisons de sécurité. Contactez le support.',
          icon: Icons.lock_outline,
          color: const Color(0xFFE53935),
        );

      case AuthErrorType.tooManyAttempts:
        return AuthErrorData(
          type: AuthErrorType.tooManyAttempts,
          title: '⏱️ Trop de tentatives',
          message:
              'Vous avez essayé trop de fois. Veuillez patienter quelques minutes avant de réessayer.',
          icon: Icons.schedule_outlined,
          color: const Color(0xFFFFA726),
        );

      case AuthErrorType.emailAlreadyExists:
        return AuthErrorData(
          type: AuthErrorType.emailAlreadyExists,
          title: '📧 Email déjà utilisé',
          message:
              'Cette adresse email est déjà associée à un compte. Connectez-vous ou utilisez une autre adresse.',
          icon: Icons.email_outlined,
          color: const Color(0xFFE53935),
        );

      case AuthErrorType.usernameAlreadyExists:
        return AuthErrorData(
          type: AuthErrorType.usernameAlreadyExists,
          title: '🆔 Nom d\'utilisateur indisponible',
          message:
              'Ce nom d\'utilisateur est déjà pris. Choisissez un autre nom d\'utilisateur.',
          icon: Icons.assignment_ind_outlined,
          color: const Color(0xFFE53935),
        );

      case AuthErrorType.invalidEmail:
        return AuthErrorData(
          type: AuthErrorType.invalidEmail,
          title: '❌ Email invalide',
          message: 'L\'adresse email n\'est pas valide. Vérifiez le format.',
          icon: Icons.email_outlined,
          color: const Color(0xFFE53935),
        );

      case AuthErrorType.weakPassword:
        return AuthErrorData(
          type: AuthErrorType.weakPassword,
          title: '🔑 Mot de passe trop faible',
          message:
              'Le mot de passe doit contenir au moins 6 caractères (lettres et chiffres).',
          icon: Icons.vpn_key_outlined,
          color: const Color(0xFFFFA726),
        );

      case AuthErrorType.passwordMismatch:
        return AuthErrorData(
          type: AuthErrorType.passwordMismatch,
          title: '🔐 Mots de passe différents',
          message: 'Les mots de passe saisis ne correspondent pas. Vérifiez.',
          icon: Icons.lock_outline,
          color: const Color(0xFFE53935),
        );

      case AuthErrorType.requiredFieldMissing:
        return AuthErrorData(
          type: AuthErrorType.requiredFieldMissing,
          title: '📝 Champ manquant',
          message:
              'Veuillez remplir tous les champs obligatoires du formulaire.',
          icon: Icons.info_outlined,
          color: const Color(0xFFE53935),
        );

      case AuthErrorType.invalidOtp:
        return AuthErrorData(
          type: AuthErrorType.invalidOtp,
          title: '🔢 Code invalide',
          message:
              'Le code de vérification est incorrect. Vérifiez le code reçu par email et réessayez.',
          icon: Icons.pin_outlined,
          color: const Color(0xFFE53935),
        );

      case AuthErrorType.otpExpired:
        return AuthErrorData(
          type: AuthErrorType.otpExpired,
          title: '⏰ Code expiré',
          message:
              'Le code de vérification a expiré. Cliquez sur "Renvoyer" pour en recevoir un nouveau.',
          icon: Icons.timer_outlined,
          color: const Color(0xFFFFA726),
        );

      case AuthErrorType.otpLimitExceeded:
        return AuthErrorData(
          type: AuthErrorType.otpLimitExceeded,
          title: '🚫 Limite de codes atteinte',
          message:
              'Vous avez demandé trop de codes. Veuillez patienter avant de réessayer.',
          icon: Icons.block_outlined,
          color: const Color(0xFFE53935),
        );

      case AuthErrorType.tokenExpired:
        return AuthErrorData(
          type: AuthErrorType.tokenExpired,
          title: '⏰ Lien expiré',
          message:
              'Le lien de réinitialisation a expiré. Veuillez demander un nouveau lien.',
          icon: Icons.link_off_outlined,
          color: const Color(0xFFFFA726),
        );

      case AuthErrorType.noConnection:
        return AuthErrorData(
          type: AuthErrorType.noConnection,
          title: '📡 Pas de connexion',
          message: 'Vérifiez votre connexion internet et réessayez la requête.',
          icon: Icons.wifi_off_outlined,
          color: const Color(0xFFE53935),
        );

      case AuthErrorType.badRequest:
        return AuthErrorData(
          type: AuthErrorType.badRequest,
          title: '⚠️ Demande invalide',
          message:
              'Les données envoyées sont invalides. Vérifiez votre saisie.',
          icon: Icons.error_outline,
          color: const Color(0xFFE53935),
        );

      case AuthErrorType.unauthorized:
        return AuthErrorData(
          type: AuthErrorType.unauthorized,
          title: '🚫 Non autorisé',
          message:
              'Vous n\'êtes pas autorisé à accéder à cette ressource. Reconnectez-vous.',
          icon: Icons.do_not_disturb_on_outlined,
          color: const Color(0xFFE53935),
        );

      case AuthErrorType.forbidden:
        return AuthErrorData(
          type: AuthErrorType.forbidden,
          title: '🔒 Accès refusé',
          message: 'Vous n\'avez pas les permissions nécessaires.',
          icon: Icons.lock_outline,
          color: const Color(0xFFE53935),
        );

      case AuthErrorType.notFound:
        return AuthErrorData(
          type: AuthErrorType.notFound,
          title: '🔍 Non trouvé',
          message: 'La ressource demandée n\'existe pas.',
          icon: Icons.search_off_outlined,
          color: const Color(0xFFE53935),
        );

      case AuthErrorType.serverError:
        return AuthErrorData(
          type: AuthErrorType.serverError,
          title: '⚙️ Erreur serveur',
          message:
              'Le serveur est temporairement indisponible. Veuillez réessayer dans quelques instants.',
          icon: Icons.storage_outlined,
          color: const Color(0xFFE53935),
        );

      case AuthErrorType.timeout:
        return AuthErrorData(
          type: AuthErrorType.timeout,
          title: '⏱️ Délai dépassé',
          message:
              'La requête a pris trop de temps. Vérifiez votre connexion et réessayez.',
          icon: Icons.schedule_outlined,
          color: const Color(0xFFFFA726),
        );

      case AuthErrorType.sendEmailError:
        return AuthErrorData(
          type: AuthErrorType.sendEmailError,
          title: '✉️ Erreur d\'envoi',
          message:
              'Impossible d\'envoyer l\'email. Vérifiez votre adresse email et réessayez.',
          icon: Icons.mail_outline_outlined,
          color: const Color(0xFFE53935),
        );

      default:
        return AuthErrorData(
          type: AuthErrorType.unknown,
          title: '❌ Erreur',
          message: 'Une erreur est survenue. Veuillez réessayer.',
          icon: Icons.error_outline,
          color: const Color(0xFFE53935),
        );
    }
  }

  /// Affiche une alerte personnalisée pour l'erreur
  static void showErrorAlert(BuildContext context, String errorMessage) {
    final errorType = detectErrorType(errorMessage);
    final errorData = getErrorData(errorType);

    // Utiliser CustomToast avec les données personnalisées
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: errorData.color.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                errorData.icon,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    errorData.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    errorData.message,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: errorData.color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 5),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  /// Affiche une alerte de succès personnalisée
  static void showSuccessAlert(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF43A047).withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF43A047),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  /// Affiche une alerte d'avertissement personnalisée
  static void showWarningAlert(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFA726).withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning_outlined,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFFA726),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }
}
