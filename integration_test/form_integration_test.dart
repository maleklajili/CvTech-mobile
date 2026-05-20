import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Form Integration Tests', () {
    testWidgets('Form submission with valid data', (WidgetTester tester) async {
      bool submitted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestForm(
              onSubmit: () {
                submitted = true;
              },
            ),
          ),
        ),
      );

      // Fill form fields
      await tester.enterText(find.byType(TextField).at(0), 'John Doe');
      await tester.enterText(find.byType(TextField).at(1), 'john@example.com');
      await tester.enterText(find.byType(TextField).at(2), 'Password123');
      await tester.pump();

      // Submit form
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(submitted, isTrue);
    });

    testWidgets('Form validation shows error messages',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestFormWithValidation(),
          ),
        ),
      );

      // Try to submit empty form
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Error messages should be displayed
      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('Form field focus management', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestForm(),
          ),
        ),
      );

      // Focus on first field
      await tester.tap(find.byType(TextField).at(0));
      await tester.pump();

      // Type in first field
      await tester.enterText(find.byType(TextField).at(0), 'Test Name');
      await tester.pump();

      // Move to next field
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      expect(find.text('Test Name'), findsOneWidget);
    });

    testWidgets('Form clear button resets all fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestFormWithClear(),
          ),
        ),
      );

      // Fill form
      await tester.enterText(find.byType(TextField).at(0), 'John');
      await tester.enterText(find.byType(TextField).at(1), 'john@test.com');
      await tester.pump();

      expect(find.text('John'), findsOneWidget);
      expect(find.text('john@test.com'), findsOneWidget);

      // Click clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      // Fields should be empty
      final nameField = find.byType(TextField).at(0);
      expect(tester.widget<TextField>(nameField).controller?.text, isEmpty);
    });

    testWidgets('Form handles special characters', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TestForm(),
          ),
        ),
      );

      // Enter text with special characters
      await tester.enterText(find.byType(TextField).at(1), 'test+special@example.com');
      await tester.pump();

      expect(find.text('test+special@example.com'), findsOneWidget);
    });
  });
}

class TestForm extends StatefulWidget {
  final VoidCallback? onSubmit;

  const TestForm({
    Key? key,
    this.onSubmit,
  }) : super(key: key);

  @override
  State<TestForm> createState() => _TestFormState();
}

class _TestFormState extends State<TestForm> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: widget.onSubmit,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

class TestFormWithValidation extends StatefulWidget {
  const TestFormWithValidation({Key? key}) : super(key: key);

  @override
  State<TestFormWithValidation> createState() => _TestFormWithValidationState();
}

class _TestFormWithValidationState extends State<TestFormWithValidation> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Email is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  formKey.currentState?.validate();
                },
                child: const Text('Validate'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }
}

class TestFormWithClear extends StatefulWidget {
  const TestFormWithClear({Key? key}) : super(key: key);

  @override
  State<TestFormWithClear> createState() => _TestFormWithClearState();
}

class _TestFormWithClearState extends State<TestFormWithClear> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('Submit'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    nameController.clear();
                    emailController.clear();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }
}
