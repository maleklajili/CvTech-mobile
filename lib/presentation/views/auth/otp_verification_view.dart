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
import 'package:cv_tech/presentation/widgets/auth/otp_text_field.dart';

class OtpVerificationView extends StatefulWidget {
  final String email;
  final RegisterRequest userData;
  final String? devOtp; // OTP pré-rempli en mode DEV

  const OtpVerificationView({
    super.key,
    required this.email,
    required this.userData,
    this.devOtp,
  });

  @override
  State<OtpVerificationView> createState() => _OtpVerificationViewState();
}

class _OtpVerificationViewState extends State<OtpVerificationView> {
  String _otp = '';
  int _resendCountdown = 60;
  Timer? _timer;
  bool _canResend = false;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();

    // Si on a un OTP en mode DEV, le pré-remplir
    if (widget.devOtp != null && widget.devOtp!.isNotEmpty) {
      _otp = widget.devOtp!;
    }
  }

  @override
  void dispose() {
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

  void _onOtpCompleted(String otp) {
    setState(() {
      _otp = otp;
    });
    // Auto-verify when OTP is complete
    _verifyOtp();
  }

  void _verifyOtp() {
    if (_otp.length == 6) {
      context.read<AuthBloc>().add(
            AuthVerifyOtpRequested(
              otp: _otp,
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
        title: '📧 Nouveau code envoyé !',
        message: 'Vérifiez votre boîte de réception et le dossier spam.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérification'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            setState(() {
              _isVerified = true;
            });

            AuthErrorHandler.showSuccessAlert(
              context,
              title: '🎉 Bienvenue !',
              message: 'Votre compte a été créé avec succès !',
            );

            // Show success animation then navigate
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
          }
        },
        builder: (context, state) {
          if (_isVerified) {
            return _buildSuccessScreen(isDark);
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Dimensions.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: Dimensions.heightLargeVertical),

                  // Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.email_outlined,
                      size: 60,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: Dimensions.heightLargeVertical),

                  // Title
                  Text(
                    'Vérification OTP',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkTextColor
                              : AppColors.textColor,
                        ),
                  ),
                  const SizedBox(height: Dimensions.heightSmallVertical),

                  // Description
                  Text(
                    'Nous avons envoyé un code de vérification à 6 chiffres à',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.darkTextMutedColor
                              : AppColors.textMutedColor,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Le code expire dans 5 minutes',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.darkTextMutedColor
                              : AppColors.textMutedColor,
                          fontStyle: FontStyle.italic,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Vérifiez votre boîte mail (et les spams)',
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Indicateur mode DEV avec OTP pré-rempli
                  if (widget.devOtp != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.developer_mode,
                              color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '🔧 Mode DEV - OTP pré-rempli: ${widget.devOtp}',
                              style: TextStyle(
                                color: Colors.orange.shade900,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: Dimensions.heightXLargeVertical),

                  // OTP Input
                  OtpTextField(
                    length: 6,
                    initialValue: widget.devOtp,
                    onCompleted: _onOtpCompleted,
                    onChanged: (value) {
                      setState(() {
                        _otp = value;
                      });
                    },
                  ),
                  const SizedBox(height: Dimensions.heightLargeVertical),

                  // Verify button
                  AuthButton(
                    text: 'Vérifier et créer mon compte',
                    onPressed: _otp.length == 6 ? _verifyOtp : null,
                    isLoading: state is AuthOtpVerifying,
                  ),
                  const SizedBox(height: Dimensions.heightLargeVertical),

                  // Resend OTP
                  Container(
                    padding: const EdgeInsets.all(Dimensions.paddingMedium),
                    decoration: BoxDecoration(
                      color: (isDark
                          ? AppColors.darkSurfaceColor
                          : Colors.grey.shade100),
                      borderRadius: Dimensions.mediumBorderRadius,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Vous n\'avez pas reçu le code ?',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextMutedColor
                                : AppColors.textMutedColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_canResend)
                          TextButton.icon(
                            onPressed: _resendOtp,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Renvoyer le code'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryColor,
                            ),
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.timer,
                                size: 18,
                                color: AppColors.textMutedColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Renvoyer dans $_resendCountdown secondes',
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.darkTextMutedColor
                                      : AppColors.textMutedColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Dimensions.heightMediumVertical),

                  // Change email
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Modifier l\'adresse email',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.darkTextMutedColor
                            : AppColors.textMutedColor,
                      ),
                    ),
                  ),
                ],
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
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 80,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: Dimensions.heightLargeVertical),
          Text(
            'Compte créé avec succès !',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextColor : AppColors.textColor,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Dimensions.heightSmallVertical),
          Text(
            'Bienvenue ${widget.userData.firstName} !',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Dimensions.heightMediumVertical),
          Text(
            'Redirection en cours...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.darkTextMutedColor
                      : AppColors.textMutedColor,
                ),
          ),
          const SizedBox(height: Dimensions.heightLargeVertical),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
          ),
        ],
      ),
    );
  }
}
