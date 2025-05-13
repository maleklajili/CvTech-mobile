// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:cv_tech/app.dart';
import 'package:cv_tech/presentation/views_models/app/theme_view_model.dart';
import 'core/utils/preferences/theme_preference.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final savedTheme = await ThemePreference.shared.load() ?? ThemeMode.system;
  runApp(ChangeNotifierProvider(
      create: (context) => ThemeViewModel(context, savedTheme),
      child: const MyApp()));
}
