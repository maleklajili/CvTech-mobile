import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'cv_templates/standard_template.dart';
import 'cv_templates/modern_template.dart';

enum CvTemplate { standard, modern }

class CvPdfGenerator {
  /// Build a PDF from structured profile data using a template.
  static Future<void> generateFromProfile({
    required Map<String, dynamic> sections,
    required CvTemplate template,
    Uint8List? photoBytes,
    String title = 'Mon CV',
  }) async {
    pw.Document pdf;

    switch (template) {
      case CvTemplate.modern:
        pdf = await ModernCvTemplate.build(
          sections: sections,
          photoBytes: photoBytes,
        );
        break;
      case CvTemplate.standard:
      default:
        pdf = await StandardCvTemplate.build(
          sections: sections,
          photoBytes: photoBytes,
        );
    }

    final bytes = await pdf.save();
    await _shareOrSave(bytes, title);
  }

  /// Generate a PDF from markdown text content (fallback for AI content).
  static Future<void> generateAndShare(
    String title,
    String markdownContent,
  ) async {
    final regular = await PdfGoogleFonts.openSansRegular();
    final bold = await PdfGoogleFonts.openSansBold();
    final italic = await PdfGoogleFonts.openSansItalic();
    final boldItalic = await PdfGoogleFonts.openSansBoldItalic();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: regular,
        bold: bold,
        italic: italic,
        boldItalic: boldItalic,
      ),
    );
    final lines = markdownContent.split('\n');
    final widgets = <pw.Widget>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        widgets.add(pw.SizedBox(height: 6));
        continue;
      }
      if (trimmed.startsWith('# ')) {
        widgets.add(_heading(trimmed.substring(2), 22, PdfColors.blueGrey800));
      } else if (trimmed.startsWith('## ')) {
        widgets.add(_sectionHeading(trimmed.substring(3)));
      } else if (trimmed.startsWith('### ')) {
        widgets.add(_heading(trimmed.substring(4), 13, PdfColors.blueGrey600));
      } else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        widgets.add(_bullet(trimmed.substring(2)));
      } else if (trimmed.startsWith('---') || trimmed.startsWith('___')) {
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 8),
          child: pw.Divider(thickness: 0.5, color: PdfColors.grey300),
        ));
      } else {
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: _buildRichText(trimmed),
        ));
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => widgets,
      ),
    );

    final bytes = await pdf.save();
    await _shareOrSave(bytes, title);
  }

  static Future<void> _shareOrSave(Uint8List bytes, String title) async {
    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: '$title.pdf');
    } else {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$title.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], subject: title);
    }
  }

  static pw.Widget _heading(String text, double size, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8, top: 4),
      child: pw.Text(
        _clean(text),
        style: pw.TextStyle(fontSize: size, fontWeight: pw.FontWeight.bold, color: color),
      ),
    );
  }

  static pw.Widget _sectionHeading(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 12, bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _clean(text),
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey700,
            ),
          ),
          pw.Divider(thickness: 0.5, color: PdfColors.grey400),
        ],
      ),
    );
  }

  static pw.Widget _bullet(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(left: 16, bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 4,
            height: 4,
            margin: const pw.EdgeInsets.only(top: 5, right: 8),
            decoration: const pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              color: PdfColors.grey700,
            ),
          ),
          pw.Expanded(child: _buildRichText(text)),
        ],
      ),
    );
  }

  static pw.Widget _buildRichText(String text) {
    final spans = <pw.InlineSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*|`(.+?)`|([^*`]+)');

    for (final match in regex.allMatches(text)) {
      if (match.group(1) != null) {
        spans.add(pw.TextSpan(
          text: match.group(1),
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
        ));
      } else if (match.group(2) != null) {
        spans.add(pw.TextSpan(
          text: match.group(2),
          style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 11),
        ));
      } else if (match.group(3) != null) {
        spans.add(pw.TextSpan(
          text: match.group(3),
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700, font: pw.Font.courier()),
        ));
      } else if (match.group(4) != null) {
        spans.add(pw.TextSpan(text: match.group(4), style: const pw.TextStyle(fontSize: 11)));
      }
    }

    if (spans.isEmpty) {
      return pw.Text(text, style: const pw.TextStyle(fontSize: 11));
    }
    return pw.RichText(text: pw.TextSpan(children: spans));
  }

  static String _clean(String text) {
    return text
        .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1')
        .replaceAll(RegExp(r'\*(.+?)\*'), r'$1')
        .replaceAll(RegExp(r'`(.+?)`'), r'$1')
        .trim();
  }
}
