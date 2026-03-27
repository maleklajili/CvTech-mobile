import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// European CV template — sidebar photo + 2 columns (France, Tunisia, Maghreb style)
class EuropeanCvTemplate {
  static const _sidebarWidth = 180.0;
  static const _sidebarColor = PdfColor.fromInt(0xFF2C3E50);
  static const _accentColor = PdfColor.fromInt(0xFF3498DB);

  static Future<pw.Document> build({
    required Map<String, dynamic> sections,
    Uint8List? photoBytes,
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
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) => pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── LEFT SIDEBAR ──
            pw.Container(
              width: _sidebarWidth,
              height: PdfPageFormat.a4.height,
              color: _sidebarColor,
              padding: const pw.EdgeInsets.all(16),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Photo
                  if (photoBytes != null) ...[
                    pw.ClipOval(
                      child: pw.Image(
                        pw.MemoryImage(photoBytes),
                        width: 90,
                        height: 90,
                        fit: pw.BoxFit.cover,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                  ] else ...[
                    // Placeholder circle
                    pw.Container(
                      width: 90,
                      height: 90,
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        border: pw.Border.all(color: PdfColors.white, width: 2),
                      ),
                      child: pw.Center(
                        child: pw.Text(
                          _initials(name),
                          style: pw.TextStyle(
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 12),
                  ],

                  // Name + Title
                  pw.Text(
                    name,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    title,
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.white,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),

                  pw.SizedBox(height: 16),
                  _sidebarDivider(),

                  // ── CONTACT ──
                  pw.SizedBox(height: 10),
                  _sidebarSection('CONTACT'),
                  pw.SizedBox(height: 6),
                  ...contact.split('\n').where((l) => l.trim().isNotEmpty).map(
                    (line) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 3),
                      child: pw.Text(
                        line.trim(),
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ),

                  // ── SKILLS ──
                  if (skills.isNotEmpty) ...[
                    pw.SizedBox(height: 14),
                    _sidebarDivider(),
                    pw.SizedBox(height: 10),
                    _sidebarSection('COMPETENCES'),
                    pw.SizedBox(height: 6),
                    ...skills.map(
                      (s) => _buildSkillBar(s as Map<String, dynamic>),
                    ),
                  ],

                  // ── LANGUAGES ──
                  if (languages.isNotEmpty) ...[
                    pw.SizedBox(height: 14),
                    _sidebarDivider(),
                    pw.SizedBox(height: 10),
                    _sidebarSection('LANGUES'),
                    pw.SizedBox(height: 6),
                    ...languages.map(
                      (l) => _buildLanguageItem(l as Map<String, dynamic>),
                    ),
                  ],
                ],
              ),
            ),

            // ── RIGHT MAIN CONTENT ──
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(24),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Summary
                    if (summary.isNotEmpty) ...[
                      _mainSection('PROFIL'),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        summary,
                        style: const pw.TextStyle(
                          fontSize: 9.5,
                          lineSpacing: 4,
                          color: PdfColors.grey800,
                        ),
                      ),
                      pw.SizedBox(height: 14),
                    ],

                    // Experience
                    if (experience.isNotEmpty) ...[
                      _mainSection('EXPERIENCE'),
                      pw.SizedBox(height: 6),
                      ...experience.map(
                        (exp) => _buildExperienceItem(
                          exp as Map<String, dynamic>,
                        ),
                      ),
                    ],

                    // Education
                    if (education.isNotEmpty) ...[
                      pw.SizedBox(height: 10),
                      _mainSection('FORMATION'),
                      pw.SizedBox(height: 6),
                      ...education.map(
                        (edu) => _buildEducationItem(
                          edu as Map<String, dynamic>,
                        ),
                      ),
                    ],

                    // Projects
                    if (projects.isNotEmpty) ...[
                      pw.SizedBox(height: 10),
                      _mainSection('PROJETS'),
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
          ],
        ),
      ),
    );
    return pdf;
  }

  // ── Helpers ──

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  static pw.Widget _sidebarDivider() {
    return pw.Container(
      width: double.infinity,
      height: 0.5,
      color: PdfColors.white,
    );
  }

  static pw.Widget _sidebarSection(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 9,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        letterSpacing: 2,
      ),
    );
  }

  static pw.Widget _mainSection(String text) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: _sidebarColor,
            letterSpacing: 1,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Container(
          width: 40,
          height: 2,
          color: _accentColor,
        ),
      ],
    );
  }

  // ── Skill progress bar in sidebar ──
  static pw.Widget _buildSkillBar(Map<String, dynamic> skill) {
    final name = skill['name']?.toString() ?? '';
    final levelStr = (skill['level'] as String?)?.toLowerCase() ?? '';
    double percent;
    switch (levelStr) {
      case 'expert':
      case 'avancé':
      case 'avance':
        percent = 0.95;
        break;
      case 'intermédiaire':
      case 'intermediaire':
      case 'intermediate':
        percent = 0.65;
        break;
      case 'débutant':
      case 'debutant':
      case 'beginner':
      case 'basique':
        percent = 0.35;
        break;
      default:
        // Try numeric level (0-100)
        final numLevel = int.tryParse(skill['level']?.toString() ?? '');
        percent = numLevel != null ? numLevel / 100.0 : 0.75;
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            name,
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Container(
            width: double.infinity,
            height: 4,
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(2),
            ),
            child: pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Container(
                width: (_sidebarWidth - 32) * percent,
                height: 4,
                decoration: pw.BoxDecoration(
                  color: _accentColor,
                  borderRadius: pw.BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildLanguageItem(Map<String, dynamic> lang) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            lang['name'] ?? lang['langue'] ?? '',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.white,
            ),
          ),
          pw.Text(
            lang['level'] ?? lang['niveau'] ?? '',
            style: pw.TextStyle(
              fontSize: 8,
              fontStyle: pw.FontStyle.italic,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildExperienceItem(Map<String, dynamic> exp) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Timeline accent dot
          pw.Container(
            width: 8,
            height: 8,
            margin: const pw.EdgeInsets.only(top: 2, right: 10),
            decoration: const pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              color: _accentColor,
            ),
          ),
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
                    exp['company'],
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: _accentColor,
                    ),
                  ),
                if ((exp['dates'] as String?)?.isNotEmpty == true)
                  pw.Text(
                    exp['dates'],
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.grey500,
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
                            margin: const pw.EdgeInsets.only(top: 4, right: 6),
                            decoration: const pw.BoxDecoration(
                              shape: pw.BoxShape.circle,
                              color: PdfColors.grey600,
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              a.toString(),
                              style: const pw.TextStyle(fontSize: 8.5),
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

  static pw.Widget _buildEducationItem(Map<String, dynamic> edu) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 8,
            height: 8,
            margin: const pw.EdgeInsets.only(top: 2, right: 10),
            decoration: const pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              color: _accentColor,
            ),
          ),
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
                    style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                  ),
                if ((edu['dates'] as String?)?.isNotEmpty == true)
                  pw.Text(
                    edu['dates'],
                    style: pw.TextStyle(
                      fontSize: 8,
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

  static pw.Widget _buildProjectItem(Map<String, dynamic> proj) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            proj['title'] ?? '',
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if ((proj['description'] as String?)?.isNotEmpty == true)
            pw.Text(
              proj['description'],
              style: const pw.TextStyle(fontSize: 8.5),
            ),
        ],
      ),
    );
  }
}
