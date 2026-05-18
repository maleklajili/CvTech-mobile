// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:cv_tech/presentation/widgets/auth/auth_button.dart';

void main() {
  testWidgets('AuthButton shows label when not loading', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AuthButton(text: 'Se connecter'),
        ),
      ),
    );

    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.byType(SpinKitThreeBounce), findsNothing);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('AuthButton shows spinner when loading', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AuthButton(text: 'Connexion', isLoading: true),
        ),
      ),
    );

    expect(find.byType(SpinKitThreeBounce), findsOneWidget);
    expect(find.text('Connexion'), findsNothing);
  });
}
