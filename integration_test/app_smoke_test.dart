import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:cv_tech/presentation/widgets/auth/auth_button.dart';
import 'package:cv_tech/presentation/widgets/auth/auth_text_field.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('basic UI interactions work', (WidgetTester tester) async {
    bool tapped = false;
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AuthTextField(
                controller: controller,
                label: 'Password',
                isPassword: true,
              ),
              const SizedBox(height: 16),
              AuthButton(
                text: 'Tester',
                onPressed: () {
                  tapped = true;
                },
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pump();

    await tester.tap(find.text('Tester'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
