import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cv_tech/presentation/widgets/auth/auth_text_field.dart';

void main() {
  testWidgets('AuthTextField toggles password visibility', (WidgetTester tester) async {
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

    TextFormField textField = tester.widget(find.byType(TextFormField));
    expect(textField.obscureText, isTrue);

    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pump();

    textField = tester.widget(find.byType(TextFormField));
    expect(textField.obscureText, isFalse);
  });
}
