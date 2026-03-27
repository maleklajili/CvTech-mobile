import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/presentation/views_models/profile/ai_cv_view_model.dart';
import 'package:cv_tech/data/models/profile/ai_cv_model.dart';
import 'package:cv_tech/data/repositories/user_repository.dart';
import 'package:cv_tech/utils/cv_pdf_generator.dart';

class AiCvView extends StatelessWidget {
  const AiCvView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AiCvViewModel()..loadCvs(),
      child: const _AiCvContent(),
    );
  }
}

class _AiCvContent extends StatefulWidget {
  const _AiCvContent();

  @override
  State<_AiCvContent> createState() => _AiCvContentState();
}

class _AiCvContentState extends State<_AiCvContent> {
  final _promptController = TextEditingController();
  final _reformulateController = TextEditingController();

  @override
  void dispose() {
    _promptController.dispose();
    _reformulateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CV IA'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AiCvViewModel>().loadCvs(),
          ),
        ],
      ),
      body: Consumer<AiCvViewModel>(
        builder: (context, vm, _) {
          if (vm.selectedCv != null) {
            return _buildCvDetailView(context, vm);
          }
          return _buildMainView(context, vm);
        },
      ),
    );
  }

  Widget _buildMainView(BuildContext context, AiCvViewModel vm) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGenerateCard(context, vm),
          const SizedBox(height: 24),
          _buildCvsList(context, vm),
        ],
      ),
    );
  }

  Widget _buildGenerateCard(BuildContext context, AiCvViewModel vm) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Générer un CV avec l\'IA',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'L\'IA analyse votre profil (formation, expérience, compétences, projets) et génère un CV professionnel.',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Language selector
            const Text('Langue', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildIconChip(
                  icon: Icons.translate,
                  label: 'Français',
                  selected: vm.selectedLanguage == 'fr',
                  onTap: () => vm.setLanguage('fr'),
                ),
                const SizedBox(width: 8),
                _buildIconChip(
                  icon: Icons.language,
                  label: 'English',
                  selected: vm.selectedLanguage == 'en',
                  onTap: () => vm.setLanguage('en'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section selector
            const Text(
              'Section à générer',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildChip(
                  label: 'CV Complet',
                  selected: vm.selectedSection == 'full',
                  onTap: () => vm.setSection('full'),
                ),
                _buildChip(
                  label: 'Résumé',
                  selected: vm.selectedSection == 'summary',
                  onTap: () => vm.setSection('summary'),
                ),
                _buildChip(
                  label: 'Expérience',
                  selected: vm.selectedSection == 'experience',
                  onTap: () => vm.setSection('experience'),
                ),
                _buildChip(
                  label: 'Formation',
                  selected: vm.selectedSection == 'education',
                  onTap: () => vm.setSection('education'),
                ),
                _buildChip(
                  label: 'Compétences',
                  selected: vm.selectedSection == 'skills',
                  onTap: () => vm.setSection('skills'),
                ),
                _buildChip(
                  label: 'Projets',
                  selected: vm.selectedSection == 'projects',
                  onTap: () => vm.setSection('projects'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Format selector
            const Text(
              'Type de CV',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildIconChip(
                  icon: Icons.description_outlined,
                  label: 'Standard',
                  selected: vm.selectedFormat == 'standard',
                  onTap: () => vm.setFormat('standard'),
                ),
                _buildIconChip(
                  icon: Icons.flag_outlined,
                  label: 'Canadien',
                  selected: vm.selectedFormat == 'canadian',
                  onTap: () => vm.setFormat('canadian'),
                ),
                _buildIconChip(
                  icon: Icons.code,
                  label: 'LaTeX',
                  selected: vm.selectedFormat == 'latex',
                  onTap: () => vm.setFormat('latex'),
                ),
                _buildIconChip(
                  icon: Icons.auto_awesome_outlined,
                  label: 'Moderne',
                  selected: vm.selectedFormat == 'modern',
                  onTap: () => vm.setFormat('modern'),
                ),
                _buildIconChip(
                  icon: Icons.account_circle_outlined,
                  label: 'Européen',
                  selected: vm.selectedFormat == 'european',
                  onTap: () => vm.setFormat('european'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Custom prompt
            TextField(
              controller: _promptController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'Instructions supplémentaires (optionnel)\nEx: "Mets l\'accent sur le développement mobile"',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 16),

            // Generate button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: vm.isGenerating
                    ? null
                    : () {
                        vm.generateCv(
                          customPrompt: _promptController.text.isNotEmpty
                              ? _promptController.text
                              : null,
                        );
                      },
                icon: vm.isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  vm.isGenerating ? 'Génération en cours...' : 'Générer mon CV',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            if (vm.error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        vm.error!,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCvsList(BuildContext context, AiCvViewModel vm) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (vm.cvs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.description_outlined,
                  size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'Aucun CV généré',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Utilisez le bouton ci-dessus pour générer votre premier CV',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mes CVs générés',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...vm.cvs.map((cv) => _buildCvCard(context, vm, cv)),
      ],
    );
  }

  Widget _buildCvCard(BuildContext context, AiCvViewModel vm, AiCvModel cv) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => vm.selectCv(cv),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getSectionIcon(cv.section),
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cv.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildStatusBadge(cv.status),
                        const SizedBox(width: 8),
                        Text(
                          'v${cv.version}',
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          cv.language == 'fr' ? 'FR' : 'EN',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (cv.createdAt != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(cv.createdAt!),
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    _showDeleteDialog(context, vm, cv);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCvDetailView(BuildContext context, AiCvViewModel vm) {
    final cv = vm.selectedCv!;
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => vm.selectCv(null),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cv.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${cv.status == 'reformulated' ? 'Reformulé' : 'Généré'} • v${cv.version}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                tooltip: 'Copier',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: cv.content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('CV copié dans le presse-papiers')),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Télécharger PDF',
                onPressed: () => _showDownloadDialog(context, cv),
              ),
              IconButton(
                icon: Icon(Icons.auto_fix_high, color: AppColors.primaryColor),
                tooltip: 'Reformuler',
                onPressed: () => _showReformulateDialog(context, vm, cv),
              ),
            ],
          ),
        ),

        // CV Content
        Expanded(
          child: Markdown(
            data: cv.content,
            selectable: true,
            padding: const EdgeInsets.all(16),
            styleSheet: MarkdownStyleSheet(
              h1: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              h3: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              p: const TextStyle(fontSize: 14, height: 1.6),
              listBullet: const TextStyle(fontSize: 14),
              strong: const TextStyle(fontWeight: FontWeight.bold),
              blockSpacing: 12,
            ),
          ),
        ),
      ],
    );
  }

  // ---- Helpers ----

  Widget _buildChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryColor.withOpacity(0.15)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primaryColor : Colors.grey[700],
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildIconChip({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryColor.withOpacity(0.15)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AppColors.primaryColor : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primaryColor : Colors.grey[700],
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isReformulated = status == 'reformulated';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isReformulated ? Colors.blue.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isReformulated ? 'Reformulé' : 'Généré',
        style: TextStyle(
          color: isReformulated ? Colors.blue.shade700 : Colors.green.shade700,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  IconData _getSectionIcon(String section) {
    switch (section) {
      case 'summary':
        return Icons.person_outline;
      case 'experience':
        return Icons.work_outline;
      case 'education':
        return Icons.school_outlined;
      case 'skills':
        return Icons.star_outline;
      case 'projects':
        return Icons.folder_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showDeleteDialog(
      BuildContext context, AiCvViewModel vm, AiCvModel cv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce CV ?'),
        content: Text('Voulez-vous supprimer "${cv.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (cv.id != null) vm.deleteCv(cv.id!);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showReformulateDialog(
      BuildContext context, AiCvViewModel vm, AiCvModel cv) {
    _reformulateController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reformuler le CV'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'L\'IA va améliorer et reformuler votre CV. Vous pouvez ajouter des instructions spécifiques.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reformulateController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'Instructions (optionnel)\nEx: "Ton plus formel", "Ajoute des mots-clés ATS"',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (cv.id != null) {
                vm.reformulateCv(
                  cv.id!,
                  instructions: _reformulateController.text.isNotEmpty
                      ? _reformulateController.text
                      : null,
                );
              }
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor),
            child:
                const Text('Reformuler', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDownloadDialog(BuildContext context, AiCvModel cv) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Télécharger le CV en PDF'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choisissez un template pour le PDF:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildTemplateOption(
              ctx: ctx,
              icon: Icons.description_outlined,
              label: 'Standard',
              description: 'Mise en page classique et professionnelle',
              onTap: () {
                Navigator.pop(ctx);
                _downloadAsPdf(context, cv, CvTemplate.standard);
              },
            ),
            const SizedBox(height: 8),
            _buildTemplateOption(
              ctx: ctx,
              icon: Icons.auto_awesome_outlined,
              label: 'Moderne',
              description: 'Design deux colonnes avec sidebar colorée',
              onTap: () {
                Navigator.pop(ctx);
                _downloadAsPdf(context, cv, CvTemplate.modern);
              },
            ),
            const SizedBox(height: 8),
            _buildTemplateOption(
              ctx: ctx,
              icon: Icons.flag_outlined,
              label: 'Canadien (ATS)',
              description: 'ATS-friendly, méthode STAR, sans photo',
              onTap: () {
                Navigator.pop(ctx);
                _downloadAsPdf(context, cv, CvTemplate.canadian);
              },
            ),
            const SizedBox(height: 8),
            _buildTemplateOption(
              ctx: ctx,
              icon: Icons.school_outlined,
              label: 'LaTeX Académique',
              description: 'Style académique, police serif, publications',
              onTap: () {
                Navigator.pop(ctx);
                _downloadAsPdf(context, cv, CvTemplate.latex);
              },
            ),
            const SizedBox(height: 8),
            _buildTemplateOption(
              ctx: ctx,
              icon: Icons.account_circle_outlined,
              label: 'Européen avec photo',
              description: 'Sidebar avec photo, barres de compétences',
              onTap: () {
                Navigator.pop(ctx);
                _downloadAsPdf(context, cv, CvTemplate.european);
              },
            ),
            const SizedBox(height: 8),
            _buildTemplateOption(
              ctx: ctx,
              icon: Icons.text_snippet_outlined,
              label: 'Texte brut',
              description: 'Export Markdown vers PDF simple',
              onTap: () {
                Navigator.pop(ctx);
                _downloadAsMarkdownPdf(context, cv);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateOption({
    required BuildContext ctx,
    required IconData icon,
    required String label,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadAsPdf(
    BuildContext context,
    AiCvModel cv,
    CvTemplate template,
  ) async {
    try {
      // Show loading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 12),
                Text('Génération du PDF en cours...'),
              ],
            ),
            duration: Duration(seconds: 10),
          ),
        );
      }

      // Parse the AI-generated markdown content into structured sections
      final sections = _parseCvContent(cv);

      // Fetch user's profile photo if available
      Uint8List? photoBytes;
      try {
        final userRepo = UserRepository();
        final user = await userRepo.getCurrentUser();
        final imageUrl = user.imageUrl;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          final dio = Dio();
          final response = await dio.get<List<int>>(
            imageUrl,
            options: Options(responseType: ResponseType.bytes),
          );
          if (response.statusCode == 200 && response.data != null) {
            photoBytes = Uint8List.fromList(response.data!);
          }
        }
      } catch (_) {
        // Photo fetch failed silently, continue without photo
      }

      await CvPdfGenerator.generateFromProfile(
        sections: sections,
        template: template,
        photoBytes: photoBytes,
        title: cv.title,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _downloadAsMarkdownPdf(
    BuildContext context,
    AiCvModel cv,
  ) async {
    try {
      await CvPdfGenerator.generateAndShare(cv.title, cv.content);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  /// Parse AI-generated markdown CV content into structured sections
  Map<String, dynamic> _parseCvContent(AiCvModel cv) {
    final lines = cv.content.split('\n');
    String name = '';
    String title = '';
    String contact = '';
    String summary = '';
    final experience = <Map<String, dynamic>>[];
    final education = <Map<String, dynamic>>[];
    final skills = <Map<String, dynamic>>[];
    final projects = <Map<String, dynamic>>[];

    String currentSection = '';
    final buffer = StringBuffer();
    bool nameFound = false;

    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed.startsWith('# ')) {
        name = trimmed.substring(2).replaceAll(RegExp(r'\*+'), '').trim();
        nameFound = true;
        continue;
      }

      // Line right after the name that isn't a section header = title/subtitle
      if (nameFound && title.isEmpty && !trimmed.startsWith('##') && trimmed.isNotEmpty && currentSection.isEmpty) {
        // Check if it looks like a job title (no bullet, no special prefix)
        if (!trimmed.startsWith('-') && !trimmed.startsWith('*') && !trimmed.startsWith('#')) {
          final clean = trimmed.replaceAll(RegExp(r'\*+|_+'), '').trim();
          // If it contains contact info, treat as contact
          if (clean.contains('@') || clean.contains('+') || clean.contains('http') || clean.contains('linkedin')) {
            contact += '$clean\n';
          } else if (clean.length < 80) {
            title = clean;
          }
          continue;
        }
      }

      if (trimmed.startsWith('## ')) {
        // Save previous section
        if (currentSection == 'summary') {
          summary = buffer.toString().trim();
        } else if (currentSection == 'contact') {
          contact = buffer.toString().trim();
        } else {
          _saveSection(currentSection, buffer, experience, education, skills, projects);
        }
        buffer.clear();
        _saveSection(currentSection, buffer, experience, education, skills, projects);
        buffer.clear();

        final sectionName = trimmed.substring(3).toLowerCase();
        if (sectionName.contains('profil') || sectionName.contains('summary') || sectionName.contains('résumé')) {
          currentSection = 'summary';
        } else if (sectionName.contains('expérience') || sectionName.contains('experience')) {
          currentSection = 'experience';
        } else if (sectionName.contains('formation') || sectionName.contains('education')) {
          currentSection = 'education';
        } else if (sectionName.contains('compétence') || sectionName.contains('skill')) {
          currentSection = 'skills';
        } else if (sectionName.contains('projet') || sectionName.contains('project')) {
          currentSection = 'projects';
        } else if (sectionName.contains('contact')) {
          currentSection = 'contact';
        } else {
          currentSection = sectionName;
        }
        continue;
      }

      if (trimmed.isNotEmpty) {
        buffer.writeln(trimmed);
      }
    }
    // Save the last section
    if (currentSection == 'summary') {
      summary = buffer.toString().trim();
    } else if (currentSection == 'contact') {
      contact = buffer.toString().trim();
    } else {
      _saveSection(currentSection, buffer, experience, education, skills, projects);
    }

    if (contact.isEmpty) {
      // Try to extract contact from content
      contact = cv.content
          .split('\n')
          .where((l) => l.contains('@') || l.contains('+') || l.contains('http'))
          .take(3)
          .join('\n');
    }

    return {
      'name': name,
      'title': title,
      'contact': contact,
      'summary': summary.isEmpty ? buffer.toString().trim() : summary,
      'experience': experience,
      'education': education,
      'skills': skills,
      'projects': projects,
    };
  }

  void _saveSection(
    String section,
    StringBuffer buffer,
    List<Map<String, dynamic>> experience,
    List<Map<String, dynamic>> education,
    List<Map<String, dynamic>> skills,
    List<Map<String, dynamic>> projects,
  ) {
    final text = buffer.toString().trim();
    if (text.isEmpty) return;

    switch (section) {
      case 'experience':
        _parseExperience(text, experience);
        break;
      case 'education':
        _parseEducation(text, education);
        break;
      case 'skills':
        _parseSkills(text, skills);
        break;
      case 'projects':
        _parseProjects(text, projects);
        break;
    }
  }

  void _parseExperience(String text, List<Map<String, dynamic>> list) {
    final entries = text.split(RegExp(r'\n(?=\*\*|###)'));
    for (final entry in entries) {
      final lines = entry.split('\n').where((l) => l.trim().isNotEmpty).toList();
      if (lines.isEmpty) continue;
      final firstLine = lines.first.replaceAll(RegExp(r'\*+|#+'), '').trim();
      final achievements = lines
          .where((l) => l.trim().startsWith('-') || l.trim().startsWith('*'))
          .map((l) => l.replaceFirst(RegExp(r'^[\s\-*]+'), '').trim())
          .toList();
      list.add({
        'post': firstLine,
        'company': lines.length > 1 ? lines[1].replaceAll(RegExp(r'[\*_]'), '').trim() : '',
        'location': '',
        'dates': '',
        'description': '',
        'achievements': achievements,
      });
    }
  }

  void _parseEducation(String text, List<Map<String, dynamic>> list) {
    final entries = text.split(RegExp(r'\n(?=\*\*|###|-\s)'));
    for (final entry in entries) {
      final clean = entry.replaceAll(RegExp(r'[\*#]+'), '').trim();
      if (clean.isEmpty) continue;
      final parts = clean.split('\n');
      list.add({
        'degree': parts.isNotEmpty ? parts[0].replaceFirst(RegExp(r'^-\s*'), '').trim() : '',
        'school': parts.length > 1 ? parts[1].trim() : '',
        'dates': '',
      });
    }
  }

  void _parseSkills(String text, List<Map<String, dynamic>> list) {
    for (final line in text.split('\n')) {
      final clean = line.replaceFirst(RegExp(r'^[\-*]\s*'), '').trim();
      if (clean.isEmpty) continue;
      if (clean.contains(':')) {
        final parts = clean.split(':');
        final cat = parts[0].replaceAll(RegExp(r'\*+'), '').trim();
        final items = parts.sublist(1).join(':').split(RegExp(r'[,|]'));
        for (final item in items) {
          if (item.trim().isNotEmpty) {
            list.add({'name': item.trim(), 'category': cat});
          }
        }
      } else {
        list.add({'name': clean.replaceAll(RegExp(r'\*+'), '').trim()});
      }
    }
  }

  void _parseProjects(String text, List<Map<String, dynamic>> list) {
    final entries = text.split(RegExp(r'\n(?=\*\*|###)'));
    for (final entry in entries) {
      final lines = entry.split('\n').where((l) => l.trim().isNotEmpty).toList();
      if (lines.isEmpty) continue;
      list.add({
        'title': lines.first.replaceAll(RegExp(r'[\*#]+'), '').trim(),
        'description': lines.length > 1 ? lines.sublist(1).join(' ').replaceAll(RegExp(r'[\*_]'), '').trim() : '',
      });
    }
  }
}
