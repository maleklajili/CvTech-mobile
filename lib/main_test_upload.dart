// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:cv_tech/presentation/blocs/auth/auth_bloc.dart';
import 'package:cv_tech/presentation/blocs/auth/auth_event.dart';
import 'package:cv_tech/presentation/views_models/app/theme_view_model.dart';
import 'package:cv_tech/presentation/views/test/test_image_upload_view.dart';
import 'core/utils/preferences/theme_preference.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser les données de locale pour le formatage des dates
  await initializeDateFormatting('fr_FR', null);
  
  final savedTheme = await ThemePreference.shared.load() ?? ThemeMode.system;
  
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc()..add(const AuthCheckRequested()),
        ),
      ],
      child: ChangeNotifierProvider(
        create: (context) => ThemeViewModel(context, savedTheme),
        child: const TestImageUploadApp(),
      ),
    ),
  );
}

class TestImageUploadApp extends StatelessWidget {
  const TestImageUploadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeViewModel>(
      builder: (context, themeViewModel, child) {
        return MaterialApp(
          title: 'Test Upload Image',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeViewModel.themeMode,
          debugShowCheckedModeBanner: false,
          home: const TestImageUploadView(),
        );
      },
    );
  }
}