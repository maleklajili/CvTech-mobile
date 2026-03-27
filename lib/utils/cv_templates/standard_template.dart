import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class StandardCvTemplate {
  static const _primaryColor = PdfColor.fromInt(0xFF1A1A2E);
  static const _accentColor = PdfColor.fromInt(0xFF16213E);
  static const _textColor = PdfColor.fromInt(0xFF2D2D2D);
  static const _subtextColor = PdfColor.fromInt(0xFF6B6B6B);
  static const _lineColor = PdfColor.fromInt(0xFFCCCCCC);

  static Future<pw.Document> build({
    required Map<String, dynamic> sections,
    Uint8List? photoBytes,
    PdfColor accentColor = PdfColors.black,
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
        margin: const pw.EdgeInsets.symmetric(horizontal: 44, vertical: 36),
        build: (context) => [
          _buildHeader(name, title, contact, photoBytes),
          pw.SizedBox(height: 20),
          if (summary.isNotEmpty) ...[
            _sectionTitle('PROFIL PROFESSIONNEL'),
            pw.SizedBox(height: 8),
            pw.Text(summary, style: pw.TextStyle(fontSize: 10, lineSpacing: 5, color: _textColor)),
            pw.SizedBox(height: 16),
          ],
          if (experience.isNotEmpty) ...[
            _sectionTitle('EXPERIENCE PROFESSIONNELLE'),
            pw.SizedBox(height: 8),
            ...experience.map((exp) => _buildExperienceItem(exp as Map<String, dynamic>)),
            pw.SizedBox(height: 8),
          ],
          if (education.isNotEmpty) ...[
            _sectionTitle('FORMATION'),
            pw.SizedBox(height: 8),
            ...education.map((edu) => _buildEducationItem(edu as Map<String, dynamic>)),
            pw.SizedBox(height: 8),
          ],
          if (projects.isNotEmpty) ...[
            _sectionTitle('PROJETS'),
            pw.SizedBox(height: 8),
            ...projects.map((proj) => _buildProjectItem(proj as Map<String, dynamic>)),
            pw.SizedBox(height: 8),
          ],
          if (skills.isNotEmpty) ...[
            _sectionTitle('COMPETENCES'),
            pw.SizedBox(height: 10),
            _buildSkillsChips(skills),
          ],
        ],
      ),
    );
    return pdf;
  }

  static pw.Widget _buildHeader(String name, String title, String contact, Uint8List? photoBytes) {
    final infoColumn = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(name.toUpperCase(), style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: _primaryColor, letterSpacing: 3)),
        if (title.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Text(title, style: pw.TextStyle(fontSize: 13, color: _subtextColor, letterSpacing: 1)),
        ],
        if (contact.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          pw.Wrap(
            spacing: 14, runSpacing: 4,
            children: contact.split(RegExp(r'[\n|]')).where((c) => c.trim().isNotEmpty).map((c) =>
              pw.Text(c.trim(), style: const pw.TextStyle(fontSize: 9, color: _subtextColor))
            ).toList(),
          ),
        ],
      ],
    );

    if (photoBytes != null) {
      return pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.ClipRRect(horizontalRadius: 6, verticalRadius: 6, child: pw.Image(pw.MemoryImage(photoBytes), width: 80, height: 95, fit: pw.BoxFit.cover)),
        pw.SizedBox(width: 18),
        pw.Expanded(child: infoColumn),
      ]);
    }

    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      infoColumn,
      pw.SizedBox(height: 10),
      pw.Container(width: double.infinity, height: 2, color: _primaryColor),
    ]);
  }

  static pw.Widget _sectionTitle(String text) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Row(children: [
        pw.Container(width: 4, height: 16, color: _accentColor),
        pw.SizedBox(width: 10),
        pw.Text(text, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _primaryColor, letterSpacing: 2)),
      ]),
      pw.SizedBox(height: 4),
      pw.Divider(thickness: 0.5, color: _lineColor),
    ]);
  }

  static pw.Widget _buildExperienceItem(Map<String, dynamic> exp) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(child: pw.Text(exp['post'] ?? '', style: pw.TextStyle(fontSize: 11.5, fontWeight: pw.FontWeight.bold, color: _primaryColor))),
          if ((exp['dates'] as String?)?.isNotEmpty == true)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(3)),
              child: pw.Text(exp['dates'], style: pw.TextStyle(fontSize: 8.5, fontStyle: pw.FontStyle.italic, color: _subtextColor)),
            ),
        ]),
        if ((exp['company'] as String?)?.isNotEmpty == true) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            '${exp['company']}${(exp['location'] as String?)?.isNotEmpty == true ? '  -  ${exp['location']}' : ''}',
            style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: _subtextColor),
          ),
        ],
        if ((exp['description'] as String?)?.isNotEmpty == true) ...[
          pw.SizedBox(height: 4),
          pw.Text(exp['description'], style: pw.TextStyle(fontSize: 9.5, color: _textColor, lineSpacing: 3)),
        ],
        if (exp['achievements'] != null)
          ...((exp['achievements'] as List?) ?? []).map((a) => pw.Padding(
            padding: const pw.EdgeInsets.only(left: 12, top: 3),
            child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Container(width: 5, height: 5, margin: const pw.EdgeInsets.only(top: 3, right: 8),
                decoration: const pw.BoxDecoration(shape: pw.BoxShape.circle, color: _accentColor)),
              pw.Expanded(child: pw.Text(a.toString(), style: pw.TextStyle(fontSize: 9.5, color: _textColor))),
            ]),
          )),
      ]),
    );
  }

  static pw.Widget _buildEducationItem(Map<String, dynamic> edu) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(child: pw.Text(edu['degree'] ?? '', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _primaryColor))),
          if ((edu['dates'] as String?)?.isNotEmpty == true)
            pw.Text(edu['dates'], style: pw.TextStyle(fontSize: 8.5, fontStyle: pw.FontStyle.italic, color: _subtextColor)),
        ]),
        if ((edu['school'] as String?)?.isNotEmpty == true) ...[
          pw.SizedBox(height: 2),
          pw.Text(edu['school'], style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: _subtextColor)),
        ],
      ]),
    );
  }

  static pw.Widget _buildProjectItem(Map<String, dynamic> proj) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(proj['title'] ?? '', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _primaryColor)),
        if ((proj['description'] as String?)?.isNotEmpty == true) ...[
          pw.SizedBox(height: 3),
          pw.Text(proj['description'], style: pw.TextStyle(fontSize: 9.5, color: _textColor)),
        ],
      ]),
    );
  }

  static pw.Widget _buildSkillsChips(List<dynamic> skills) {
    final grouped = <String, List<String>>{};
    for (final s in skills) {
      final map = s as Map<String, dynamic>;
      final cat = (map['category'] ?? 'General') as String;
      grouped.putIfAbsent(cat, () => []);
      grouped[cat]!.add('${map['name']}');
    }

    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: grouped.entries.map((entry) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(entry.key, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _primaryColor)),
          pw.SizedBox(height: 5),
          pw.Wrap(spacing: 6, runSpacing: 5, children: entry.value.map((skill) =>
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: pw.BoxDecoration(color: PdfColors.grey100, border: pw.Border.all(color: _lineColor, width: 0.5), borderRadius: pw.BorderRadius.circular(4)),
              child: pw.Text(skill, style: pw.TextStyle(fontSize: 9, color: _textColor)),
            ),
          ).toList()),
        ]),
      );
    }).toList());
  }
}