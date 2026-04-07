import 'dart:async';
import 'dart:io' show File;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/data/models/profile/manual_cv_model.dart';
import 'package:cv_tech/data/repositories/ai_cv_repository.dart';
import 'package:cv_tech/data/repositories/manual_cv_repository.dart';
import 'package:cv_tech/presentation/views/profile/manual_cv_form_view.dart';
import 'package:cv_tech/presentation/views_models/profile/manual_cv_view_model.dart';
import 'package:cv_tech/presentation/widgets/common/custom_toast.dart';
import 'package:cv_tech/theme/app_theme.dart';

// ══════════════════════════════════════════════════════════════════════════════
// CV Builder  —  5-screen guided flow
//   1. Import trigger
//   2. Scan / progress
//   3. Score CV
//   3. Template + AI
//   4. CV preview + export
// ══════════════════════════════════════════════════════════════════════════════

const _kBlue = Color(0xFFF26E22); // App primary orange
const _kBlueBg = Color(0xFFFFF3EB); // Light orange bg
const _kBlueDark = Color(0xFFB85A10); // Dark orange
const _kBlueMid = Color(0xFFE06318); // Mid orange
const _kBlueSoft = Color(0xFFFFD4B5); // Soft orange
const _kGreen = Color(0xFF1D9E75);
const _kGreenBg = Color(0xFFE1F5EE);
const _kGreenDark = Color(0xFF0F6E56);

class CvBuilderView extends StatefulWidget {
  final bool useAi;
  const CvBuilderView({super.key, this.useAi = false});
  @override
  State<CvBuilderView> createState() => _CvBuilderViewState();
}

class _CvBuilderViewState extends State<CvBuilderView>
    with SingleTickerProviderStateMixin {
  final _pageCtrl = PageController();
  int _step = 0;

  // Repos
  final _manualRepo = ManualCvRepository();
  final _aiRepo = AiCvRepository();

  // Import state
  ManualCvModel? _importedCv;
  bool _importing = false;
  String? _importError;
  final List<_ScanItem> _scanItems = [];

  // Template state
  int _selectedTpl = 0; // index in _templates
  String _selectedLang = 'fr';
  final _jobCtrl = TextEditingController();
  Color _selectedColor = const Color(0xFF0A66C2); // default blue
  String _selectedFont = 'Roboto';

  static const _colorPalette = [
    Color(0xFF0A66C2), // Blue
    Color(0xFFF26E22), // Orange
    Color(0xFF1D9E75), // Green
    Color(0xFF7C3AED), // Purple
    Color(0xFFDC2626), // Red
    Color(0xFF0891B2), // Teal
    Color(0xFF1E293B), // Dark Navy
    Color(0xFFC2410C), // Rust
  ];

  static const _fontOptions = [
    'Roboto',
    'Montserrat',
    'Lora',
    'Open Sans',
    'Playfair Display',
  ];

  // Generation
  bool _generating = false;
  String? _generatedId;
  String _generatedType = 'manual';

  // PDF
  Uint8List? _pdfBytes;
  bool _loadingPdf = false;

  // Score card expansion
  String? _expandedKey; // which section is expanded
  String _expandMode = ''; // 'ai' or 'edit'
  final _aiPromptCtrl = TextEditingController();
  bool _aiFixLoading = false;
  final Set<String> _aiFixedSections = {};

  // Spinner animation
  late AnimationController _spinCtrl;

  static const _templates = [
    _Tpl('standard', 'Standard', Color(0xFF0A66C2), Color(0xFF85B7EB)),
    _Tpl('modern', 'Moderne', Color(0xFF1D9E75), Color(0xFF9FE1CB)),
    _Tpl('european', 'Européen', Color(0xFF2C2C2A), Color(0xFF888780)),
    _Tpl('canadian', 'Canadien', Color(0xFF1E3A8A), Color(0xFF93C5FD)),
    _Tpl('latex', 'LaTeX', Color(0xFF404040), Color(0xFFB4B2A9)),
  ];

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _jobCtrl.dispose();
    _aiPromptCtrl.dispose();
    _spinCtrl.dispose();
    super.dispose();
  }

  void _goTo(int p) {
    _pageCtrl.animateToPage(p,
        duration: const Duration(milliseconds: 320), curve: Curves.easeInOut);
    setState(() => _step = p);
  }

  // ─── STEP 1 → 2 : start import ───────────────────────────────────
  Future<void> _startImport() async {
    _goTo(1);
    setState(() {
      _importing = true;
      _importError = null;
      _scanItems.clear();
    });

    final phases = [
      _ScanItem('Informations personnelles', Icons.person_outline_rounded),
      _ScanItem('Expériences', Icons.work_outline_rounded),
      _ScanItem('Formations', Icons.school_outlined),
      _ScanItem('Compétences', Icons.psychology_outlined),
      _ScanItem('Projets & certifications', Icons.folder_outlined),
    ];

    for (var i = 0; i < phases.length; i++) {
      if (!mounted) return;
      setState(() => _scanItems.add(phases[i]));
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      // Mark previous as done
      if (i > 0) setState(() => _scanItems[i - 1].status = _ScanStatus.done);
      setState(() => _scanItems[i].status = _ScanStatus.loading);
    }

    // API call
    try {
      final tpl = _templates[_selectedTpl];
      final cv = await _manualRepo.importFromProfile(
        format: tpl.key,
        language: _selectedLang,
      );
      if (!mounted) return;
      // mark all done
      for (var s in _scanItems) {
        s.status = _ScanStatus.done;
      }
      setState(() {
        _importedCv = cv;
        _generatedId = cv.id;
        _generatedType = 'manual';
        _importing = false;
      });
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) _goTo(2);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _importError = e.toString();
        _importing = false;
      });
    }
  }

  // ─── STEP 3 : generate / customize ────────────────────────────────
  Future<void> _generateCv() async {
    setState(() => _generating = true);
    try {
      final tpl = _templates[_selectedTpl];
      final userPrompt = _jobCtrl.text.trim();

      // Use AI if user chose "Avec IA" mode or provided a custom prompt
      if (widget.useAi || userPrompt.isNotEmpty) {
        final prompt = userPrompt.isNotEmpty
            ? userPrompt
            : 'Génère un CV professionnel complet et optimisé à partir des données du profil.';
        final aiCv = await _aiRepo.generate(
          language: _selectedLang,
          section: 'full',
          format: tpl.key,
          customPrompt: prompt,
        );
        if (!mounted) return;
        setState(() {
          _generatedId = aiCv.id;
          _generatedType = 'ai';
        });
      } else if (_importedCv != null) {
        if (_importedCv!.format != tpl.key ||
            _importedCv!.language != _selectedLang) {
          await _manualRepo.update(_importedCv!.id!, {
            'format': tpl.key,
            'language': _selectedLang,
          });
        }
      }
      await _loadPdf();
      if (!mounted) return;
      setState(() => _generating = false);
      _goTo(4);
    } catch (e) {
      if (!mounted) return;
      setState(() => _generating = false);
      CustomToast.error(context, 'Erreur: $e');
    }
  }

  String _colorHex(Color c) =>
      '#${c.value.toRadixString(16).padLeft(8, '0').substring(2)}';

  Future<void> _loadPdf() async {
    setState(() => _loadingPdf = true);
    try {
      final id = _generatedId;
      if (id == null) return;
      final tpl = _templates[_selectedTpl];
      final colorHex = _colorHex(_selectedColor);
      Uint8List bytes;
      if (_generatedType == 'ai') {
        bytes = await _aiRepo.downloadPdf(id,
            format: tpl.key,
            lang: _selectedLang,
            primaryColor: colorHex,
            fontFamily: _selectedFont);
      } else {
        bytes = await _manualRepo.downloadPdf(id,
            format: tpl.key,
            lang: _selectedLang,
            primaryColor: colorHex,
            fontFamily: _selectedFont);
      }
      if (!mounted) return;
      setState(() => _pdfBytes = bytes);
    } catch (e) {
      if (!mounted) return;
      CustomToast.error(context, 'Erreur PDF: $e');
    } finally {
      if (mounted) setState(() => _loadingPdf = false);
    }
  }

  Future<void> _downloadPdf() async {
    if (_pdfBytes == null) return;
    await Printing.layoutPdf(
        onLayout: (_) async => _pdfBytes!,
        name: _importedCv?.title ?? 'Mon CV');
  }

  Future<void> _sharePdf() async {
    if (_pdfBytes == null) return;
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/cv_export.pdf');
      await file.writeAsBytes(_pdfBytes!);
      if (!mounted) return;
      await Share.shareXFiles([XFile(file.path)], text: 'Mon CV');
    } catch (e) {
      if (!mounted) return;
      CustomToast.error(context, 'Erreur: $e');
    }
  }

  String _initials(String name) {
    final p = name.trim().split(RegExp(r'\s+'));
    if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  // ═══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: PageView(
          controller: _pageCtrl,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (i) => setState(() => _step = i),
          children: [
            _screen1(),
            _screen2(),
            _screenScore(),
            _screen3(),
            _screen4(),
          ],
        ),
      ),
    );
  }

  // ─── shared top bar ────────────────────────────────────────────────
  Widget _topBar({String? left, required String title, String? right}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (left != null)
            GestureDetector(
              onTap: () {
                if (_step == 0) {
                  Navigator.pop(context);
                } else {
                  _goTo(_step - 1);
                }
              },
              child: Text(left,
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.textMutedColor)),
            )
          else
            const SizedBox(width: 40),
          const Spacer(),
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor)),
          const Spacer(),
          if (right != null)
            Text(right,
                style: const TextStyle(
                    fontSize: 11,
                    color: _kBlue,
                    fontWeight: FontWeight.w600))
          else
            const SizedBox(width: 40),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SCREEN 1 — Import trigger
  // ═══════════════════════════════════════════════════════════════════
  Widget _screen1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _topBar(left: '← Retour', title: widget.useAi ? 'CV avec IA' : 'Importer le Profil'),

          // Hero card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: _kBlueBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _kBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.useAi ? Icons.auto_awesome_rounded : Icons.person_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(height: 10),
                Text(widget.useAi
                    ? 'CV intelligent avec l\'IA'
                    : 'Importez depuis votre profil',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kBlueDark)),
                const SizedBox(height: 4),
                Text(
                  widget.useAi
                      ? 'Importez votre profil puis l\'IA\noptimisera votre CV automatiquement'
                      : 'Vos informations seront importées\nautomatiquement en quelques secondes',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, color: _kBlueMid, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Profile card (replaces URL box)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: _kBlue, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_circle_rounded,
                    color: _kBlue, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Mon profil CvTech',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _kBlue,
                    ),
                  ),
                ),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: _kGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text('Connecté',
                    style: TextStyle(
                        fontSize: 9,
                        color: _kGreen,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Hint
          Text.rich(
            TextSpan(
              text: 'Données de votre profil: ',
              style: TextStyle(fontSize: 9, color: AppTheme.textMutedColor),
              children: const [
                TextSpan(
                    text: 'expériences, formations, compétences',
                    style: TextStyle(color: _kBlue)),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Import button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startImport,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Importer mon profil',
                  style:
                      TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),

          // Or divider
          Row(
            children: [
              Expanded(child: Divider(color: AppTheme.dividerColor)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text('ou',
                    style: TextStyle(
                        fontSize: 9, color: AppTheme.textMutedColor)),
              ),
              Expanded(child: Divider(color: AppTheme.dividerColor)),
            ],
          ),
          const SizedBox(height: 8),

          // Manual button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 11),
                side: BorderSide(
                    color: AppTheme.dividerColor, width: 0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Remplir manuellement',
                  style: TextStyle(
                      fontSize: 11, color: AppTheme.textMutedColor)),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SCREEN 2 — Analyse en cours
  // ═══════════════════════════════════════════════════════════════════
  Widget _screen2() {
    final doneCount =
        _scanItems.where((s) => s.status == _ScanStatus.done).length;
    final total = 5;
    final pct = total > 0 ? (doneCount / total * 100).round() : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _topBar(title: 'Analyse en cours'),

          // Spinner
          Center(
            child: SizedBox(
              width: 52,
              height: 52,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  RotationTransition(
                    turns: _spinCtrl,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _kBlueBg, width: 3),
                      ),
                      child: CustomPaint(painter: _ArcPainter()),
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _kBlue,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(Icons.person_search_rounded,
                        color: Colors.white, size: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _importError != null
                ? 'Erreur'
                : (_importing ? 'Lecture du profil...' : 'Import terminé !'),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _importError != null ? Colors.red : _kBlueDark,
            ),
          ),
          const SizedBox(height: 4),
          Text('Profil CvTech',
              style: TextStyle(fontSize: 10, color: _kBlueMid)),
          const SizedBox(height: 14),

          // Scan card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _kBlueBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                // Avatar row (shown once we have data)
                if (_importedCv != null) ...[
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: _kBlue,
                        child: Text(
                          _initials(_importedCv!.personalInfo.fullName),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_importedCv!.personalInfo.fullName,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _kBlueDark)),
                            if (_importedCv!.personalInfo.professionalTitle !=
                                null)
                              Text(
                                '${_importedCv!.personalInfo.professionalTitle}${_importedCv!.personalInfo.city != null ? ' · ${_importedCv!.personalInfo.city}' : ''}',
                                style: const TextStyle(
                                    fontSize: 10, color: _kBlueMid),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],

                // Check rows
                ..._scanItems.map(_buildCheckRow),

                // Pending rows
                ...List.generate(
                  (total - _scanItems.length).clamp(0, total),
                  (_) => _buildPendingCheckRow(),
                ),

                // Progress bar
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 4,
                    backgroundColor: _kBlueSoft,
                    color: _kBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('$pct% importé',
                      style: const TextStyle(fontSize: 9, color: _kBlueMid)),
                ),
              ],
            ),
          ),

          // Error retry
          if (_importError != null) ...[
            const SizedBox(height: 14),
            Text(_importError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 11)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _goTo(0),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Réessayer', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: _kBlue),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckRow(_ScanItem item) {
    final isDone = item.status == _ScanStatus.done;
    final isLoading = item.status == _ScanStatus.loading;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: _kBlueSoft, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: isDone
                  ? _kGreen
                  : (isLoading
                      ? Colors.transparent
                      : _kBlueBg),
              shape: BoxShape.circle,
              border: isLoading
                  ? Border.all(color: _kBlue, width: 1.5)
                  : null,
            ),
            child: isDone
                ? const Icon(Icons.check_rounded,
                    color: Colors.white, size: 10)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(item.label,
                style: const TextStyle(fontSize: 10, color: _kBlueDark)),
          ),
          if (isDone)
            const Text('✓',
                style: TextStyle(fontSize: 9, color: _kBlueMid))
          else if (isLoading)
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                  strokeWidth: 1.5, color: _kBlue),
            )
          else
            Text('—',
                style: TextStyle(
                    fontSize: 9, color: _kBlueMid.withAlpha(100))),
        ],
      ),
    );
  }

  Widget _buildPendingCheckRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: _kBlueSoft, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: _kBlueBg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 80,
            height: 8,
            decoration: BoxDecoration(
              color: _kBlueSoft,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Spacer(),
          Text('—',
              style:
                  TextStyle(fontSize: 9, color: _kBlueMid.withAlpha(100))),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SCORE HELPERS
  // ═══════════════════════════════════════════════════════════════════

  List<_ScoreSection> _calculateScore(ManualCvModel cv) {
    final raw = _calculateRawScore(cv);
    // Override AI-fixed sections: give max points
    return raw.map((s) {
      if (_aiFixedSections.contains(s.key)) {
        return _ScoreSection(
          key: s.key,
          name: s.name,
          icon: s.icon,
          maxPoints: s.maxPoints,
          earnedPoints: s.maxPoints,
          priority: 'ok',
          tips: const [],
        );
      }
      return s;
    }).toList();
  }

  List<_ScoreSection> _calculateRawScore(ManualCvModel cv) {
    final sections = <_ScoreSection>[];
    final pi = cv.personalInfo;

    // 1. Informations personnelles (20 pts)
    int info = 0;
    final infoTips = <String>[];
    if (pi.fullName.isNotEmpty) info += 3;
    else infoTips.add('Ajoutez votre nom complet');
    if (pi.professionalTitle != null && pi.professionalTitle!.isNotEmpty) {
      info += 3;
    } else {
      infoTips.add('Ajoutez un titre professionnel');
    }
    if (pi.email != null && pi.email!.isNotEmpty) info += 3;
    else infoTips.add('Ajoutez votre email');
    if (pi.phone != null && pi.phone!.isNotEmpty) info += 3;
    else infoTips.add('Ajoutez votre téléphone');
    if (pi.city != null && pi.city!.isNotEmpty) info += 2;
    else infoTips.add('Ajoutez votre ville');
    if (pi.country != null && pi.country!.isNotEmpty) info += 2;
    if (pi.address != null && pi.address!.isNotEmpty) info += 2;
    if (pi.photoUrl != null && pi.photoUrl!.isNotEmpty) info += 1;
    if (pi.website != null && pi.website!.isNotEmpty) info += 1;
    sections.add(_ScoreSection(
      key: 'info',
      name: 'Informations',
      icon: Icons.person_outline_rounded,
      maxPoints: 20,
      earnedPoints: info,
      priority: _priority(info, 20),
      tips: infoTips,
    ));

    // 2. Bio / Summary (15 pts)
    int bio = 0;
    final bioTips = <String>[];
    final summary = pi.summary ?? '';
    if (summary.isNotEmpty) {
      bio += 5;
      if (summary.length > 50) {
        bio += 5;
      } else {
        bioTips.add('Développez votre résumé (min 50 caractères)');
      }
      if (summary.length > 150) {
        bio += 5;
      } else if (summary.length > 50) {
        bioTips.add('Un résumé détaillé améliore votre score (>150 car.)');
      }
    } else {
      bioTips.add('Ajoutez un résumé professionnel');
    }
    sections.add(_ScoreSection(
      key: 'bio',
      name: 'Résumé / Bio',
      icon: Icons.description_outlined,
      maxPoints: 15,
      earnedPoints: bio,
      priority: _priority(bio, 15),
      tips: bioTips,
    ));

    // 3. Expériences (25 pts)
    int exp = 0;
    final expTips = <String>[];
    if (cv.experiences.isNotEmpty) {
      exp += 8;
      if (cv.experiences.length >= 2) exp += 5;
      else expTips.add('Ajoutez au moins 2 expériences');
      if (cv.experiences.length >= 3) exp += 4;
      final withDesc = cv.experiences
          .where((e) => e.description != null && e.description!.isNotEmpty)
          .length;
      if (withDesc == cv.experiences.length) {
        exp += 8;
      } else if (withDesc > 0) {
        exp += 4;
        expTips.add('Décrivez toutes vos expériences');
      } else {
        expTips.add('Ajoutez des descriptions à vos expériences');
      }
    } else {
      expTips.add('Ajoutez vos expériences professionnelles');
    }
    sections.add(_ScoreSection(
      key: 'experiences',
      name: 'Expériences',
      icon: Icons.work_outline_rounded,
      maxPoints: 25,
      earnedPoints: exp,
      priority: _priority(exp, 25),
      tips: expTips,
    ));

    // 4. Compétences (20 pts)
    int skill = 0;
    final skillTips = <String>[];
    if (cv.skills.isNotEmpty) {
      skill += 5;
      if (cv.skills.length >= 3) skill += 5;
      else skillTips.add('Ajoutez au moins 3 compétences');
      if (cv.skills.length >= 5) skill += 5;
      else if (cv.skills.length >= 3) {
        skillTips.add('5+ compétences rend votre profil plus complet');
      }
      final withLevel = cv.skills
          .where((s) => s.level != null && s.level!.isNotEmpty)
          .length;
      if (withLevel == cv.skills.length) skill += 5;
      else skillTips.add('Précisez le niveau de chaque compétence');
    } else {
      skillTips.add('Ajoutez vos compétences techniques');
    }
    sections.add(_ScoreSection(
      key: 'skills',
      name: 'Compétences',
      icon: Icons.psychology_outlined,
      maxPoints: 20,
      earnedPoints: skill,
      priority: _priority(skill, 20),
      tips: skillTips,
    ));

    // 5. Formation (15 pts)
    int edu = 0;
    final eduTips = <String>[];
    if (cv.educations.isNotEmpty) {
      edu += 7;
      if (cv.educations.length >= 2) edu += 4;
      else eduTips.add('Ajoutez au moins 2 formations');
      final withDates =
          cv.educations.where((e) => e.startDate.isNotEmpty).length;
      if (withDates == cv.educations.length) edu += 4;
      else eduTips.add('Ajoutez les dates de vos formations');
    } else {
      eduTips.add('Ajoutez vos formations');
    }
    sections.add(_ScoreSection(
      key: 'educations',
      name: 'Formation',
      icon: Icons.school_outlined,
      maxPoints: 15,
      earnedPoints: edu,
      priority: _priority(edu, 15),
      tips: eduTips,
    ));

    // 6. Langues (5 pts)
    int lang = 0;
    final langTips = <String>[];
    if (cv.languages.isNotEmpty) {
      lang += 3;
      if (cv.languages.length >= 2) lang += 2;
      else langTips.add('Ajoutez au moins 2 langues');
    } else {
      langTips.add('Ajoutez les langues que vous maîtrisez');
    }
    sections.add(_ScoreSection(
      key: 'languages',
      name: 'Langues',
      icon: Icons.translate_rounded,
      maxPoints: 5,
      earnedPoints: lang,
      priority: _priority(lang, 5),
      tips: langTips,
    ));

    return sections;
  }

  String _priority(int earned, int max) {
    final pct = max > 0 ? earned / max : 0.0;
    if (pct >= 0.7) return 'ok';
    if (pct >= 0.4) return 'ameliorer';
    return 'urgent';
  }

  Color _scoreColor(double pct) {
    if (pct >= 0.7) return _kGreen;
    if (pct >= 0.4) return const Color(0xFFE67E22);
    return const Color(0xFFE74C3C);
  }

  String _scoreLabel(double pct) {
    if (pct >= 0.8) return 'Excellent !';
    if (pct >= 0.7) return 'Très bien';
    if (pct >= 0.5) return 'Peut mieux faire';
    if (pct >= 0.3) return 'Incomplet';
    return 'À compléter';
  }

  Color _priorityColor(String p) {
    if (p == 'ok') return _kGreen;
    if (p == 'ameliorer') return const Color(0xFFE67E22);
    return const Color(0xFFE74C3C);
  }

  Color _priorityBgColor(String p) {
    if (p == 'ok') return _kGreenBg;
    if (p == 'ameliorer') return const Color(0xFFFEF3E2);
    return const Color(0xFFFDEDED);
  }

  String _priorityLabel(String p) {
    if (p == 'ok') return '✓ OK';
    if (p == 'ameliorer') return '⬆ Améliorer';
    return '⚠ Urgent';
  }

  void _fixWithAi(_ScoreSection section) {
    // Build a rich, context-aware prompt for each section
    final data = _sectionData(section.key);
    final dataStr = data.isNotEmpty ? data.join(', ') : 'aucune donnée';
    final tipsStr = section.tips.isNotEmpty
        ? section.tips.join('. ')
        : '';
    final score = '${section.earnedPoints}/${section.maxPoints}';

    final base = <String, String>{
      'info':
          'Complète et améliore les informations personnelles du CV.\n'
          'Score actuel: $score.\n'
          'Données existantes: $dataStr.\n'
          '${tipsStr.isNotEmpty ? 'À corriger: $tipsStr.' : ''}',
      'bio':
          'Rédige un résumé professionnel percutant et détaillé.\n'
          'Score actuel: $score.\n'
          'Résumé existant: $dataStr.\n'
          '${tipsStr.isNotEmpty ? 'Conseils: $tipsStr.' : ''}',
      'experiences':
          'Améliore et détaille les descriptions des expériences professionnelles.\n'
          'Score actuel: $score.\n'
          'Expériences existantes: $dataStr.\n'
          '${tipsStr.isNotEmpty ? 'À améliorer: $tipsStr.' : ''}',
      'skills':
          'Enrichis la liste des compétences avec des niveaux précis.\n'
          'Score actuel: $score.\n'
          'Compétences existantes: $dataStr.\n'
          '${tipsStr.isNotEmpty ? 'À améliorer: $tipsStr.' : ''}',
      'educations':
          'Complète les informations de formation.\n'
          'Score actuel: $score.\n'
          'Formations existantes: $dataStr.\n'
          '${tipsStr.isNotEmpty ? 'À compléter: $tipsStr.' : ''}',
      'languages':
          'Ajoute les langues maîtrisées avec les niveaux.\n'
          'Score actuel: $score.\n'
          'Langues existantes: $dataStr.\n'
          '${tipsStr.isNotEmpty ? 'À ajouter: $tipsStr.' : ''}',
    };

    setState(() {
      if (_expandedKey == section.key && _expandMode == 'ai') {
        _expandedKey = null;
      } else {
        _expandedKey = section.key;
        _expandMode = 'ai';
        _aiPromptCtrl.text = base[section.key] ?? '';
      }
    });
  }

  Future<void> _submitAiPrompt() async {
    final prompt = _aiPromptCtrl.text.trim();
    if (prompt.isEmpty) return;
    final sectionKey = _expandedKey;
    setState(() => _aiFixLoading = true);
    try {
      final tpl = _templates[_selectedTpl];
      final aiCv = await _aiRepo.generate(
        language: _selectedLang,
        section: 'full',
        format: tpl.key,
        customPrompt: prompt,
      );
      if (!mounted) return;
      setState(() {
        _generatedId = aiCv.id;
        _generatedType = 'ai';
        _aiFixLoading = false;
        _expandedKey = null;
        if (sectionKey != null) _aiFixedSections.add(sectionKey);
      });
      CustomToast.success(context, 'Section améliorée par l\'IA ✓');
    } catch (e) {
      if (!mounted) return;
      setState(() => _aiFixLoading = false);
      CustomToast.error(context, 'Erreur: $e');
    }
  }

  void _toggleEditSection(_ScoreSection section) {
    setState(() {
      if (_expandedKey == section.key && _expandMode == 'edit') {
        _expandedKey = null;
      } else {
        _expandedKey = section.key;
        _expandMode = 'edit';
      }
    });
  }

  Future<void> _openFormEditor() async {
    if (_importedCv == null) return;
    final vm = ManualCvViewModel()..loadCvs();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ManualCvFormView(existingCv: _importedCv, viewModel: vm),
      ),
    );
    if (!mounted || _importedCv?.id == null) return;
    try {
      final cv = await _manualRepo.getById(_importedCv!.id!);
      setState(() {
        _importedCv = cv;
        _expandedKey = null;
      });
    } catch (_) {}
  }

  List<String> _sectionData(String key) {
    final cv = _importedCv;
    if (cv == null) return [];
    switch (key) {
      case 'info':
        final pi = cv.personalInfo;
        return [
          if (pi.fullName.isNotEmpty) 'Nom: ${pi.fullName}',
          if (pi.professionalTitle != null) 'Titre: ${pi.professionalTitle}',
          if (pi.email != null) 'Email: ${pi.email}',
          if (pi.phone != null) 'Tél: ${pi.phone}',
          if (pi.city != null) 'Ville: ${pi.city}',
          if (pi.country != null) 'Pays: ${pi.country}',
        ];
      case 'bio':
        final s = cv.personalInfo.summary ?? '';
        return s.isNotEmpty ? [s] : ['Aucun résumé'];
      case 'experiences':
        return cv.experiences.isEmpty
            ? ['Aucune expérience']
            : cv.experiences
                .map((e) => '${e.jobTitle} — ${e.company}')
                .toList();
      case 'skills':
        return cv.skills.isEmpty
            ? ['Aucune compétence']
            : cv.skills
                .map((s) =>
                    '${s.name}${s.level != null ? ' (${s.level})' : ''}')
                .toList();
      case 'educations':
        return cv.educations.isEmpty
            ? ['Aucune formation']
            : cv.educations.map((e) => '${e.degree} — ${e.school}').toList();
      case 'languages':
        return cv.languages.isEmpty
            ? ['Aucune langue']
            : cv.languages
                .map((l) =>
                    '${l.name}${l.level != null ? ' (${l.level})' : ''}')
                .toList();
      default:
        return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // SCREEN 3 (Score CV)
  // ═══════════════════════════════════════════════════════════════════
  Widget _screenScore() {
    if (_importedCv == null) {
      return const Center(child: CircularProgressIndicator(color: _kBlue));
    }

    final sections = _calculateScore(_importedCv!);
    final totalEarned = sections.fold<int>(0, (s, e) => s + e.earnedPoints);
    final pct = totalEarned / 100;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _topBar(left: '← Retour', title: 'Score CV', right: '3/5'),

          // ── Score gauge ──────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: _kBlueBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: 94,
                  height: 94,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: pct,
                          strokeWidth: 7,
                          strokeCap: StrokeCap.round,
                          backgroundColor: _kBlueSoft,
                          color: _scoreColor(pct),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$totalEarned',
                              style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: _scoreColor(pct))),
                          const Text('/100',
                              style:
                                  TextStyle(fontSize: 10, color: _kBlueMid)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(_scoreLabel(pct),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _scoreColor(pct))),
                const SizedBox(height: 4),
                const Text(
                  'Complétez les sections ci-dessous\npour améliorer votre score',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 9, color: _kBlueMid, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Section breakdown ────────────────────────────
          ...sections.map(_buildScoreCard),

          const SizedBox(height: 14),

          // ── Continue button ──────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _goTo(3),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Choisir un template →',
                  style:
                      TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(_ScoreSection s) {
    final pct = s.maxPoints > 0 ? s.earnedPoints / s.maxPoints : 0.0;
    final color = _priorityColor(s.priority);
    final bg = _priorityBgColor(s.priority);
    final isExpanded = _expandedKey == s.key;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isExpanded ? _kBlue : AppTheme.dividerColor,
            width: isExpanded ? 1.5 : 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(s.icon, size: 14, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(s.name,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textColor)),
                        const Spacer(),
                        if (_aiFixedSections.contains(s.key))
                          Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _kGreenBg,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_awesome_rounded,
                                    size: 8, color: _kGreenDark),
                                SizedBox(width: 3),
                                Text('IA',
                                    style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w600,
                                        color: _kGreenDark)),
                              ],
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(_priorityLabel(s.priority),
                              style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                  color: color)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 4,
                              backgroundColor: AppTheme.dividerColor,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${s.earnedPoints}/${s.maxPoints}',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: color)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Recommendations
          if (s.tips.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...s.tips.map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        s.priority == 'urgent'
                            ? Icons.error_outline_rounded
                            : Icons.lightbulb_outline_rounded,
                        size: 12,
                        color: color,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(tip,
                            style: TextStyle(
                                fontSize: 9,
                                color: AppTheme.textMutedColor)),
                      ),
                    ],
                  ),
                )),
          ],

          // Action buttons
          if (s.priority != 'ok') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                GestureDetector(
                  onTap: () => _fixWithAi(s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isExpanded && _expandMode == 'ai'
                          ? _kBlue
                          : _kBlueBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_fix_high_rounded,
                            size: 12,
                            color: isExpanded && _expandMode == 'ai'
                                ? Colors.white
                                : _kBlue),
                        const SizedBox(width: 6),
                        Text('Corriger avec l\'IA',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: isExpanded && _expandMode == 'ai'
                                    ? Colors.white
                                    : _kBlue)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _toggleEditSection(s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isExpanded && _expandMode == 'edit'
                          ? AppTheme.textMutedColor
                          : Colors.transparent,
                      border: Border.all(
                          color: isExpanded && _expandMode == 'edit'
                              ? AppTheme.textMutedColor
                              : AppTheme.dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_outlined,
                            size: 12,
                            color: isExpanded && _expandMode == 'edit'
                                ? Colors.white
                                : AppTheme.textMutedColor),
                        const SizedBox(width: 6),
                        Text('Modifier',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: isExpanded && _expandMode == 'edit'
                                    ? Colors.white
                                    : AppTheme.textMutedColor)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],

          // ── Expanded: AI prompt ────────────────────────
          if (isExpanded && _expandMode == 'ai') ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _kBlueBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Prompt IA',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: _kBlueDark)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _aiPromptCtrl,
                    maxLines: 3,
                    style: TextStyle(
                        fontSize: 10, color: AppTheme.textColor),
                    decoration: InputDecoration(
                      hintText: 'Décrivez ce que l\'IA doit améliorer...',
                      hintStyle: TextStyle(
                          fontSize: 10, color: AppTheme.textMutedColor),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      filled: true,
                      fillColor: AppTheme.cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: AppTheme.dividerColor, width: 0.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: AppTheme.dividerColor, width: 0.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: _kBlue, width: 1.2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _aiFixLoading ? null : _submitAiPrompt,
                      icon: _aiFixLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.auto_awesome_rounded, size: 14),
                      label: Text(
                          _aiFixLoading
                              ? 'Traitement en cours...'
                              : 'Lancer l\'IA',
                          style: const TextStyle(fontSize: 10)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kBlue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _kBlueSoft,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Expanded: Current data ─────────────────────
          if (isExpanded && _expandMode == 'edit') ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.isLight
                    ? const Color(0xFFF8F9FA)
                    : AppColors.darkSurfaceColor,
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppTheme.dividerColor, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Données actuelles',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textColor)),
                  const SizedBox(height: 6),
                  ..._sectionData(s.key).map((d) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('•  ',
                                style: TextStyle(
                                    fontSize: 9, color: _kBlue)),
                            Expanded(
                              child: Text(d,
                                  style: TextStyle(
                                      fontSize: 9,
                                      color: AppTheme.textMutedColor,
                                      height: 1.3)),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openFormEditor,
                      icon: const Icon(Icons.open_in_new_rounded, size: 13),
                      label: const Text('Ouvrir le formulaire',
                          style: TextStyle(fontSize: 10)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kBlue,
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        side: const BorderSide(color: _kBlue, width: 1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SCREEN 4 — Template + AI
  // ═══════════════════════════════════════════════════════════════════
  Widget _screen3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _topBar(
              left: '← Retour',
              title: 'Choisir un style',
              right: '4/5'),

          // Success badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _kBlueBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: _kGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 9),
                ),
                const SizedBox(width: 8),
                const Text('Profil importé avec succès !',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _kBlueDark)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Template grid title
          Text('Sélectionnez votre template',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor)),
          const SizedBox(height: 10),

          // Template grid  — 3 columns
          SizedBox(
            height: 115,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _templates.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final t = _templates[i];
                final active = i == _selectedTpl;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTpl = i),
                  child: Container(
                    width: 88,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: active ? _kBlue : AppTheme.dividerColor,
                        width: active ? 2 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        // Template preview
                        Container(
                          height: 56,
                          color: t.bg,
                          padding: const EdgeInsets.all(6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                  width: 42,
                                  height: 4,
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(2))),
                              const SizedBox(height: 3),
                              Container(
                                  width: 30,
                                  height: 3,
                                  decoration: BoxDecoration(
                                      color: t.accent,
                                      borderRadius:
                                          BorderRadius.circular(2))),
                              const Spacer(),
                              Container(
                                  width: 50,
                                  height: 2,
                                  decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(100),
                                      borderRadius:
                                          BorderRadius.circular(2))),
                              const SizedBox(height: 2),
                              Container(
                                  width: 36,
                                  height: 2,
                                  decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(70),
                                      borderRadius:
                                          BorderRadius.circular(2))),
                            ],
                          ),
                        ),
                        // Badge
                        Expanded(
                          child: Container(
                            color: AppTheme.cardColor,
                            alignment: Alignment.center,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: active ? _kBlue : _kBlueBg,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                active ? 'Sélectionné' : t.label,
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                  color: active
                                      ? Colors.white
                                      : _kBlueMid,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Language selector
          Text('Langue',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textColor)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _langChip('Français', 'fr'),
              _langChip('English', 'en'),
              _langChip('العربية', 'ar'),
              _langChip('Español', 'es'),
            ],
          ),
          const SizedBox(height: 14),

          // Color palette
          Row(
            children: [
              Text('Couleur principale',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor)),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => setState(
                    () => _selectedColor = const Color(0xFF0A66C2)),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kBlueBg,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text('Défaut',
                      style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                          color: _kBlueDark)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _colorPalette.map((c) {
              final active = _selectedColor.value == c.value;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = c),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: active
                        ? Border.all(color: AppTheme.textColor, width: 2.5)
                        : Border.all(
                            color: AppTheme.dividerColor, width: 0.5),
                    boxShadow: active
                        ? [
                            BoxShadow(
                                color: c.withAlpha(80),
                                blurRadius: 6,
                                spreadRadius: 1)
                          ]
                        : null,
                  ),
                  child: active
                      ? const Icon(Icons.check_rounded,
                          size: 14, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Font selector
          Row(
            children: [
              Text('Police',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor)),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => setState(() => _selectedFont = 'Roboto'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kBlueBg,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text('Défaut',
                      style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                          color: _kBlueDark)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _fontOptions.map((f) {
              final active = _selectedFont == f;
              return GestureDetector(
                onTap: () => setState(() => _selectedFont = f),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: active ? _kBlue : AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: active ? _kBlue : AppTheme.dividerColor),
                  ),
                  child: Text(f,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              active ? FontWeight.w600 : FontWeight.w500,
                          color:
                              active ? Colors.white : AppTheme.textColor)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // AI enhancement
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppTheme.dividerColor, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Instructions pour l'IA",
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textColor)),
                const SizedBox(height: 3),
                Text('Décrivez ce que vous voulez générer ou modifier',
                    style: TextStyle(
                        fontSize: 9, color: AppTheme.textMutedColor)),
                const SizedBox(height: 8),
                TextField(
                  controller: _jobCtrl,
                  maxLines: 3,
                  minLines: 1,
                  style: TextStyle(
                      fontSize: 10, color: AppTheme.textColor),
                  decoration: InputDecoration(
                    hintText: 'Ex: Optimise pour poste Flutter, ajoute un résumé professionnel, reformule les expériences...',
                    hintStyle: TextStyle(
                        fontSize: 10, color: AppTheme.textMutedColor),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    filled: true,
                    fillColor: AppTheme.isLight
                        ? const Color(0xFFF5F5F5)
                        : AppColors.darkSurfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: AppTheme.dividerColor, width: 0.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: AppTheme.dividerColor, width: 0.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: _kBlue, width: 1.2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Generate button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _generating ? null : _generateCv,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _generating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Générer mon CV →',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _langChip(String label, String code) {
    final active = _selectedLang == code;
    return GestureDetector(
      onTap: () => setState(() => _selectedLang = code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? _kBlue : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: active ? _kBlue : AppTheme.dividerColor),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: active ? Colors.white : AppTheme.textColor)),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SCREEN 4 — CV Preview + Export
  // ═══════════════════════════════════════════════════════════════════
  Widget _screen4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _topBar(left: '← Modifier', title: 'Mon CV', right: null),
          // Prêt badge
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _kGreenBg,
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 12, color: _kGreenDark),
                  SizedBox(width: 4),
                  Text('Prêt',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: _kGreenDark)),
                ],
              ),
            ),
          ),

          // CV frame
          if (_loadingPdf)
            Container(
              height: 320,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.dividerColor, width: 0.5),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                        strokeWidth: 2.5, color: _kBlue),
                    SizedBox(height: 12),
                    Text('Génération du PDF...',
                        style: TextStyle(fontSize: 11, color: _kBlueMid)),
                  ],
                ),
              ),
            )
          else if (_importedCv != null)
            _buildCvFrame()
          else
            Container(
              height: 320,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppTheme.dividerColor, width: 0.5),
              ),
              child: Center(
                child: Text('Aperçu non disponible',
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.textMutedColor)),
              ),
            ),
          const SizedBox(height: 12),

          // Export row (matches mockup: Share | Edit | Download PDF)
          Row(
            children: [
              _exportBtn('Partager', Icons.share_outlined, false,
                  onTap: _sharePdf),
              const SizedBox(width: 6),
              _exportBtn('Modifier', Icons.edit_outlined, false,
                  onTap: () => _goTo(3)),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: _downloadPdf,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _kBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.picture_as_pdf_rounded,
                            size: 14, color: Colors.white),
                        SizedBox(width: 5),
                        Text('Télécharger PDF',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _exportBtn(String label, IconData icon, bool primary,
      {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(
                color: AppTheme.dividerColor, width: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontSize: 10, color: AppTheme.textMutedColor)),
          ),
        ),
      ),
    );
  }

  // ─── CV Frame widget (matches mockup exactly) ─────────────────────
  Widget _buildCvFrame() {
    final cv = _importedCv!;
    final pi = cv.personalInfo;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor, width: 0.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Blue header
          Container(
            padding: const EdgeInsets.all(12),
            color: _kBlue,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: _kBlueSoft,
                  child: Text(
                    _initials(pi.fullName),
                    style: const TextStyle(
                        color: _kBlueDark,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pi.fullName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                      if (pi.professionalTitle != null)
                        Text(
                          '${pi.professionalTitle}${pi.city != null ? ' · ${pi.city}' : ''}',
                          style: const TextStyle(
                              color: Color(0xFF85B7EB), fontSize: 9),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body
          Container(
            color: AppTheme.cardColor,
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Experience section
                if (cv.experiences.isNotEmpty) ...[
                  _cvSection('EXPÉRIENCE'),
                  ...cv.experiences.take(3).map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${e.jobTitle} — ${e.company}',
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textColor)),
                            Text(
                              '${e.startDate}${e.current ? ' – Présent' : (e.endDate != null ? ' – ${e.endDate}' : '')}',
                              style: TextStyle(
                                  fontSize: 8,
                                  color: AppTheme.textMutedColor),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 6),
                ],

                // Education section
                if (cv.educations.isNotEmpty) ...[
                  _cvSection('FORMATION'),
                  ...cv.educations.take(2).map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.degree,
                                style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textColor)),
                            Text('${e.school} · ${e.startDate}',
                                style: TextStyle(
                                    fontSize: 8,
                                    color: AppTheme.textMutedColor)),
                          ],
                        ),
                      )),
                  const SizedBox(height: 6),
                ],

                // Skills section
                if (cv.skills.isNotEmpty) ...[
                  _cvSection('COMPÉTENCES'),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: cv.skills.take(8).map((s) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _kBlueBg,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(s.name,
                            style: const TextStyle(
                                fontSize: 8,
                                color: _kBlueDark,
                                fontWeight: FontWeight.w500)),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cvSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        padding: const EdgeInsets.only(bottom: 3),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _kBlueSoft, width: 0.5)),
        ),
        child: Text(title,
            style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: _kBlue,
                letterSpacing: 0.5)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Helper classes
// ═══════════════════════════════════════════════════════════════════════════════

enum _ScanStatus { pending, loading, done }

class _ScanItem {
  final String label;
  final IconData icon;
  _ScanStatus status;
  _ScanItem(this.label, this.icon, {this.status = _ScanStatus.pending});
}

class _Tpl {
  final String key;
  final String label;
  final Color bg;
  final Color accent;
  const _Tpl(this.key, this.label, this.bg, this.accent);
}

class _ScoreSection {
  final String key;
  final String name;
  final IconData icon;
  final int maxPoints;
  final int earnedPoints;
  final String priority; // 'ok', 'ameliorer', 'urgent'
  final List<String> tips;
  const _ScoreSection({
    required this.key,
    required this.name,
    required this.icon,
    required this.maxPoints,
    required this.earnedPoints,
    required this.priority,
    this.tips = const [],
  });
}

/// Paints a quarter-arc for the spinner (mimics CSS border-top trick)
class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _kBlue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final rect = Offset.zero & size;
    canvas.drawArc(rect.deflate(1.5), -1.57, 1.57, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
