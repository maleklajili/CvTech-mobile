// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/core/constants/dimension.dart';
import 'package:cv_tech/core/utils/auth_error_handler.dart';
import 'package:cv_tech/data/models/auth/register_request.dart';
import 'package:cv_tech/presentation/blocs/auth/auth_bloc.dart';
import 'package:cv_tech/presentation/blocs/auth/auth_event.dart';
import 'package:cv_tech/presentation/blocs/auth/auth_state.dart';
import 'package:cv_tech/presentation/widgets/auth/auth_button.dart';
import 'package:cv_tech/core/l10n/app_localizations.dart';

/// Page simple pour saisir le code de vérification OTP
class EnterOtpView extends StatefulWidget {
  final String email;
  final RegisterRequest userData;

  const EnterOtpView({
    super.key,
    required this.email,
    required this.userData,
  });

  @override
  State<EnterOtpView> createState() => _EnterOtpViewState();
}

class _EnterOtpViewState extends State<EnterOtpView> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _resendCountdown = 60;
  Timer? _timer;
  bool _canResend = false;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _canResend = false;
    _resendCountdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendCountdown > 0) {
            _resendCountdown--;
          } else {
            _canResend = true;
            timer.cancel();
          }
        });
      }
    });
  }

  void _verifyOtp() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            AuthVerifyOtpRequested(
              otp: _otpController.text.trim(),
              userData: widget.userData,
            ),
          );
    }
  }

  void _resendOtp() {
    if (_canResend) {
      context.read<AuthBloc>().add(
            AuthSendOtpRequested(email: widget.email),
          );
      _startCountdown();
      AuthErrorHandler.showSuccessAlert(
        context,
        title: '📧 Code renvoyé',
        message: 'Un nouveau code a été envoyé à ${widget.email}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            setState(() {
              _isVerified = true;
            });

            // Déconnecter immédiatement pour sécurité
            context.read<AuthBloc>().add(const AuthLogoutRequested());

            AuthErrorHandler.showSuccessAlert(
              context,
              title: '🎉 ${AppLocalizations.of(context).welcome}!',
              message: AppLocalizations.of(context).accountCreatedSuccess,
            );

            // Rediriger vers la page de login
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            });
          } else if (state is AuthError) {
            // Vérifier si c'est une erreur d'OTP expiré pour permettre le renvoi
            final errorType = AuthErrorHandler.detectErrorType(state.message);
            if (errorType == AuthErrorType.otpExpired && !_canResend) {
              setState(() {
                _canResend = true;
                _resendCountdown = 0;
              });
              _timer?.cancel();
            }
            // Utiliser le gestionnaire d'erreur personnalisé
            AuthErrorHandler.showErrorAlert(context, state.message);
          } else if (state is AuthOtpSent) {
            AuthErrorHandler.showSuccessAlert(
              context,
              title: '📧 Code envoyé !',
              message: 'Vérifiez votre boîte de réception et le dossier spam.',
            );

            // Redémarrer le compteur
            _startCountdown();
          }
        },
        builder: (context, state) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          if (_isVerified) {
            return _buildSuccessScreen(isDark);
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Dimensions.paddingLarge),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),

                    // Icon
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryColor.withOpacity(0.2),
                            AppColors.primaryColor.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mark_email_read_outlined,
                        size: 70,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      AppLocalizations.of(context).verificationCode,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.darkTextColor
                                    : AppColors.textColor,
                              ),
                    ),
                    const SizedBox(height: 12),

                    // Description
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextMutedColor
                                  : AppColors.textMutedColor,
                            ),
                        children: [
                          const TextSpan(
                              text:
                                  'Un code de vérification à 6 chiffres a été envoyé à\n'),
                          TextSpan(
                            text: widget.email,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    // OTP Input Field
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 16,
                        color: isDark
                            ? AppColors.darkTextColor
                            : AppColors.textColor,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '000000',
                        hintStyle: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 16,
                          color: isDark
                              ? AppColors.darkTextMutedColor.withOpacity(0.3)
                              : AppColors.textMutedColor.withOpacity(0.3),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? AppColors.darkSurfaceColor
                            : Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppColors.darkDividerColor
                                : AppColors.dividerColor,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppColors.primaryColor,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.errorColor,
                            width: 1,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 24,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer le code';
                        }
                        if (value.length != 6) {
                          return 'Le code doit contenir 6 chiffres';
                        }
                        if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                          return 'Le code ne doit contenir que des chiffres';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _verifyOtp(),
                    ),
                    const SizedBox(height: 24),

                    // Info Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue.shade700, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Conseil',
                                  style: TextStyle(
                                    color: Colors.blue.shade900,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Vérifiez votre boîte de réception et le dossier spam. Le code expire dans 5 minutes.',
                                  style: TextStyle(
                                    color: Colors.blue.shade800,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Verify Button
                    AuthButton(
                      text: AppLocalizations.of(context).verifyCode,
                      onPressed: _verifyOtp,
                      isLoading: state is AuthOtpVerifying,
                    ),
                    const SizedBox(height: 24),

                    // Resend Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Vous n'avez pas reçu le code ? ",
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextMutedColor
                                        : AppColors.textMutedColor,
                                  ),
                        ),
                        if (_canResend)
                          TextButton(
                            onPressed: _resendOtp,
                            child: Text(
                              'Renvoyer',
                              style: TextStyle(
                                color: AppColors.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Text(
                            'Renvoyer dans ${_resendCountdown}s',
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuccessScreen(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 80,
              color: Colors.green.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context).accountCreatedSuccess,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Votre compte a été créé avec succès',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.darkTextMutedColor
                      : AppColors.textMutedColor,
                ),
          ),
          const SizedBox(height: 8),
          const CircularProgressIndicator(),
        ],
      ),
    );
  }
}
