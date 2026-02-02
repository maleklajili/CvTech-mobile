import 'dart:io';
import 'dart:convert';

Future<void> main() async {
  print('🔍 Testing connection to backend server...');
  print('Target URL: http://localhost:9000');
  
  try {
    final client = HttpClient();
    client.connectionTimeout = Duration(seconds: 5);
    
    // Test de connexion simple
    final request = await client.getUrl(Uri.parse('http://localhost:9000'));
    request.headers.set('User-Agent', 'Dart/Test Client');
    
    final response = await request.close();
    
    print('✅ Server responded with status: ${response.statusCode}');
    
    // Lire la réponse
    final responseBody = await response.transform(utf8.decoder).join();
    print('Response body: $responseBody');
    
    if (response.statusCode == 200) {
      print('✅ Backend server is running and accessible!');
    } else {
      print('⚠️  Server responded but with status: ${response.statusCode}');
    }
    
    client.close();
  } on SocketException catch (e) {
    print('❌ Socket error: $e');
    print('');
    print('This usually means:');
    print('1. Backend server is not running');
    print('2. Wrong port number (should be 9000)');
    print('3. Firewall blocking the connection');
  } catch (e) {
    print('❌ Other error: $e');
  }
}