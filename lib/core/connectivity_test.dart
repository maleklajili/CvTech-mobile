// Test connectivity helper
import 'package:dio/dio.dart';

class ConnectivityTest {
  static Future<void> testBackendConnection(String baseUrl) async {
    print('🔍 Test de connexion au backend...');
    print('URL cible: $baseUrl');
    
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ));

    try {
      final response = await dio.get('/user/current-user');
      print('✅ Connexion réussie!');
      print('Status: ${response.statusCode}');
      print('Response: ${response.data}');
    } on DioException catch (e) {
      print('❌ Erreur de connexion:');
      print('Type: ${e.type}');
      print('Message: ${e.message}');
      if (e.response != null) {
        print('Response Status: ${e.response!.statusCode}');
        print('Response Data: ${e.response!.data}');
      }
    } catch (e) {
      print('❌ Erreur inattendue: $e');
    }
  }
}
