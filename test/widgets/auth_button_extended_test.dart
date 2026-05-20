import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cv_tech/presentation/widgets/auth/auth_button.dart';

void main() {
  group('AuthButton Extended Tests', () {
    testWidgets('AuthButton displays icon when provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthButton(
              text: 'Login with Google',
              icon: Icons.login,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.login), findsOneWidget);
      expect(find.text('Login with Google'), findsOneWidget);
    });

    testWidgets('AuthButton respects custom width and height',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthButton(
              text: 'Custom Size',
              width: 200,
              height: 60,
            ),
          ),
        ),
      );

      final button = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(button.width, equals(200));
      expect(button.height, equals(60));
    });

    testWidgets('AuthButton outlined style displays correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthButton(
              text: 'Outlined Button',
              isOutlined: true,
            ),
          ),
        ),
      );

      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.text('Outlined Button'), findsOneWidget);
    });

    testWidgets('AuthButton disables when loading', (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthButton(
              text: 'Loading Button',
              isLoading: true,
              onPressed: () {
                wasPressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(wasPressed, isFalse);
    });

    testWidgets('AuthButton calls onPressed when not loading',
        (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthButton(
              text: 'Click Me',
              onPressed: () {
                wasPressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(wasPressed, isTrue);
    });

    testWidgets('AuthButton handles null onPressed gracefully',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuthButton(
              text: 'No Action',
            ),
          ),
        ),
      );

      expect(find.text('No Action'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('AuthButton default height is 50',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuthButton(
              text: 'Default Height',
            ),
          ),
        ),
      );

      final button = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(button.height, equals(50));
    });
  });
}
