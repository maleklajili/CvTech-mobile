// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:dio/dio.dart';

// Project imports:
import 'package:cv_tech/core/env.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/presentation/widgets/auth/auth_button.dart';

/// Page de debug pour tester les endpoints d'authentification
class AuthDebugView extends StatefulWidget {
  const AuthDebugView({super.key});

  @override
  State<AuthDebugView> createState() => _AuthDebugViewState();
}

class _AuthDebugViewState extends State<AuthDebugView> {
  final _dio = Dio(BaseOptions(baseUrl: baseUrl));
  final _emailController = TextEditingController(text: 'test@example.com');
  final _passwordController = TextEditingController(text: 'Test123456');
  String _response = '';
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _loading = true;
      _response = 'Testing connection...';
    });

    try {
      final response = await _dio.get('/');
      setState(() {
        _response = 'Connection OK!\nStatus: ${response.statusCode}';
      });
    } catch (e) {
      setState(() {
        _response = 'Connection ERROR:\n$e';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _testSendOtp() async {
    setState(() {
      _loading = true;
      _response = 'Sending OTP...';
    });

    try {
      final email = _emailController.text;
      final response = await _dio.post('/auth/send-otp/$email');
      setState(() {
        _response = 'Send OTP SUCCESS!\n'
            'Status: ${response.statusCode}\n'
            'Response: ${response.data}';
      });
    } catch (e) {
      if (e is DioException) {
        setState(() {
          _response = 'Send OTP ERROR:\n'
              'Status: ${e.response?.statusCode}\n'
              'Message: ${e.message}\n'
              'Data: ${e.response?.data}';
        });
      } else {
        setState(() {
          _response = 'Send OTP ERROR:\n$e';
        });
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _testLogin() async {
    setState(() {
      _loading = true;
      _response = 'Testing login...';
    });

    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'identifier': _emailController.text,
          'password': _passwordController.text,
        },
      );
      setState(() {
        _response = 'Login SUCCESS!\n'
            'Status: ${response.statusCode}\n'
            'Response: ${response.data}';
      });
    } catch (e) {
      if (e is DioException) {
        setState(() {
          _response = 'Login ERROR:\n'
              'Status: ${e.response?.statusCode}\n'
              'Message: ${e.message}\n'
              'Data: ${e.response?.data}\n'
              'URL: ${e.requestOptions.uri}';
        });
      } else {
        setState(() {
          _response = 'Login ERROR:\n$e';
        });
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth Debug'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Base URL Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configuration',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Base URL: $baseUrl'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Email Input
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Password Input
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),

            // Test Buttons
            AuthButton(
              text: 'Test Connection (GET /)',
              onPressed: _testConnection,
              isLoading: _loading,
            ),
            const SizedBox(height: 12),
            AuthButton(
              text: 'Test Send OTP',
              onPressed: _testSendOtp,
              isLoading: _loading,
            ),
            const SizedBox(height: 12),
            AuthButton(
              text: 'Test Login',
              onPressed: _testLogin,
              isLoading: _loading,
            ),
            const SizedBox(height: 24),

            // Response Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Response',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _response.isEmpty ? 'No response yet' : _response,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
