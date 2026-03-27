import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Modern CV template — header + two-column layout (Jill Morgan style)
class ModernCvTemplate {
  static Future<pw.Document> build({
    required Map<String, dynamic> sections,
    Uint8List? photoBytes,
    PdfColor accentColor = const PdfColor.fromInt(0xFF333333),
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
    final languages = sections['languages'] as List<dynamic>? ?? [];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (context) => [
          // ── FULL-WIDTH HEADER ──
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 24),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (photoBytes != null) ...[
                  pw.ClipOval(
                    child: pw.Image(
                      pw.MemoryImage(photoBytes),
                      width: 70,
                      height: 70,
                      fit: pw.BoxFit.cover,
                    ),
                  ),
                  pw.SizedBox(width: 16),
                ],
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        name,
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        title,
                        style: const pw.TextStyle(
                          fontSize: 13,
                          color: PdfColors.grey700,
                        ),
                      ),
                      if (contact.isNotEmpty) ...[
                        pw.SizedBox(height: 6),
                        pw.Text(
                          contact.replaceAll('\n', '   |   '),
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Separator
          pw.Container(
            margin: const pw.EdgeInsets.symmetric(horizontal: 36),
            child: pw.Divider(thickness: 1, color: PdfColors.grey300),
          ),

          // ── SUMMARY (full-width) ──
          if (summary.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(36, 12, 36, 12),
              child: pw.Text(
                summary,
                style: const pw.TextStyle(
                  fontSize: 10,
                  lineSpacing: 4,
                  color: PdfColors.grey800,
                ),
              ),
            ),

          // ── TWO-COLUMN LAYOUT ──
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 36),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // LEFT COLUMN — Experience + Education + Projects
                pw.Expanded(
                  flex: 3,
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.only(right: 20),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (experience.isNotEmpty) ...[
                          _mainSectionTitle('Experience'),
                          pw.SizedBox(height: 6),
                          ...experience.map(
                            (exp) => _buildExperienceItem(
                              exp as Map<String, dynamic>,
                              accentColor,
                            ),
                          ),
                        ],
                        if (education.isNotEmpty) ...[
                          pw.SizedBox(height: 10),
                          _mainSectionTitle('Education'),
                          pw.SizedBox(height: 6),
                          ...education.map(
                            (edu) => _buildEducationItem(
                              edu as Map<String, dynamic>,
                            ),
                          ),
                        ],
                        if (projects.isNotEmpty) ...[
                          pw.SizedBox(height: 10),
                          _mainSectionTitle('Projects'),
                          pw.SizedBox(height: 6),
                          ...projects.map(
                            (proj) => _buildProjectItem(
                              proj as Map<String, dynamic>,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Vertical separator
                pw.Container(
                  width: 0.5,
                  height: 500,
                  color: PdfColors.grey300,
                ),

                // RIGHT COLUMN — Skills + Languages
                pw.Expanded(
                  flex: 2,
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 20),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (skills.isNotEmpty) ...[
                          _sideSectionTitle('Skills'),
                          pw.SizedBox(height: 8),
                          ...skills.map(
                            (s) => _buildSkillDots(
                              s as Map<String, dynamic>,
                            ),
                          ),
                        ],
                        if (languages.isNotEmpty) ...[
                          pw.SizedBox(height: 16),
                          _sideSectionTitle('Languages'),
                          pw.SizedBox(height: 8),
                          ...languages.map(
                            (l) => _buildSkillDots(
                              l as Map<String, dynamic>,
                            ),
                          ),
                        ],
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
    return pdf;
  }

  // ────────────────── SECTION TITLES ──────────────────

  static pw.Widget _mainSectionTitle(String text) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Container(
          width: double.infinity,
          height: 1,
          color: PdfColors.grey300,
        ),
      ],
    );
  }

  static pw.Widget _sideSectionTitle(String text) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Container(
          width: double.infinity,
          height: 1,
          color: PdfColors.grey300,
        ),
      ],
    );
  }

  // ────────────────── EXPERIENCE ──────────────────

  static pw.Widget _buildExperienceItem(
    Map<String, dynamic> exp,
    PdfColor accentColor,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Timeline dot
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4, right: 10),
            child: pw.Container(
              width: 6,
              height: 6,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                color: accentColor,
              ),
            ),
          ),
          // Content
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  exp['post'] ?? '',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if ((exp['company'] as String?)?.isNotEmpty == true)
                  pw.Text(
                    exp['company'],
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                if ((exp['dates'] as String?)?.isNotEmpty == true)
                  pw.Text(
                    exp['dates'],
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.grey500,
                    ),
                  ),
                if ((exp['description'] as String?)?.isNotEmpty == true)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 3),
                    child: pw.Text(
                      exp['description'],
                      style: const pw.TextStyle(
                        fontSize: 9,
                        lineSpacing: 3,
                      ),
                    ),
                  ),
                if (exp['achievements'] != null)
                  ...((exp['achievements'] as List?) ?? []).map(
                    (a) => pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 2),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            width: 3,
                            height: 3,
                            margin: const pw.EdgeInsets.only(
                              top: 4,
                              right: 6,
                            ),
                            decoration: const pw.BoxDecoration(
                              shape: pw.BoxShape.circle,
                              color: PdfColors.grey600,
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              a.toString(),
                              style: const pw.TextStyle(fontSize: 9),
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

  // ────────────────── EDUCATION ──────────────────

  static pw.Widget _buildEducationItem(Map<String, dynamic> edu) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4, right: 10),
            child: pw.Container(
              width: 6,
              height: 6,
              decoration: const pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                color: PdfColors.grey600,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  edu['degree'] ?? '',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if ((edu['school'] as String?)?.isNotEmpty == true)
                  pw.Text(
                    edu['school'],
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                if ((edu['dates'] as String?)?.isNotEmpty == true)
                  pw.Text(
                    edu['dates'],
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.grey500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────── PROJECTS ──────────────────

  static pw.Widget _buildProjectItem(Map<String, dynamic> proj) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
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

  // ────────────────── SKILL DOTS ──────────────────

  static pw.Widget _buildSkillDots(Map<String, dynamic> skill) {
    final name = (skill['name'] ?? '') as String;
    final levelStr = (skill['level'] as String?)?.toLowerCase() ?? '';
    int filled;
    switch (levelStr) {
      case 'expert':
      case 'avance':
      case 'avancé':
      case 'natif':
      case 'native':
        filled = 5;
        break;
      case 'courant':
      case 'fluent':
        filled = 4;
        break;
      case 'intermediaire':
      case 'intermédiaire':
      case 'intermediate':
        filled = 3;
        break;
      case 'debutant':
      case 'débutant':
      case 'beginner':
      case 'basique':
        filled = 2;
        break;
      default:
        filled = 4;
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(
              name,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
          pw.Row(
            children: List.generate(
              5,
              (i) => pw.Container(
                width: 8,
                height: 8,
                margin: const pw.EdgeInsets.only(left: 3),
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  color: i < filled ? PdfColors.grey800 : PdfColors.white,
                  border: pw.Border.all(
                    color: PdfColors.grey500,
                    width: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
