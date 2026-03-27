import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Professional CV template — clean design (Sebastian Bennett style)
class StandardCvTemplate {
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
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 30),
        build: (context) => [
          // ── HEADER ──
          _buildHeader(name, title, contact, photoBytes),
          pw.SizedBox(height: 6),
          pw.Divider(thickness: 1.5, color: PdfColors.black),

          // ── ABOUT ME ──
          if (summary.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _sectionTitle('ABOUT ME'),
            pw.SizedBox(height: 6),
            pw.Text(
              summary,
              style: const pw.TextStyle(fontSize: 10, lineSpacing: 4),
            ),
          ],

          // ── EDUCATION ──
          if (education.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _sectionTitle('EDUCATION'),
            pw.SizedBox(height: 6),
            ...education.map(
              (edu) => _buildEducationItem(edu as Map<String, dynamic>),
            ),
          ],

          // ── WORK EXPERIENCE ──
          if (experience.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _sectionTitle('WORK EXPERIENCE'),
            pw.SizedBox(height: 6),
            ...experience.map(
              (exp) => _buildExperienceItem(exp as Map<String, dynamic>),
            ),
          ],

          // ── PROJECTS ──
          if (projects.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _sectionTitle('PROJECTS'),
            pw.SizedBox(height: 6),
            ...projects.map(
              (proj) => _buildProjectItem(proj as Map<String, dynamic>),
            ),
          ],

          // ── SKILLS ──
          if (skills.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _sectionTitle('SKILLS'),
            pw.SizedBox(height: 8),
            _buildSkillsChips(skills),
          ],
        ],
      ),
    );
    return pdf;
  }

  // ────────────────── HEADER ──────────────────

  static pw.Widget _buildHeader(
    String name,
    String title,
    String contact,
    Uint8List? photoBytes,
  ) {
    final nameWidget = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          name.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 26,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        if (title.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            color: PdfColors.grey800,
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 11,
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
        if (contact.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          pw.Text(
            contact.replaceAll('\n', '   |   '),
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ],
    );

    if (photoBytes != null) {
      return pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.ClipRRect(
            horizontalRadius: 4,
            verticalRadius: 4,
            child: pw.Image(
              pw.MemoryImage(photoBytes),
              width: 75,
              height: 90,
              fit: pw.BoxFit.cover,
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(child: nameWidget),
        ],
      );
    }
    return nameWidget;
  }

  // ────────────────── SECTION TITLE ──────────────────

  static pw.Widget _sectionTitle(String text) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Divider(thickness: 0.8, color: PdfColors.grey400),
      ],
    );
  }

  // ────────────────── EDUCATION ──────────────────

  static pw.Widget _buildEducationItem(Map<String, dynamic> edu) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  edu['degree'] ?? '',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              if ((edu['dates'] as String?)?.isNotEmpty == true)
                pw.Text(
                  edu['dates'],
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
            ],
          ),
          if ((edu['school'] as String?)?.isNotEmpty == true)
            pw.Text(
              edu['school'],
              style: pw.TextStyle(
                fontSize: 10,
                fontStyle: pw.FontStyle.italic,
                color: PdfColors.grey700,
              ),
            ),
        ],
      ),
    );
  }

  // ────────────────── EXPERIENCE ──────────────────

  static pw.Widget _buildExperienceItem(Map<String, dynamic> exp) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
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
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
            ],
          ),
          if ((exp['company'] as String?)?.isNotEmpty == true)
            pw.Text(
              '${exp['company']}${(exp['location'] as String?)?.isNotEmpty == true ? ' - ${exp['location']}' : ''}',
              style: pw.TextStyle(
                fontSize: 10,
                fontStyle: pw.FontStyle.italic,
                color: PdfColors.grey700,
              ),
            ),
          if ((exp['description'] as String?)?.isNotEmpty == true)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: pw.Text(
                exp['description'],
                style: const pw.TextStyle(fontSize: 10, lineSpacing: 3),
              ),
            ),
          if (exp['achievements'] != null)
            ...((exp['achievements'] as List?) ?? []).map(
              (a) => pw.Padding(
                padding: const pw.EdgeInsets.only(left: 10, top: 3),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 4,
                      height: 4,
                      margin: const pw.EdgeInsets.only(top: 4, right: 8),
                      decoration: const pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        a.toString(),
                        style: const pw.TextStyle(fontSize: 10),
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
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if ((proj['description'] as String?)?.isNotEmpty == true)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                proj['description'],
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }

  // ────────────────── SKILLS ──────────────────

  static pw.Widget _buildSkillsChips(List<dynamic> skills) {
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
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.only(right: 4, top: 3),
                child: pw.Text(
                  '${entry.key}:',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              ...entry.value.map(
                (skill) => pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey500),
                    borderRadius: pw.BorderRadius.circular(3),
                  ),
                  child: pw.Text(skill, style: const pw.TextStyle(fontSize: 9)),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
