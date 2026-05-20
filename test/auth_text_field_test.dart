import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cv_tech/presentation/widgets/auth/auth_text_field.dart';

void main() {
  group('AuthTextField Tests', () {
    testWidgets('AuthTextField accepts text input', (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthTextField(
              controller: controller,
              label: 'Email',
            ),
          ),
        ),
      );

      // Find and tap the text field
      await tester.tap(find.byType(TextFormField));
      await tester.pump();

      // Enter text
      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      await tester.pump();

      // Verify text was entered
      expect(controller.text, 'test@example.com');
    });

    testWidgets('AuthTextField displays label', (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthTextField(
              controller: controller,
              label: 'Username',
            ),
          ),
        ),
      );

      // Verify label is displayed
      expect(find.text('Username'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('AuthTextField has visibility toggle for password',
        (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthTextField(
              controller: controller,
              label: 'Password',
              isPassword: true,
            ),
          ),
        ),
      );

      // Password field should show visibility icon
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      // Tap the visibility icon
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();

      // Icon should change to visibility
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('AuthTextField handles empty input', (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthTextField(
              controller: controller,
              label: 'Test',
            ),
          ),
        ),
      );

      // Verify controller is empty initially
      expect(controller.text, isEmpty);

      // Enter and clear text
      await tester.enterText(find.byType(TextFormField), 'test');
      await tester.pump();
      expect(controller.text, isNotEmpty);

      // Clear controller
      controller.clear();
      await tester.pump();
      expect(controller.text, isEmpty);
    });

    testWidgets('AuthTextField shows/hides password based on isPassword',
        (WidgetTester tester) async {
      final controller = TextEditingController();

      // Test with isPassword = true
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthTextField(
              controller: controller,
              label: 'Password',
              isPassword: true,
            ),
          ),
        ),
      );

      expect(find.byType(IconButton), findsOneWidget);

      // Test with isPassword = false
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthTextField(
              controller: controller,
              label: 'Email',
              isPassword: false,
            ),
          ),
        ),
      );

      // No icon button for regular text field
      expect(find.byType(IconButton), findsNothing);
    });
  });
}
