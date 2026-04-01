import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform, Uint8List;
import 'dart:io' show File;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

/// Centralized PDF download & share logic.
/// Avoids duplicating heavy imports (dart:io, printing, share_plus, path_provider)
/// across multiple views.
class PdfDownloadService {
  const PdfDownloadService._();

  /// Save PDF bytes to a temp file and share/download them.
  static Future<void> shareOrSave(Uint8List pdfBytes, String filename) async {
    final isMobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    if (isMobile) {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(pdfBytes);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        subject: filename,
      ));
    } else {
      await Printing.sharePdf(bytes: pdfBytes, filename: filename);
    }
  }
}
