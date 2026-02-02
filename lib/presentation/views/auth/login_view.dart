// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/core/constants/dimension.dart';
import 'package:cv_tech/core/utils/auth_error_handler.dart';
import 'package:cv_tech/data/models/auth/login_request.dart';
import 'package:cv_tech/presentation/blocs/auth/auth_bloc.dart';
import 'package:cv_tech/presentation/blocs/auth/auth_event.dart';
import 'package:cv_tech/presentation/blocs/auth/auth_state.dart';
import 'package:cv_tech/presentation/views/auth/register_view.dart';
import 'package:cv_tech/presentation/views/auth/forgot_password_view.dart';
import 'package:cv_tech/presentation/views/test/api_test_view.dart';
import 'package:cv_tech/presentation/views/test/auth_debug_view.dart';
import 'package:cv_tech/presentation/widgets/auth/auth_button.dart';
import 'package:cv_tech/presentation/widgets/auth/auth_text_field.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    // Supprimer d'abord les anciens messages d'erreur
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            AuthLoginRequested(
              request: LoginRequest(
                identifier: _identifierController.text.trim(),
                password: _passwordController.text,
              ),
            ),
          );
    }
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterView()),
    );
  }

  void _navigateToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Debug: Auth Debug
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AuthDebugView()),
              );
            },
            icon: const Icon(Icons.developer_mode),
            tooltip: 'Auth Debug',
          ),
          // Debug: Test API button
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ApiTestView()),
              );
            },
            icon: const Icon(Icons.bug_report),
            tooltip: 'Test API',
          ),
        ],
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            print(
                'Login successful - AuthWrapper will handle navigation to home');
            AuthErrorHandler.showSuccessAlert(
              context,
              title: '✅ Connexion réussie',
              message: 'Bienvenue ! Vous êtes maintenant connecté.',
            );
          } else if (state is AuthError) {
            // Utiliser le gestionnaire d'erreur personnalisé
            AuthErrorHandler.showErrorAlert(context, state.message);
          }
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Dimensions.paddingLarge),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.disabled,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo/Icon
                    Icon(
                      Icons.person_outline,
                      size: 80,
                      color: AppColors.primaryColor,
                    ),
                    const SizedBox(height: Dimensions.heightMediumVertical),

                    // Title
                    Text(
                      'Bienvenue',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Dimensions.heightSmallVertical),

                    Text(
                      'Connectez-vous pour continuer',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Dimensions.heightLargeVertical),

                    // Email/Username field
                    AuthTextField(
                      controller: _identifierController,
                      label: 'Email ou nom d\'utilisateur',
                      hint: 'Entrez votre email ou username',
                      prefixIcon: Icons.person_outline,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ce champ est requis';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: Dimensions.heightMediumVertical),

                    // Password field
                    AuthTextField(
                      controller: _passwordController,
                      label: 'Mot de passe',
                      hint: 'Entrez votre mot de passe',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _onLogin(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le mot de passe est requis';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: Dimensions.heightSmallVertical),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _navigateToForgotPassword,
                        child: Text(
                          'Mot de passe oublié ?',
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: Dimensions.heightMediumVertical),

                    // Login button
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        return AuthButton(
                          text: 'Se connecter',
                          onPressed: _onLogin,
                          isLoading:
                              state is AuthLoading || state is AuthSubmitting,
                        );
                      },
                    ),
                    const SizedBox(height: Dimensions.heightLargeVertical),

                    // Register link
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        const Text(
                          'Pas encore de compte ? ',
                        ),
                        TextButton(
                          onPressed: _navigateToRegister,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'S\'inscrire',
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
