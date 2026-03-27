import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class LatexCvTemplate {
  static const _titleColor = PdfColor.fromInt(0xFF1A1A1A);
  static const _textColor = PdfColor.fromInt(0xFF333333);
  static const _subtextColor = PdfColor.fromInt(0xFF555555);
  static const _lineColor = PdfColor.fromInt(0xFF999999);

  static Future<pw.Document> build({
    required Map<String, dynamic> sections,
  }) async {
    final regular = await PdfGoogleFonts.notoSerifRegular();
    final bold = await PdfGoogleFonts.notoSerifBold();
    final italic = await PdfGoogleFonts.notoSerifItalic();
    final boldItalic = await PdfGoogleFonts.notoSerifBoldItalic();

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
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 55, vertical: 45),
        build: (context) => [
          // HEADER - centered academic style
          pw.Center(child: pw.Text(name.toUpperCase(), style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _titleColor, letterSpacing: 4))),
          pw.SizedBox(height: 2),
          pw.Divider(thickness: 1, color: _titleColor),
          if (title.isNotEmpty || contact.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Center(
                child: pw.Text(
                  [title, ...contact.split(RegExp(r'[\n|]')).where((c) => c.trim().isNotEmpty).map((c) => c.trim())].where((x) => x.isNotEmpty).join('  |  '),
                  style: pw.TextStyle(fontSize: 9.5, color: _subtextColor),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ),
          pw.SizedBox(height: 4),
          pw.Divider(thickness: 0.5, color: _lineColor),

          // SUMMARY
          if (summary.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _sectionTitle('Profil'),
            pw.SizedBox(height: 6),
            pw.Text(summary, style: pw.TextStyle(fontSize: 10.5, lineSpacing: 5, color: _textColor, fontStyle: pw.FontStyle.italic)),
            pw.SizedBox(height: 12),
          ],

          // EXPERIENCE
          if (experience.isNotEmpty) ...[
            _sectionTitle('Experience Professionnelle'),
            pw.SizedBox(height: 8),
            ...experience.map((exp) => _buildExperienceItem(exp as Map<String, dynamic>)),
          ],

          // EDUCATION
          if (education.isNotEmpty) ...[
            _sectionTitle('Formation'),
            pw.SizedBox(height: 8),
            ...education.map((edu) => _buildEducationItem(edu as Map<String, dynamic>)),
          ],

          // PROJECTS
          if (projects.isNotEmpty) ...[
            _sectionTitle('Projets'),
            pw.SizedBox(height: 8),
            ...projects.map((proj) => _buildProjectItem(proj as Map<String, dynamic>)),
          ],

          // SKILLS
          if (skills.isNotEmpty) ...[
            _sectionTitle('Competences'),
            pw.SizedBox(height: 8),
            _buildSkillsList(skills),
          ],
        ],
      ),
    );
    return pdf;
  }

  static pw.Widget _sectionTitle(String text) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(text.toUpperCase(), style: pw.TextStyle(fontSize: 12.5, fontWeight: pw.FontWeight.bold, color: _titleColor, letterSpacing: 2)),
      pw.SizedBox(height: 2),
      pw.Divider(thickness: 0.8, color: _lineColor),
    ]);
  }

  static pw.Widget _buildExperienceItem(Map<String, dynamic> exp) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(child: pw.Text(exp['post'] ?? '', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _titleColor))),
          if ((exp['dates'] as String?)?.isNotEmpty == true)
            pw.Text(exp['dates'], style: pw.TextStyle(fontSize: 9.5, fontStyle: pw.FontStyle.italic, color: _subtextColor)),
        ]),
        if ((exp['company'] as String?)?.isNotEmpty == true) ...[
          pw.SizedBox(height: 1),
          pw.Text(exp['company'], style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: _subtextColor)),
        ],
        if (exp['achievements'] != null)
          ...((exp['achievements'] as List?) ?? []).map((a) => pw.Padding(
            padding: const pw.EdgeInsets.only(left: 12, top: 3),
            child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Container(width: 4, height: 4, margin: const pw.EdgeInsets.only(top: 4, right: 8),
                decoration: const pw.BoxDecoration(shape: pw.BoxShape.circle, color: _titleColor)),
              pw.Expanded(child: pw.Text(a.toString(), style: pw.TextStyle(fontSize: 10, color: _textColor))),
            ]),
          )),
      ]),
    );
  }

  static pw.Widget _buildEducationItem(Map<String, dynamic> edu) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Expanded(child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(edu['degree'] ?? '', style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: _titleColor)),
          if ((edu['school'] as String?)?.isNotEmpty == true) ...[
            pw.SizedBox(height: 1),
            pw.Text(edu['school'], style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: _subtextColor)),
          ],
        ])),
        if ((edu['dates'] as String?)?.isNotEmpty == true)
          pw.Text(edu['dates'], style: pw.TextStyle(fontSize: 9.5, fontStyle: pw.FontStyle.italic, color: _subtextColor)),
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
          pw.Text(proj['description'], style: pw.TextStyle(fontSize: 10, color: _textColor)),
        ],
      ]),
    );
  }

  static pw.Widget _buildSkillsList(List<dynamic> skills) {
    final grouped = <String, List<String>>{};
    for (final s in skills) {
      final map = s as Map<String, dynamic>;
      final cat = (map['category'] ?? 'General') as String;
      grouped.putIfAbsent(cat, () => []);
      grouped[cat]!.add('${map['name']}');
    }

    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: grouped.entries.map((entry) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text('${entry.key}:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _titleColor)),
          ),
          pw.Expanded(child: pw.Text(entry.value.join(', '), style: pw.TextStyle(fontSize: 10, color: _textColor))),
        ]),
      );
    }).toList());
  }
}