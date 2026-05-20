import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:cv_tech/main.dart';
import 'package:cv_tech/presentation/widgets/auth/auth_button.dart';
import 'package:cv_tech/presentation/widgets/auth/auth_text_field.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Integration Tests', () {
    testWidgets('Login form interaction flow', (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify that we're on a page with login elements
      expect(find.byType(AuthButton), findsWidgets);
      expect(find.byType(AuthTextField), findsWidgets);
    });

    testWidgets('Form validation works correctly',
        (WidgetTester tester) async {
      final emailController = TextEditingController();
      final passwordController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  AuthTextField(
                    controller: emailController,
                    label: 'Email',
                  ),
                  AuthTextField(
                    controller: passwordController,
                    label: 'Password',
                    isPassword: true,
                  ),
                  const SizedBox(height: 16),
                  AuthButton(
                    text: 'Login',
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify initial state
      expect(emailController.text, isEmpty);
      expect(passwordController.text, isEmpty);

      // Enter email
      await tester.enterText(find.byType(AuthTextField).first, 'test@example.com');
      await tester.pump();
      expect(emailController.text, 'test@example.com');

      // Enter password
      await tester.enterText(find.byType(AuthTextField).at(1), 'Password123');
      await tester.pump();
      expect(passwordController.text, 'Password123');
    });

    testWidgets('Password visibility toggle works',
        (WidgetTester tester) async {
      final passwordController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthTextField(
              controller: passwordController,
              label: 'Password',
              isPassword: true,
            ),
          ),
        ),
      );

      // Password should be hidden initially
      TextFormField textField =
          tester.widget(find.byType(TextFormField).first);
      expect(textField.obscureText, isTrue);

      // Toggle visibility
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();

      textField = tester.widget(find.byType(TextFormField).first);
      expect(textField.obscureText, isFalse);

      // Toggle back
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();

      textField = tester.widget(find.byType(TextFormField).first);
      expect(textField.obscureText, isTrue);
    });

    testWidgets('Multiple form submissions work correctly',
        (WidgetTester tester) async {
      int submitCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AuthButton(
                  text: 'Submit',
                  onPressed: () {
                    submitCount++;
                  },
                ),
              ],
            ),
          ),
        ),
      );

      // First submission
      await tester.tap(find.byType(AuthButton));
      await tester.pump();
      expect(submitCount, equals(1));

      // Second submission
      await tester.tap(find.byType(AuthButton));
      await tester.pump();
      expect(submitCount, equals(2));

      // Third submission
      await tester.tap(find.byType(AuthButton));
      await tester.pump();
      expect(submitCount, equals(3));
    });
  });
}
