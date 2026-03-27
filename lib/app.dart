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

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
BuildContext? get mainContext => _navigatorKey.currentContext;

NavigatorState? get mainState => _navigatorKey.currentState;

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
        initialRoute: '/',
        onGenerateInitialRoutes: (String initialRouteName) {
          return [
            MaterialPageRoute<void>(
              builder: (_) => const _RootGuard(child: AuthWrapper()),
              settings: const RouteSettings(name: '/'),
            ),
          ];
        },
        builder: (context, child) {
          AppTheme.syncWithContext(context);
          return child ?? const _RootGuard(child: AuthWrapper());
        },
        routes: {
          '/': (context) => const _RootGuard(child: AuthWrapper()),
          '/create': (context) => const _RootGuard(child: AuthWrapper()), // Placeholder
          '/home': (context) => const MainView(),
        },
        onUnknownRoute: (settings) {
          // Route fallback - rediriger vers la page d'accueil
          return MaterialPageRoute(
            builder: (context) => const _RootGuard(child: AuthWrapper()),
            settings: const RouteSettings(name: '/'),
          );
        },
      ),
    );
  }
}

class _RootGuard extends StatelessWidget {
  final Widget child;

  const _RootGuard({required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(canPop: false, child: child);
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
        if (!_splashCompleted) {
          return const SplashScreen();
        }

        if (state is AuthAuthenticated) {
          return const MainView();
        }

        if (state is AuthInitial || state is AuthLoading) {
          return const SplashScreen();
        }

        return const LoginView();
      },
    );
  }
}
