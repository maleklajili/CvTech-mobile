import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CanadianCvTemplate {
  static const _titleColor = PdfColor.fromInt(0xFF1A1A1A);
  static const _textColor = PdfColor.fromInt(0xFF333333);
  static const _subtextColor = PdfColor.fromInt(0xFF666666);
  static const _lineColor = PdfColor.fromInt(0xFFDDDDDD);

  static Future<pw.Document> build({
    required Map<String, dynamic> sections,
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
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.symmetric(horizontal: 50, vertical: 40),
        build: (context) => [
          // HEADER - simple, ATS-friendly
          pw.Center(child: pw.Text(name.toUpperCase(), style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: _titleColor, letterSpacing: 2))),
          if (title.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Center(child: pw.Text(title, style: pw.TextStyle(fontSize: 11, color: _subtextColor))),
          ],
          if (contact.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Wrap(spacing: 10, runSpacing: 4,
                children: contact.split(RegExp(r'[\n|]')).where((c) => c.trim().isNotEmpty).map((c) =>
                  pw.Text(c.trim(), style: const pw.TextStyle(fontSize: 9, color: _subtextColor))
                ).toList(),
              ),
            ),
          ],
          pw.SizedBox(height: 12),
          pw.Divider(thickness: 1, color: _titleColor),

          // PROFESSIONAL SUMMARY
          if (summary.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _sectionTitle('PROFESSIONAL SUMMARY'),
            pw.SizedBox(height: 6),
            pw.Text(summary, style: pw.TextStyle(fontSize: 10, lineSpacing: 5, color: _textColor)),
            pw.SizedBox(height: 12),
          ],

          // KEY COMPETENCIES
          if (skills.isNotEmpty) ...[
            _sectionTitle('KEY COMPETENCIES'),
            pw.SizedBox(height: 8),
            pw.Wrap(spacing: 8, runSpacing: 6,
              children: skills.map((s) {
                final map = s as Map<String, dynamic>;
                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: pw.BoxDecoration(border: pw.Border.all(color: _lineColor), borderRadius: pw.BorderRadius.circular(4)),
                  child: pw.Text(map['name']?.toString() ?? '', style: pw.TextStyle(fontSize: 9, color: _textColor)),
                );
              }).toList(),
            ),
            pw.SizedBox(height: 14),
          ],

          // WORK EXPERIENCE
          if (experience.isNotEmpty) ...[
            _sectionTitle('WORK EXPERIENCE'),
            pw.SizedBox(height: 8),
            ...experience.map((exp) => _buildExperienceItem(exp as Map<String, dynamic>)),
          ],

          // EDUCATION
          if (education.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            _sectionTitle('EDUCATION'),
            pw.SizedBox(height: 8),
            ...education.map((edu) => _buildEducationItem(edu as Map<String, dynamic>)),
          ],

          // PROJECTS
          if (projects.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            _sectionTitle('PROJECTS'),
            pw.SizedBox(height: 8),
            ...projects.map((proj) => _buildProjectItem(proj as Map<String, dynamic>)),
          ],
        ],
      ),
    );
    return pdf;
  }

  static pw.Widget _sectionTitle(String text) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(text, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _titleColor, letterSpacing: 1.5)),
      pw.SizedBox(height: 3),
      pw.Divider(thickness: 0.5, color: _lineColor),
    ]);
  }

  static pw.Widget _buildExperienceItem(Map<String, dynamic> exp) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Expanded(child: pw.Text(exp['post'] ?? '', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _titleColor))),
          if ((exp['dates'] as String?)?.isNotEmpty == true)
            pw.Text(exp['dates'], style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: _subtextColor)),
        ]),
        if ((exp['company'] as String?)?.isNotEmpty == true) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            '${exp['company']}${(exp['location'] as String?)?.isNotEmpty == true ? ', ${exp['location']}' : ''}',
            style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: _subtextColor),
          ),
        ],
        if (exp['achievements'] != null)
          ...((exp['achievements'] as List?) ?? []).map((a) => pw.Padding(
            padding: const pw.EdgeInsets.only(left: 10, top: 4),
            child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Container(width: 4, height: 4, margin: const pw.EdgeInsets.only(top: 4, right: 8),
                decoration: const pw.BoxDecoration(shape: pw.BoxShape.circle, color: _titleColor)),
              pw.Expanded(child: pw.Text(a.toString(), style: pw.TextStyle(fontSize: 9.5, color: _textColor, lineSpacing: 3))),
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
            pw.SizedBox(height: 2),
            pw.Text(edu['school'], style: pw.TextStyle(fontSize: 9.5, fontStyle: pw.FontStyle.italic, color: _subtextColor)),
          ],
        ])),
        if ((edu['dates'] as String?)?.isNotEmpty == true)
          pw.Text(edu['dates'], style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic, color: _subtextColor)),
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
          pw.Text(proj['description'], style: pw.TextStyle(fontSize: 9.5, color: _textColor)),
        ],
      ]),
    );
  }
}