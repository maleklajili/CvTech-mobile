// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:cv_tech/app.dart';
import 'package:cv_tech/presentation/blocs/auth/auth_bloc.dart';
import 'package:cv_tech/presentation/blocs/auth/auth_event.dart';
import 'package:cv_tech/presentation/views_models/app/theme_view_model.dart';
import 'package:cv_tech/presentation/views_models/app/locale_view_model.dart';
import 'package:cv_tech/core/utils/image_url_helper.dart';
import 'core/utils/preferences/theme_preference.dart';
import 'core/utils/preferences/locale_preference.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser les données de locale pour le formatage des dates
  await initializeDateFormatting('fr_FR', null);

  // Initialiser l'URL des médias dès le démarrage.
  await ImageUrlHelper.initialize();
  
  final savedTheme = await ThemePreference.shared.load() ?? ThemeMode.system;
  final savedLocale = await LocalePreference.shared.load() ?? 'fr';
  
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc()..add(const AuthCheckRequested()),
        ),
      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) => ThemeViewModel(context, savedTheme),
          ),
          ChangeNotifierProvider(
            create: (context) => LocaleViewModel(context, savedLocale),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}
