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
import 'package:cv_tech/core/utils/validators/form_validators.dart';
import 'package:cv_tech/data/models/auth/register_request.dart';
import 'package:cv_tech/presentation/blocs/auth/auth_bloc.dart';
import 'package:cv_tech/presentation/blocs/auth/auth_event.dart';
import 'package:cv_tech/presentation/blocs/auth/auth_state.dart';
import 'package:cv_tech/presentation/views/auth/enter_otp_view.dart';
import 'package:cv_tech/presentation/widgets/auth/auth_button.dart';
import 'package:cv_tech/presentation/widgets/auth/auth_text_field.dart';
import 'package:cv_tech/core/l10n/app_localizations.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _acceptTerms = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Écouter les changements du mot de passe pour mettre à jour les indicateurs
    _passwordController.addListener(_updatePasswordIndicators);
  }

  void _updatePasswordIndicators() {
    // Debounce pour éviter trop de rebuilds pendant la saisie rapide
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          // Les indicateurs seront mis à jour
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSendOtp() {
    print('_onSendOtp called');

    if (!_acceptTerms) {
      print('Terms not accepted');
      AuthErrorHandler.showWarningAlert(
        context,
        title: '⚠️ Conditions requises',
        message:
            'Veuillez accepter les conditions d\'utilisation pour continuer.',
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      final email = _emailController.text.trim();
      print('Form valid, sending OTP to: $email');
      context.read<AuthBloc>().add(
            AuthSendOtpRequested(email: email),
          );
    } else {
      print('Form validation failed');
    }
  }

  RegisterRequest _buildRegisterRequest() {
    return RegisterRequest(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      userName: '', // Le backend génère automatiquement le username
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          print('RegisterView - State changed: ${state.runtimeType}');

          if (state is AuthOtpSent) {
            print('OTP Sent to: ${state.email}');

            // Afficher le succès de l'envoi
            AuthErrorHandler.showSuccessAlert(
              context,
              title: '📧 Code envoyé !',
              message: 'Un code de vérification a été envoyé à ${state.email}',
            );

            // Naviguer vers la page OTP (sans afficher le code)
            print('Navigating to EnterOtpView...');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EnterOtpView(
                  email: state.email,
                  userData: _buildRegisterRequest(),
                ),
              ),
            ).then((_) {
              print('Returned from EnterOtpView');
            });
          } else if (state is AuthError) {
            print('Auth Error: ${state.message}');
            // Utiliser le gestionnaire d'erreur personnalisé
            AuthErrorHandler.showErrorAlert(context, state.message);
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Dimensions.paddingLarge),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    Text(
                      AppLocalizations.of(context).createAccount,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.darkTextColor
                                    : AppColors.textColor,
                              ),
                    ),
                    const SizedBox(height: Dimensions.heightSmallVertical),
                    Text(
                      AppLocalizations.of(context).translate('fill_info_below'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? AppColors.darkTextMutedColor
                                : AppColors.textMutedColor,
                          ),
                    ),
                    const SizedBox(height: Dimensions.heightLargeVertical),

                    // First Name & Last Name
                    Row(
                      children: [
                        Expanded(
                          child: AuthTextField(
                            controller: _firstNameController,
                            label: '${AppLocalizations.of(context).firstName} *',
                            prefixIcon: Icons.person_outline,
                            textInputAction: TextInputAction.next,
                            validator: (value) => FormValidators.validateName(
                              value,
                              fieldName: 'Le prénom',
                            ),
                          ),
                        ),
                        const SizedBox(width: Dimensions.paddingMedium),
                        Expanded(
                          child: AuthTextField(
                            controller: _lastNameController,
                            label: '${AppLocalizations.of(context).lastName} *',
                            prefixIcon: Icons.person_outline,
                            textInputAction: TextInputAction.next,
                            validator: (value) => FormValidators.validateName(
                              value,
                              fieldName: 'Le nom',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Dimensions.heightMediumVertical),

                    // Email
                    AuthTextField(
                      controller: _emailController,
                      label: '${AppLocalizations.of(context).email} *',
                      hint: 'exemple@email.com',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: FormValidators.validateEmail,
                    ),
                    const SizedBox(height: Dimensions.heightMediumVertical),

                    // Password
                    AuthTextField(
                      controller: _passwordController,
                      label: '${AppLocalizations.of(context).password} *',
                      hint: 'Min. 6 caractères avec lettres et chiffres',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      textInputAction: TextInputAction.next,
                      validator: FormValidators.validatePassword,
                    ),
                    const SizedBox(height: Dimensions.heightSmallVertical),

                    // Password requirements hint
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPasswordRequirement(
                            AppLocalizations.of(context).atLeast6Chars,
                            _passwordController.text.length >= 6,
                          ),
                          _buildPasswordRequirement(
                            AppLocalizations.of(context).atLeastUppercase,
                            RegExp(r'[A-Z]').hasMatch(_passwordController.text),
                          ),
                          _buildPasswordRequirement(
                            AppLocalizations.of(context).atLeastLowercase,
                            RegExp(r'[a-z]').hasMatch(_passwordController.text),
                          ),
                          _buildPasswordRequirement(
                            AppLocalizations.of(context).atLeastDigit,
                            RegExp(r'[0-9]').hasMatch(_passwordController.text),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Dimensions.heightMediumVertical),

                    // Confirm Password
                    AuthTextField(
                      controller: _confirmPasswordController,
                      label: '${AppLocalizations.of(context).confirmPassword} *',
                      hint: 'Retapez votre mot de passe',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _onSendOtp(),
                      validator: FormValidators.validateConfirmPassword(
                        _passwordController.text,
                      ),
                    ),
                    const SizedBox(height: Dimensions.heightMediumVertical),

                    // Terms and conditions checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: _acceptTerms,
                            onChanged: (value) {
                              setState(() {
                                _acceptTerms = value ?? false;
                              });
                            },
                            activeColor: AppColors.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _acceptTerms = !_acceptTerms;
                              });
                            },
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.darkTextMutedColor
                                      : AppColors.textMutedColor,
                                  fontSize: 13,
                                ),
                                children: [
                                  const TextSpan(text: 'J\'accepte les '),
                                  TextSpan(
                                    text: 'conditions d\'utilisation',
                                    style: TextStyle(
                                      color: AppColors.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const TextSpan(text: ' et la '),
                                  TextSpan(
                                    text: 'politique de confidentialité',
                                    style: TextStyle(
                                      color: AppColors.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Dimensions.heightLargeVertical),

                    // Register button
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        return AuthButton(
                          text: AppLocalizations.of(context).createMyAccount,
                          onPressed: _onSendOtp,
                          isLoading:
                              state is AuthLoading || state is AuthSubmitting,
                        );
                      },
                    ),
                    const SizedBox(height: Dimensions.heightMediumVertical),

                    // Login link
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context).alreadyHaveAccount,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.darkTextMutedColor
                                : AppColors.textMutedColor,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            AppLocalizations.of(context).login,
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Dimensions.heightMediumVertical),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPasswordRequirement(String text, bool isMet) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasText = _passwordController.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            hasText
                ? (isMet ? Icons.check_circle : Icons.cancel)
                : Icons.circle_outlined,
            size: 14,
            color: hasText
                ? (isMet ? Colors.green : AppColors.errorColor)
                : (isDark
                    ? AppColors.darkTextMutedColor
                    : AppColors.textMutedColor),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: hasText
                  ? (isMet ? Colors.green : AppColors.errorColor)
                  : (isDark
                      ? AppColors.darkTextMutedColor
                      : AppColors.textMutedColor),
            ),
          ),
        ],
      ),
    );
  }
}
