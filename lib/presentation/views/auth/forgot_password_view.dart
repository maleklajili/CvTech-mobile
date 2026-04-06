// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/core/constants/dimension.dart';
import 'package:cv_tech/core/utils/auth_error_handler.dart';
import 'package:cv_tech/presentation/blocs/auth/auth_bloc.dart';
import 'package:cv_tech/presentation/blocs/auth/auth_event.dart';
import 'package:cv_tech/presentation/blocs/auth/auth_state.dart';
import 'package:cv_tech/presentation/widgets/auth/auth_button.dart';
import 'package:cv_tech/presentation/widgets/auth/auth_text_field.dart';
import 'package:cv_tech/core/l10n/app_localizations.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onSendResetLink() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            AuthForgotPasswordRequested(email: _emailController.text.trim()),
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
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthPasswordResetSent) {
            AuthErrorHandler.showSuccessAlert(
              context,
              title: '✉️ Email envoyé',
              message:
                  'Vérifiez votre boîte de réception (et les spams) pour réinitialiser votre mot de passe.',
            );
            Navigator.pop(context);
          } else if (state is AuthError) {
            // Utiliser le gestionnaire d'erreur personnalisé
            AuthErrorHandler.showErrorAlert(context, state.message);
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Dimensions.paddingLarge),
            child: Form(
              key: _formKey,
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
                      Icons.lock_reset,
                      size: 60,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: Dimensions.heightLargeVertical),

                  // Title
                  Text(
                    AppLocalizations.of(context).resetPassword,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Dimensions.heightSmallVertical),

                  // Description
                  Text(
                    AppLocalizations.of(context).enterEmailReset,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Dimensions.heightXLargeVertical),

                  // Email field
                  AuthTextField(
                    controller: _emailController,
                    label: AppLocalizations.of(context).email,
                    hint: AppLocalizations.of(context).email,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _onSendResetLink(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context).requiredField;
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Email invalide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: Dimensions.heightLargeVertical),

                  // Send button
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return AuthButton(
                        text: AppLocalizations.of(context).resetPassword,
                        onPressed: _onSendResetLink,
                        isLoading:
                            state is AuthLoading || state is AuthSubmitting,
                      );
                    },
                  ),
                  const SizedBox(height: Dimensions.heightMediumVertical),

                  // Back to login
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      AppLocalizations.of(context).backToLogin,
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
