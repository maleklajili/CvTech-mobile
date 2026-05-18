import 'package:flutter_test/flutter_test.dart';

import 'package:cv_tech/core/config/network_config.dart';

void main() {
  group('NetworkConfig.isValidUrl', () {
    test('accepts valid http/https URLs', () {
      expect(NetworkConfig.isValidUrl('http://localhost:9000'), isTrue);
      expect(NetworkConfig.isValidUrl('https://example.com'), isTrue);
    });

    test('rejects invalid URLs', () {
      expect(NetworkConfig.isValidUrl(''), isFalse);
      expect(NetworkConfig.isValidUrl('localhost:9000'), isFalse);
      expect(NetworkConfig.isValidUrl('ftp://example.com'), isFalse);
    });
  });
}
