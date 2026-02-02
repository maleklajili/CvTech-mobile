// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:dio/dio.dart';

// Project imports:
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/core/constants/dimension.dart';
import 'package:cv_tech/core/env.dart';

class ApiTestView extends StatefulWidget {
  const ApiTestView({super.key});

  @override
  State<ApiTestView> createState() => _ApiTestViewState();
}

class _ApiTestViewState extends State<ApiTestView> {
  final _dio = Dio(BaseOptions(baseUrl: baseUrl));
  final _emailController = TextEditingController();
  
  bool _isLoading = false;
  String? _result;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _result = null;
      _error = null;
    });

    try {
      final response = await _dio.get('/');
      setState(() {
        _result = 'Backend connecté !\n\nRéponse: ${response.data}';
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur de connexion: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testSendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _error = 'Veuillez entrer un email';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null;
      _error = null;
    });

    try {
      final response = await _dio.post('/auth/send-otp/$email');
      setState(() {
        _result = 'OTP envoyé avec succès !\n\nRéponse: ${response.data}';
      });
    } catch (e) {
      if (e is DioException) {
        setState(() {
          _error = 'Erreur: ${e.response?.data ?? e.message}';
        });
      } else {
        setState(() {
          _error = 'Erreur: $e';
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testLogin() async {
    setState(() {
      _isLoading = true;
      _result = null;
      _error = null;
    });

    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'identifier': 'test@example.com',
          'password': 'test123',
        },
      );
      setState(() {
        _result = 'Login réussi !\n\nRéponse: ${response.data}';
      });
    } catch (e) {
      if (e is DioException) {
        setState(() {
          _error = 'Erreur: ${e.response?.data ?? e.message}';
        });
      } else {
        setState(() {
          _error = 'Erreur: $e';
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test API Backend'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Dimensions.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // API URL
              Container(
                padding: const EdgeInsets.all(Dimensions.paddingMedium),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceColor : Colors.grey.shade100,
                  borderRadius: Dimensions.mediumBorderRadius,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'URL de l\'API:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextColor : AppColors.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      baseUrl,
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Dimensions.heightLargeVertical),

              // Test Connection Button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _testConnection,
                icon: const Icon(Icons.wifi),
                label: const Text('Tester la connexion'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: Dimensions.heightMediumVertical),

              // Email input for OTP test
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email pour test OTP',
                  hintText: 'exemple@email.com',
                  border: OutlineInputBorder(
                    borderRadius: Dimensions.mediumBorderRadius,
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: Dimensions.heightSmallVertical),

              // Test Send OTP Button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _testSendOtp,
                icon: const Icon(Icons.email),
                label: const Text('Envoyer OTP'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: Dimensions.heightMediumVertical),

              // Test Login Button
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _testLogin,
                icon: const Icon(Icons.login),
                label: const Text('Tester Login (demo)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: Dimensions.heightLargeVertical),

              // Loading indicator
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                ),

              // Result
              if (_result != null) ...[
                Container(
                  padding: const EdgeInsets.all(Dimensions.paddingMedium),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green),
                    borderRadius: Dimensions.mediumBorderRadius,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'Succès',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _result!,
                        style: TextStyle(
                          color: Colors.green.shade900,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Error
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(Dimensions.paddingMedium),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red),
                    borderRadius: Dimensions.mediumBorderRadius,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            'Erreur',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: Dimensions.heightLargeVertical),

              // Instructions
              Container(
                padding: const EdgeInsets.all(Dimensions.paddingMedium),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceColor : Colors.blue.shade50,
                  borderRadius: Dimensions.mediumBorderRadius,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: isDark ? AppColors.primaryColor : Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Instructions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextColor : Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Cliquez sur "Tester la connexion" pour vérifier que le backend est accessible\n\n'
                      '2. Entrez un email et cliquez sur "Envoyer OTP" pour tester l\'envoi d\'un code\n\n'
                      '3. Le backend doit être en cours d\'exécution sur le port 9000',
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextMutedColor : Colors.blue.shade900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
