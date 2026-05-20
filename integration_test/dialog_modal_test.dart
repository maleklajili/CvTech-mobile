import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:cv_tech/presentation/widgets/common/custom_alert_dialog.dart';
import 'package:cv_tech/presentation/widgets/auth/auth_button.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Dialog and Modal Integration Tests', () {
    testWidgets('Alert dialog can be opened and closed',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AuthButton(
                text: 'Show Dialog',
                onPressed: () {
                  showDialog(
                    context: tester.element(find.byType(AuthButton)),
                    builder: (BuildContext context) {
                      return CustomAlertDialog(
                        title: 'Confirmation',
                        message: 'Do you want to continue?',
                        positiveButtonText: 'Yes',
                        negativeButtonText: 'No',
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Dialog should not be visible initially
      expect(find.text('Confirmation'), findsNothing);

      // Open dialog
      await tester.tap(find.byType(AuthButton));
      await tester.pumpAndSettle();

      // Dialog should now be visible
      expect(find.text('Confirmation'), findsOneWidget);
      expect(find.text('Do you want to continue?'), findsOneWidget);
      expect(find.text('Yes'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);

      // Close dialog by tapping No
      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.text('Confirmation'), findsNothing);
    });

    testWidgets('Dialog callback is triggered on positive button',
        (WidgetTester tester) async {
      bool positivePressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AuthButton(
                text: 'Show Dialog',
                onPressed: () {
                  showDialog(
                    context: tester.element(find.byType(AuthButton)),
                    builder: (BuildContext context) {
                      return CustomAlertDialog(
                        title: 'Test',
                        message: 'Message',
                        positiveButtonText: 'Confirm',
                        onPositivePressed: () {
                          positivePressed = true;
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AuthButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(positivePressed, isTrue);
    });

    testWidgets('Multiple dialogs can be shown sequentially',
        (WidgetTester tester) async {
      int dialogCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AuthButton(
                text: 'Show Dialogs',
                onPressed: () {
                  for (int i = 0; i < 3; i++) {
                    showDialog(
                      context: tester.element(find.byType(AuthButton)),
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Dialog'),
                          content: Text('Dialog $i'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                dialogCount++;
                                Navigator.pop(context);
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AuthButton));
      await tester.pumpAndSettle();

      // Close dialog 1
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(dialogCount, equals(1));
    });

    testWidgets('Dialog with custom styling displays correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AuthButton(
                text: 'Show Styled Dialog',
                onPressed: () {
                  showDialog(
                    context: tester.element(find.byType(AuthButton)),
                    builder: (BuildContext context) {
                      return CustomAlertDialog(
                        title: 'Styled Title',
                        message: 'This is a custom styled message with more details.',
                        positiveButtonText: 'Accept',
                        negativeButtonText: 'Decline',
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(AuthButton));
      await tester.pumpAndSettle();

      expect(find.text('Styled Title'), findsOneWidget);
      expect(find.text('This is a custom styled message with more details.'),
          findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
    });
  });
}
