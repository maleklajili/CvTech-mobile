import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Canadian CV template — ATS-friendly, no photo, no personal info, STAR method
class CanadianCvTemplate {
  static Future<pw.Document> build({
    required Map<String, dynamic> sections,
    Uint8List? photoBytes, // ignored for Canadian format
  }) async {
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

    final name = sections['name'] as String? ?? '';
    final title = sections['title'] as String? ?? '';
    final contact = sections['contact'] as String? ?? '';
    final summary = sections['summary'] as String? ?? '';
    final experience = sections['experience'] as List<dynamic>? ?? [];
    final education = sections['education'] as List<dynamic>? ?? [];
    final skills = sections['skills'] as List<dynamic>? ?? [];
    final projects = sections['projects'] as List<dynamic>? ?? [];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 36),
        build: (context) => [
          // ── NAME (centered, minimal) ──
          pw.Center(
            child: pw.Text(
              name.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
          ),
          pw.SizedBox(height: 4),
          // Contact line — condensed
          if (contact.isNotEmpty)
            pw.Center(
              child: pw.Text(
                contact.replaceAll('\n', '  |  '),
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                textAlign: pw.TextAlign.center,
              ),
            ),
          pw.SizedBox(height: 4),
          pw.Divider(thickness: 1, color: PdfColors.black),

          // ── PROFESSIONAL SUMMARY ──
          if (summary.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            _section('PROFESSIONAL SUMMARY'),
            pw.SizedBox(height: 4),
            pw.Text(
              summary,
              style: const pw.TextStyle(fontSize: 10, lineSpacing: 4),
            ),
          ],

          // ── KEY COMPETENCIES ──
          if (skills.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _section('KEY COMPETENCIES'),
            pw.SizedBox(height: 6),
            _buildKeyCompetencies(skills),
          ],

          // ── WORK EXPERIENCE ──
          if (experience.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _section('WORK EXPERIENCE'),
            pw.SizedBox(height: 6),
            ...experience.map(
              (exp) => _buildExperienceItem(exp as Map<String, dynamic>),
            ),
          ],

          // ── EDUCATION ──
          if (education.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _section('EDUCATION'),
            pw.SizedBox(height: 6),
            ...education.map(
              (edu) => _buildEducationItem(edu as Map<String, dynamic>),
            ),
          ],

          // ── PROJECTS ──
          if (projects.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _section('KEY PROJECTS'),
            pw.SizedBox(height: 6),
            ...projects.map(
              (proj) => _buildProjectItem(proj as Map<String, dynamic>),
            ),
          ],
        ],
      ),
    );
    return pdf;
  }

  static pw.Widget _section(String text) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.only(bottom: 3),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
        ),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }

  /// Key competencies as a 3-column grid of bullet items
  static pw.Widget _buildKeyCompetencies(List<dynamic> skills) {
    final names = skills
        .map((s) => (s as Map<String, dynamic>)['name']?.toString() ?? '')
        .where((n) => n.isNotEmpty)
        .toList();

    // Group into rows of 3
    final rows = <pw.TableRow>[];
    for (var i = 0; i < names.length; i += 3) {
      rows.add(pw.TableRow(
        children: List.generate(3, (j) {
          final idx = i + j;
          if (idx >= names.length) return pw.SizedBox();
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3, right: 8),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 4,
                  height: 4,
                  margin: const pw.EdgeInsets.only(top: 3, right: 6),
                  decoration: const pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    color: PdfColors.black,
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    names[idx],
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              ],
            ),
          );
        }),
      ));
    }

    return pw.Table(children: rows);
  }

  static pw.Widget _buildExperienceItem(Map<String, dynamic> exp) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Role + dates on same line
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  exp['post'] ?? '',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              if ((exp['dates'] as String?)?.isNotEmpty == true)
                pw.Text(
                  exp['dates'],
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
            ],
          ),
          // Company + location
          if ((exp['company'] as String?)?.isNotEmpty == true)
            pw.Text(
              '${exp['company']}${(exp['location'] as String?)?.isNotEmpty == true ? ', ${exp['location']}' : ''}',
              style: pw.TextStyle(
                fontSize: 10,
                fontStyle: pw.FontStyle.italic,
                color: PdfColors.grey700,
              ),
            ),
          // STAR-format achievements
          if (exp['achievements'] != null)
            ...((exp['achievements'] as List?) ?? []).map(
              (a) => pw.Padding(
                padding: const pw.EdgeInsets.only(left: 10, top: 2),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 4,
                      height: 4,
                      margin: const pw.EdgeInsets.only(top: 4, right: 6),
                      decoration: const pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        a.toString(),
                        style: const pw.TextStyle(fontSize: 9, lineSpacing: 3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildEducationItem(Map<String, dynamic> edu) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  edu['degree'] ?? '',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if ((edu['school'] as String?)?.isNotEmpty == true)
                  pw.Text(
                    edu['school'],
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.grey700,
                    ),
                  ),
              ],
            ),
          ),
          if ((edu['dates'] as String?)?.isNotEmpty == true)
            pw.Text(
              edu['dates'],
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildProjectItem(Map<String, dynamic> proj) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            proj['title'] ?? '',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if ((proj['description'] as String?)?.isNotEmpty == true)
            pw.Text(
              proj['description'],
              style: const pw.TextStyle(fontSize: 9),
            ),
        ],
      ),
    );
  }
}
