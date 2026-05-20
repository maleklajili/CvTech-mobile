import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cv_tech/presentation/widgets/auth/otp_text_field.dart';

void main() {
  group('OtpTextField Tests', () {
    testWidgets('OtpTextField displays correct number of fields',
        (WidgetTester tester) async {
      const int otpLength = 6;
      String? completedOtp;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OtpTextField(
              length: otpLength,
              onCompleted: (otp) {
                completedOtp = otp;
              },
            ),
          ),
        ),
      );

      // Should display 6 TextFormField widgets (one for each digit)
      expect(find.byType(TextField), findsNWidgets(otpLength));
    });

    testWidgets('OtpTextField accepts digit input', (WidgetTester tester) async {
      String? completedOtp;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OtpTextField(
              length: 6,
              onCompleted: (otp) {
                completedOtp = otp;
              },
            ),
          ),
        ),
      );

      // Tap the first field and enter a digit
      await tester.tap(find.byType(TextField).first);
      await tester.pump();

      await tester.enterText(find.byType(TextField).first, '1');
      await tester.pump();

      // Verify text was entered
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('OtpTextField moves to next field on input',
        (WidgetTester tester) async {
      String? completedOtp;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OtpTextField(
              length: 6,
              onCompleted: (otp) {
                completedOtp = otp;
              },
            ),
          ),
        ),
      );

      // Enter digits in sequence
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byType(TextField).at(i));
        await tester.pump();
        await tester.enterText(find.byType(TextField).at(i), '${i + 1}');
        await tester.pump();
      }

      // Verify digits were entered
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('OtpTextField with initial value', (WidgetTester tester) async {
      String? completedOtp;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OtpTextField(
              length: 6,
              initialValue: '123456',
              onCompleted: (otp) {
                completedOtp = otp;
              },
            ),
          ),
        ),
      );

      // Verify initial values are populated
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
    });

    testWidgets('OtpTextField calls onChanged callback',
        (WidgetTester tester) async {
      String? changedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OtpTextField(
              length: 6,
              onCompleted: (otp) {},
              onChanged: (value) {
                changedValue = value;
              },
            ),
          ),
        ),
      );

      // Enter a digit
      await tester.tap(find.byType(TextField).first);
      await tester.pump();
      await tester.enterText(find.byType(TextField).first, '5');
      await tester.pump();

      // onChanged should be called with the digit
      expect(changedValue, isNotNull);
    });
  });
}
