import 'package:flutter_test/flutter_test.dart';

import 'package:cv_tech/core/utils/image_url_helper.dart';

void main() {
  setUp(() {
    ImageUrlHelper.setBaseUrl('http://example.com');
  });

  tearDown(() {
    ImageUrlHelper.clearCache();
  });

  group('ImageUrlHelper', () {
    test('getImageUrlSync builds profile image URL', () {
      final url = ImageUrlHelper.getImageUrlSync('avatar.png', '123');
      expect(url, 'http://example.com/uploads/images-123/avatar.png');
    });

    test('getImageUrlSync returns full URL when provided', () {
      final url = ImageUrlHelper.getImageUrlSync('https://cdn.com/a.png', '123');
      expect(url, 'https://cdn.com/a.png');
    });

    test('resolveMaybeUrlSync resolves relative URLs', () {
      expect(
        ImageUrlHelper.resolveMaybeUrlSync('/uploads/test.png'),
        'http://example.com/uploads/test.png',
      );
      expect(
        ImageUrlHelper.resolveMaybeUrlSync('uploads/test.png'),
        'http://example.com/uploads/test.png',
      );
    });

    test('getMessageMediaUrlSync builds message media URL', () {
      final url = ImageUrlHelper.getMessageMediaUrlSync('file.jpg', 'abc');
      expect(url, 'http://example.com/uploads/images-abc/messages/file.jpg');
    });
  });
}
