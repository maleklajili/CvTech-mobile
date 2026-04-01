import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/data/repositories/ai_cv_repository.dart';
import 'package:cv_tech/data/repositories/manual_cv_repository.dart';
import 'package:cv_tech/presentation/widgets/common/custom_toast.dart';

/// Customization screen shown before downloading a CV as PDF.
/// Allows user to pick template, primary color, and font family.
class CvCustomizationScreen extends StatefulWidget {
  final String cvId;
  final String cvTitle;

  /// "ai" or "manual"
  final String cvType;

  /// Current format of the CV (used as default selection)
  final String currentFormat;

  const CvCustomizationScreen({
    super.key,
    required this.cvId,
    required this.cvTitle,
    required this.cvType,
    this.currentFormat = 'standard',
  });

  @override
  State<CvCustomizationScreen> createState() => _CvCustomizationScreenState();
}

class _CvCustomizationScreenState extends State<CvCustomizationScreen> {
  late String _selectedTemplate;
  Color _selectedColor = const Color(0xFF1e3a8a);
  String _selectedFont = 'Arial';
  bool _isDownloading = false;

  static const _templates = [
    _TemplateOption(
      key: 'standard',
      label: 'Standard',
      icon: Icons.description_outlined,
      color: Color(0xFF4B5563),
    ),
    _TemplateOption(
      key: 'canadian',
      label: 'Canadien',
      icon: Icons.flag_outlined,
      color: Color(0xFF1e3a8a),
    ),
    _TemplateOption(
      key: 'modern',
      label: 'Moderne',
      icon: Icons.auto_awesome_outlined,
      color: Color(0xFF667eea),
    ),
    _TemplateOption(
      key: 'european',
      label: 'Européen',
      icon: Icons.account_circle_outlined,
      color: Color(0xFF0f766e),
    ),
    _TemplateOption(
      key: 'latex',
      label: 'LaTeX',
      icon: Icons.code,
      color: Color(0xFF1a1a1a),
    ),
  ];

  static const _presetColors = [
    // Blues
    Color(0xFF1e3a8a),
    Color(0xFF0369A1),
    Color(0xFF2563EB),
    Color(0xFF4338CA),
    // Greens
    Color(0xFF0f766e),
    Color(0xFF166534),
    Color(0xFF059669),
    Color(0xFF15803D),
    // Reds & Pinks
    Color(0xFFDC2626),
    Color(0xFFBE185D),
    Color(0xFFE11D48),
    Color(0xFF9F1239),
    // Purples
    Color(0xFF6D28D9),
    Color(0xFF7C3AED),
    Color(0xFF6B21A8),
    // Warm tones
    Color(0xFF92400E),
    Color(0xFFD97706),
    Color(0xFFEA580C),
    // Neutrals
    Color(0xFF1E293B),
    Color(0xFF374151),
    Color(0xFF000000),
    Color(0xFF475569),
  ];

  static const _fonts = [
    'Arial',
    'Times New Roman',
    'Georgia',
    'Calibri',
    'Roboto',
    'Helvetica',
    'Verdana',
    'Courier New',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTemplate = widget.currentFormat;
  }

  String _colorToHex(Color c) {
    return '#${c.red.toRadixString(16).padLeft(2, '0')}'
        '${c.green.toRadixString(16).padLeft(2, '0')}'
        '${c.blue.toRadixString(16).padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personnaliser le CV'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Template picker
            const Text(
              'Template',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildTemplatePicker(),
            const SizedBox(height: 24),

            // Color picker
            const Text(
              'Couleur principale',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildColorPicker(),
            const SizedBox(height: 24),

            // Font picker
            const Text(
              'Police',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildFontPicker(),
            const SizedBox(height: 32),

            // Download button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isDownloading ? null : _downloadPdf,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isDownloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download),
                label: Text(
                  _isDownloading
                      ? 'Génération en cours...'
                      : 'Télécharger le PDF',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatePicker() {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _templates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final t = _templates[index];
          final isSelected = _selectedTemplate == t.key;
          return GestureDetector(
            onTap: () => setState(() => _selectedTemplate = t.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 100,
              decoration: BoxDecoration(
                color: isSelected
                    ? t.color.withValues(alpha: 0.12)
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? t.color : Colors.grey.shade300,
                  width: isSelected ? 2.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: t.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(t.icon, color: t.color, size: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? t.color : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildColorPicker() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _presetColors.map((color) {
        final isSelected = _selectedColor.value == color.value;
        return GestureDetector(
          onTap: () => setState(() => _selectedColor = color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFontPicker() {
    return Column(
      children: _fonts.map((font) {
        final isSelected = _selectedFont == font;
        return GestureDetector(
          onTap: () => setState(() => _selectedFont = font),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? _selectedColor.withValues(alpha: 0.08)
                  : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? _selectedColor : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Aperçu en $font',
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? _selectedColor : null,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: _selectedColor, size: 22),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _downloadPdf() async {
    setState(() => _isDownloading = true);

    try {
      CustomToast.info(context, 'Génération du PDF en cours...', title: 'PDF');

      final primaryHex = _colorToHex(_selectedColor);
      debugPrint('>>> CV Download: template=$_selectedTemplate, color=$primaryHex, font=$_selectedFont');
      late final Uint8List pdfBytes;

      if (widget.cvType == 'ai') {
        final repo = AiCvRepository();
        pdfBytes = await repo.downloadPdf(
          widget.cvId,
          primaryColor: primaryHex,
          fontFamily: _selectedFont,
          format: _selectedTemplate,
        );
      } else {
        final repo = ManualCvRepository();
        pdfBytes = await repo.downloadPdf(
          widget.cvId,
          primaryColor: primaryHex,
          fontFamily: _selectedFont,
          format: _selectedTemplate,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      final filename =
          '${widget.cvTitle.replaceAll(RegExp(r'[^\w\s-]'), '').trim()}.pdf';

      final isMobile = !kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS);

      if (isMobile) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(pdfBytes);
        await SharePlus.instance.share(ShareParams(
          files: [XFile(file.path)],
          subject: widget.cvTitle,
        ));
      } else {
        await Printing.sharePdf(bytes: pdfBytes, filename: filename);
      }

      if (mounted) {
        CustomToast.success(context, 'PDF généré avec succès');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        CustomToast.error(context, '$e', title: 'Erreur PDF');
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }
}

class _TemplateOption {
  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const _TemplateOption({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });
}
