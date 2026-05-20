import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cv_tech/presentation/widgets/common/custom_alert_dialog.dart';

void main() {
  group('CustomAlertDialog Tests', () {
    testWidgets('CustomAlertDialog displays title and message',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return CustomAlertDialog(
                            title: 'Test Title',
                            message: 'Test Message',
                            positiveButtonText: 'OK',
                          );
                        },
                      );
                    },
                    child: const Text('Show Dialog'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Initial state: no dialog
      expect(find.text('Test Title'), findsNothing);

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Dialog should be displayed
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Message'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('CustomAlertDialog displays with buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return CustomAlertDialog(
                            title: 'Confirmation',
                            message: 'Are you sure?',
                            positiveButtonText: 'Yes',
                            negativeButtonText: 'No',
                          );
                        },
                      );
                    },
                    child: const Text('Show Dialog'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Both buttons should be visible
      expect(find.text('Yes'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);
    });

    testWidgets('CustomAlertDialog closes when button tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return CustomAlertDialog(
                            title: 'Test',
                            message: 'Message',
                            positiveButtonText: 'OK',
                          );
                        },
                      );
                    },
                    child: const Text('Show Dialog'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();
      expect(find.text('Test'), findsOneWidget);

      // Close dialog by tapping OK
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.text('Test'), findsNothing);
    });
  });
}
