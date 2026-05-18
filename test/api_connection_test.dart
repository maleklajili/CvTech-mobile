import 'package:flutter_test/flutter_test.dart';
import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/core/env.dart';

void main() {
  group('API Connection Tests', () {
    test('should connect to backend server', () async {
      final apiClient = ApiClient();
      
      try {
        // Test simple ping to server
        final response = await apiClient.dio.get('$baseUrl');
        print('Server response status: ${response.statusCode}');
        
        // Si on arrive ici sans exception, la connexion fonctionne
        expect(response.statusCode, isNotNull);
      } catch (e) {
        print('Connection error: $e');
        // Le test échouera si la connexion n'est pas possible
        fail('Could not connect to backend server: $e');
      }
    }, skip: 'Requires backend server running');

    test('should have correct base URL configuration', () {
      print('Current base URL: $baseUrl');
      
      // Vérifier que l'URL est configurée
      expect(baseUrl.isNotEmpty, true);
      expect(baseUrl.contains('http'), true);
      expect(baseUrl.contains(':9000'), true);
    });
  });
}