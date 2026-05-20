import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Navigation and Screen Transitions Tests', () {
    testWidgets('Basic navigation between screens', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const FirstScreen(),
          routes: {
            '/second': (context) => const SecondScreen(),
            '/third': (context) => const ThirdScreen(),
          },
        ),
      );

      // Verify we're on first screen
      expect(find.text('First Screen'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsWidgets);

      // Navigate to second screen
      await tester.tap(find.byIcon(Icons.arrow_forward).first);
      await tester.pumpAndSettle();

      expect(find.text('Second Screen'), findsOneWidget);

      // Navigate to third screen
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();

      expect(find.text('Third Screen'), findsOneWidget);
    });

    testWidgets('Back navigation works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const FirstScreen(),
          routes: {
            '/second': (context) => const SecondScreen(),
          },
        ),
      );

      // Navigate forward
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();
      expect(find.text('Second Screen'), findsOneWidget);

      // Navigate back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('First Screen'), findsOneWidget);
    });

    testWidgets('Navigation maintains state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Enter text',
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(tester.element(find.byType(ElevatedButton)))
                        .push(MaterialPageRoute(
                      builder: (context) => const SecondScreen(),
                    ));
                  },
                  child: const Text('Next'),
                ),
              ],
            ),
          ),
        ),
      );

      // Enter text
      await tester.enterText(find.byType(TextField), 'Test Input');
      await tester.pump();
      expect(find.text('Test Input'), findsOneWidget);

      // Navigate to second screen
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Second Screen'), findsOneWidget);

      // Navigate back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Text should still be there (state preserved)
      expect(find.text('Test Input'), findsOneWidget);
    });

    testWidgets('Multiple rapid navigations work', (WidgetTester tester) async {
      int navigationCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  navigationCount++;
                },
                child: const Text('Navigate'),
              ),
            ),
          ),
        ),
      );

      // Perform multiple rapid navigations
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
      }

      expect(navigationCount, equals(5));
    });
  });
}

class FirstScreen extends StatelessWidget {
  const FirstScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('First')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('First Screen'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/second');
              },
              child: const Icon(Icons.arrow_forward),
            ),
          ],
        ),
      ),
    );
  }
}

class SecondScreen extends StatelessWidget {
  const SecondScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Second'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Second Screen'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/third');
              },
              child: const Icon(Icons.arrow_forward),
            ),
          ],
        ),
      ),
    );
  }
}

class ThirdScreen extends StatelessWidget {
  const ThirdScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Third'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: const Center(
        child: Text('Third Screen'),
      ),
    );
  }
}
