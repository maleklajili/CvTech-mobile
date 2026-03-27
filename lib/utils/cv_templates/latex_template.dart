import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// LaTeX academic CV template — serif-like typography, thin separators, compact
class LatexCvTemplate {
  static Future<pw.Document> build({
    required Map<String, dynamic> sections,
    Uint8List? photoBytes,
  }) async {
    // Use Noto Serif for academic look
    final regular = await PdfGoogleFonts.notoSerifRegular();
    final bold = await PdfGoogleFonts.notoSerifBold();
    final italic = await PdfGoogleFonts.notoSerifItalic();
    final boldItalic = await PdfGoogleFonts.notoSerifBoldItalic();

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
    final languages = sections['languages'] as List<dynamic>? ?? [];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 50, vertical: 40),
        build: (context) => [
          // ── NAME — centered, serif ──
          pw.Center(
            child: pw.Text(
              name.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
          ),
          if (title.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Center(
              child: pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey700,
                ),
              ),
            ),
          ],
          pw.SizedBox(height: 4),
          // Thin line
          pw.Divider(thickness: 0.3, color: PdfColors.grey500),
          // Contact on one line
          if (contact.isNotEmpty) ...[
            pw.SizedBox(height: 3),
            pw.Center(
              child: pw.Text(
                contact.replaceAll('\n', '  —  '),
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Divider(thickness: 0.3, color: PdfColors.grey500),
          ],

          // ── SUMMARY ──
          if (summary.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            _section('Resume'),
            pw.SizedBox(height: 4),
            pw.Text(
              summary,
              style: const pw.TextStyle(fontSize: 9.5, lineSpacing: 4),
            ),
          ],

          // ── EDUCATION (first for academic) ──
          if (education.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            _section('Formation'),
            pw.SizedBox(height: 4),
            ...education.map(
              (edu) => _buildEducationItem(edu as Map<String, dynamic>),
            ),
          ],

          // ── EXPERIENCE ──
          if (experience.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            _section('Experience Professionnelle'),
            pw.SizedBox(height: 4),
            ...experience.map(
              (exp) => _buildExperienceItem(exp as Map<String, dynamic>),
            ),
          ],

          // ── PROJECTS / PUBLICATIONS ──
          if (projects.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            _section('Publications & Projets'),
            pw.SizedBox(height: 4),
            ...projects.map(
              (proj) => _buildProjectItem(proj as Map<String, dynamic>),
            ),
          ],

          // ── SKILLS ──
          if (skills.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            _section('Competences'),
            pw.SizedBox(height: 4),
            _buildSkillsTable(skills),
          ],

          // ── LANGUAGES ──
          if (languages.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            _section('Langues'),
            pw.SizedBox(height: 4),
            ...languages.map(
              (l) => _buildLanguageItem(l as Map<String, dynamic>),
            ),
          ],
        ],
      ),
    );
    return pdf;
  }

  // ── Section title — thin-line LaTeX style ──
  static pw.Widget _section(String text) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          text.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Container(
          width: double.infinity,
          height: 0.4,
          color: PdfColors.grey600,
        ),
      ],
    );
  }

  static pw.Widget _buildEducationItem(Map<String, dynamic> edu) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Dates column — fixed width, right-aligned
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              edu['dates'] ?? '',
              style: pw.TextStyle(
                fontSize: 8.5,
                fontStyle: pw.FontStyle.italic,
                color: PdfColors.grey600,
              ),
            ),
          ),
          pw.SizedBox(width: 12),
          // Content column
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
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildExperienceItem(Map<String, dynamic> exp) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Dates column
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              exp['dates'] ?? '',
              style: pw.TextStyle(
                fontSize: 8.5,
                fontStyle: pw.FontStyle.italic,
                color: PdfColors.grey600,
              ),
            ),
          ),
          pw.SizedBox(width: 12),
          // Content column
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  exp['post'] ?? '',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if ((exp['company'] as String?)?.isNotEmpty == true)
                  pw.Text(
                    '${exp['company']}${(exp['location'] as String?)?.isNotEmpty == true ? ', ${exp['location']}' : ''}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                if (exp['achievements'] != null)
                  ...((exp['achievements'] as List?) ?? []).map(
                    (a) => pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 2),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '- ',
                            style: const pw.TextStyle(fontSize: 9),
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
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildProjectItem(Map<String, dynamic> proj) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '- ',
            style: const pw.TextStyle(fontSize: 9),
          ),
          pw.Expanded(
            child: pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(
                    text: '${proj['title'] ?? ''}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if ((proj['description'] as String?)?.isNotEmpty == true)
                    pw.TextSpan(
                      text: ' — ${proj['description']}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSkillsTable(List<dynamic> skills) {
    final grouped = <String, List<String>>{};
    for (final s in skills) {
      final map = s as Map<String, dynamic>;
      final cat = (map['category'] ?? 'General') as String;
      grouped.putIfAbsent(cat, () => []);
      grouped[cat]!.add('${map['name']}');
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 3),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 100,
                child: pw.Text(
                  '${entry.key}:',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  entry.value.join(', '),
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _buildLanguageItem(Map<String, dynamic> lang) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              lang['name'] ?? lang['langue'] ?? '',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Text(
            lang['level'] ?? lang['niveau'] ?? '',
            style: pw.TextStyle(
              fontSize: 9,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
