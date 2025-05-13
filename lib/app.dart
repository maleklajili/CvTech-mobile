// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:cv_tech/core/constants/app_strings.dart';
import 'package:cv_tech/presentation/views/main/main_view.dart';
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
        home: const MainView(),
      ),
    );
  }
}
