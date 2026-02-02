// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:cv_tech/core/constants/app_strings.dart';
import 'package:cv_tech/presentation/blocs/auth/auth_bloc.dart';
import 'package:cv_tech/presentation/blocs/auth/auth_state.dart';
import 'package:cv_tech/presentation/views/auth/login_view.dart';
import 'package:cv_tech/presentation/views/main/main_view.dart';
import 'package:cv_tech/presentation/views/splash/splash_screen.dart';
import 'package:cv_tech/presentation/views_models/app/theme_view_model.dart';
import 'package:cv_tech/theme/app_theme.dart';

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey();
BuildContext get mainContext => _navigatorKey.currentContext!;

NavigatorState get mainState => _navigatorKey.currentState!;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeViewModel>(
      builder: (context, themeViewModel, child) => MaterialApp(
        navigatorKey: _navigatorKey,
        debugShowCheckedModeBanner: false,
        title: AppStrings.appName,
        darkTheme: AppTheme.darkTheme,
        theme: AppTheme.lightTheme,
        themeMode: themeViewModel.themeMode,
        home: const AuthWrapper(),
        routes: {
          '/create': (context) => const AuthWrapper(), // Placeholder
          '/home': (context) => const MainView(),
        },
        onUnknownRoute: (settings) {
          // Route fallback - rediriger vers la page d'accueil
          return MaterialPageRoute(
            builder: (context) => const AuthWrapper(),
          );
        },
      ),
    );
  }
}

/// Widget qui gère la navigation entre les écrans d'auth et l'app principale
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _splashCompleted = false;
  bool _hasShownContent = false;

  @override
  void initState() {
    super.initState();
    _startSplashTimer();
  }

  void _startSplashTimer() {
    // Afficher le splash screen pendant 2 secondes
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _splashCompleted = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        print('🟠 AuthWrapper: State changed to ${state.runtimeType}');
        
        // Afficher le splash screen au démarrage (pendant le loading initial)
        // Mais PAS pendant les tentatives de login/register
        if ((state is AuthInitial || state is AuthLoading) && !_hasShownContent) {
          print('⏳ AuthWrapper: Loading state - Showing SplashScreen');
          return const SplashScreen();
        }
        
        // Si le splash n'est pas encore terminé, continuer à l'afficher
        if (!_splashCompleted && !_hasShownContent) {
          print('⏳ AuthWrapper: Splash not completed - Showing SplashScreen');
          return const SplashScreen();
        }
        
        if (state is AuthAuthenticated) {
          print('✅ AuthWrapper: Authenticated - Showing MainView');
          _hasShownContent = true;
          return const MainView();
        }
        
        // Pour AuthUnauthenticated, AuthError, ou après le splash
        print('❌ AuthWrapper: Showing LoginView (state: ${state.runtimeType})');
        _hasShownContent = true;
        return const LoginView();
      },
    );
  }
}
