import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class EuropeanCvTemplate {
  static const _sidebarWidth = 185.0;
  static const _sidebarColor = PdfColor.fromInt(0xFF2C3E50);
  static const _accentColor = PdfColor.fromInt(0xFF3498DB);
  static const _titleColor = PdfColor.fromInt(0xFF1A252F);
  static const _textColor = PdfColor.fromInt(0xFF333333);
  static const _subtextColor = PdfColor.fromInt(0xFF777777);

  static Future<pw.Document> build({
    required Map<String, dynamic> sections,
    Uint8List? photoBytes,
  }) async {
    final regular = await PdfGoogleFonts.openSansRegular();
    final bold = await PdfGoogleFonts.openSansBold();
    final italic = await PdfGoogleFonts.openSansItalic();
    final boldItalic = await PdfGoogleFonts.openSansBoldItalic();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: regular, bold: bold, italic: italic, boldItalic: boldItalic),
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
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) => pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // LEFT SIDEBAR
            pw.Container(
              width: _sidebarWidth,
              color: _sidebarColor,
              padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Photo
                  if (photoBytes != null) ...[
                    pw.ClipOval(
                      child: pw.Image(pw.MemoryImage(photoBytes), width: 100, height: 100, fit: pw.BoxFit.cover),
                    ),
                    pw.SizedBox(height: 14),
                  ] else ...[
                    pw.Container(
                      width: 100, height: 100,
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        border: pw.Border.all(color: _accentColor, width: 2),
                      ),
                      child: pw.Center(
                        child: pw.Text(_initials(name), style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                      ),
                    ),
                    pw.SizedBox(height: 14),
                  ],

                  // Name + Title
                  pw.Text(name.toUpperCase(), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.white, letterSpacing: 1.5), textAlign: pw.TextAlign.center),
                  pw.SizedBox(height: 4),
                  pw.Text(title, style: const pw.TextStyle(fontSize: 9.5, color: _accentColor), textAlign: pw.TextAlign.center),

                  pw.SizedBox(height: 18),
                  _sidebarDivider(),

                  // CONTACT
                  pw.SizedBox(height: 14),
                  _sidebarSectionTitle('CONTACT'),
                  pw.SizedBox(height: 8),
                  ...contact.split(RegExp(r'[\n|]')).where((l) => l.trim().isNotEmpty).map((line) =>
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 5),
                      child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                        pw.Container(width: 4, height: 4, margin: const pw.EdgeInsets.only(top: 3, right: 6),
                          decoration: const pw.BoxDecoration(shape: pw.BoxShape.circle, color: _accentColor)),
                        pw.Expanded(child: pw.Text(line.trim(), style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.white))),
                      ]),
                    ),
                  ),

                  // SKILLS
                  if (skills.isNotEmpty) ...[
                    pw.SizedBox(height: 14),
                    _sidebarDivider(),
                    pw.SizedBox(height: 14),
                    _sidebarSectionTitle('COMPETENCES'),
                    pw.SizedBox(height: 8),
                    ...skills.take(10).map((s) => _buildSkillBar(s as Map<String, dynamic>)),
                  ],
                ],
              ),
            ),

            // RIGHT MAIN CONTENT
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 26, vertical: 28),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Summary
                    if (summary.isNotEmpty) ...[
                      _mainSectionTitle('PROFIL'),
                      pw.SizedBox(height: 8),
                      pw.Text(summary, style: pw.TextStyle(fontSize: 9.5, lineSpacing: 5, color: _textColor)),
                      pw.SizedBox(height: 18),
                    ],

                    // Experience
                    if (experience.isNotEmpty) ...[
                      _mainSectionTitle('EXPERIENCE PROFESSIONNELLE'),
                      pw.SizedBox(height: 8),
                      ...experience.map((exp) => _buildExperienceItem(exp as Map<String, dynamic>)),
                    ],

                    // Education
                    if (education.isNotEmpty) ...[
                      pw.SizedBox(height: 12),
                      _mainSectionTitle('FORMATION'),
                      pw.SizedBox(height: 8),
                      ...education.map((edu) => _buildEducationItem(edu as Map<String, dynamic>)),
                    ],

                    // Projects
                    if (projects.isNotEmpty) ...[
                      pw.SizedBox(height: 12),
                      _mainSectionTitle('PROJETS'),
                      pw.SizedBox(height: 8),
                      ...projects.map((proj) => _buildProjectItem(proj as Map<String, dynamic>)),
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

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '';
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  static pw.Widget _sidebarDivider() => pw.Container(width: double.infinity, height: 0.5, color: PdfColor.fromInt(0xFF4A6478));

  static pw.Widget _sidebarSectionTitle(String text) {
    return pw.Container(
      width: double.infinity,
      child: pw.Text(text, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _accentColor, letterSpacing: 2), textAlign: pw.TextAlign.left),
    );
  }

  static pw.Widget _mainSectionTitle(String text) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(text, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _titleColor, letterSpacing: 1.5)),
      pw.SizedBox(height: 3),
      pw.Row(children: [
        pw.Container(width: 35, height: 2.5, color: _accentColor),
        pw.SizedBox(width: 4),
        pw.Expanded(child: pw.Container(height: 0.5, color: PdfColors.grey300)),
      ]),
    ]);
  }

  static pw.Widget _buildSkillBar(Map<String, dynamic> skill) {
    final name = skill['name']?.toString() ?? '';
    final levelStr = (skill['level'] as String?)?.toLowerCase() ?? '';
    double percent;
    switch (levelStr) {
      case 'expert': case 'avance': percent = 0.95; break;
      case 'intermediaire': case 'intermediate': percent = 0.65; break;
      case 'debutant': case 'beginner': case 'basique': percent = 0.35; break;
      default:
        final numLevel = int.tryParse(skill['level']?.toString() ?? '');
        percent = numLevel != null ? numLevel / 100.0 : 0.75;
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(name, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.white)),
        pw.SizedBox(height: 3),
        pw.Container(
          width: double.infinity, height: 5,
          decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFF4A6478), borderRadius: pw.BorderRadius.circular(2.5)),
          child: pw.Align(
            alignment: pw.Alignment.centerLeft,
            child: pw.FractionallySizedBox(
              widthFactor: percent,
              child: pw.Container(
                height: 5,
                decoration: pw.BoxDecoration(color: _accentColor, borderRadius: pw.BorderRadius.circular(2.5)),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  static pw.Widget _buildExperienceItem(Map<String, dynamic> exp) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Container(width: 8, height: 8, margin: const pw.EdgeInsets.only(top: 2, right: 10),
          decoration: const pw.BoxDecoration(shape: pw.BoxShape.circle, color: _accentColor)),
        pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Expanded(child: pw.Text(exp['post'] ?? '', style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: _titleColor))),
            if ((exp['dates'] as String?)?.isNotEmpty == true)
              pw.Text(exp['dates'], style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: _subtextColor)),
          ]),
          if ((exp['company'] as String?)?.isNotEmpty == true)
            pw.Text(exp['company'], style: const pw.TextStyle(fontSize: 9, color: _accentColor)),
          if (exp['achievements'] != null)
            ...((exp['achievements'] as List?) ?? []).map((a) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Container(width: 3, height: 3, margin: const pw.EdgeInsets.only(top: 4, right: 6),
                  decoration: const pw.BoxDecoration(shape: pw.BoxShape.circle, color: PdfColors.grey500)),
                pw.Expanded(child: pw.Text(a.toString(), style: pw.TextStyle(fontSize: 8.5, color: _textColor))),
              ]),
            )),
        ])),
      ]),
    );
  }

  static pw.Widget _buildEducationItem(Map<String, dynamic> edu) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Container(width: 8, height: 8, margin: const pw.EdgeInsets.only(top: 2, right: 10),
          decoration: const pw.BoxDecoration(shape: pw.BoxShape.circle, color: _accentColor)),
        pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(edu['degree'] ?? '', style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: _titleColor)),
          if ((edu['school'] as String?)?.isNotEmpty == true)
            pw.Text(edu['school'], style: const pw.TextStyle(fontSize: 9, color: _subtextColor)),
          if ((edu['dates'] as String?)?.isNotEmpty == true)
            pw.Text(edu['dates'], style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: _subtextColor)),
        ])),
      ]),
    );
  }

  static pw.Widget _buildProjectItem(Map<String, dynamic> proj) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(proj['title'] ?? '', style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: _titleColor)),
        if ((proj['description'] as String?)?.isNotEmpty == true) ...[
          pw.SizedBox(height: 2),
          pw.Text(proj['description'], style: pw.TextStyle(fontSize: 9, color: _textColor)),
        ],
      ]),
    );
  }
}