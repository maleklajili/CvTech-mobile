import 'package:flutter/material.dart';
import 'package:cv_tech/core/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/core/services/pdf_download_service.dart';
import 'package:cv_tech/presentation/views_models/profile/ai_cv_view_model.dart';
import 'package:cv_tech/data/models/profile/ai_cv_model.dart';
import 'package:cv_tech/data/repositories/ai_cv_repository.dart';
import 'package:cv_tech/presentation/widgets/common/custom_toast.dart';
import 'package:cv_tech/presentation/widgets/common/custom_alert_dialog.dart';
import 'package:cv_tech/presentation/views/profile/cv_customization_screen.dart';

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

  @override
  void dispose() {
    _promptController.dispose();
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
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
                        style: TextStyle(color: Colors.red.shade700, fontSize: 15),
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
                style: TextStyle(color: Colors.grey[400], fontSize: 15),
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
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
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
                              color: Colors.grey[500], fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          cv.language == 'fr' ? 'FR' : 'EN',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (cv.createdAt != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(cv.createdAt!),
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 15),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'pdf') {
                    _downloadAsPdf(context, cv);
                  } else if (value == 'delete') {
                    _showDeleteDialog(context, vm, cv);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'pdf',
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('Télécharger PDF'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context).delete, style: const TextStyle(color: Colors.red)),
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
                color: Colors.black.withValues(alpha: 0.05),
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
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                tooltip: 'Copier',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: cv.content));
                  CustomToast.success(context, 'CV copié dans le presse-papiers');
                },
              ),
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Télécharger PDF',
                onPressed: () => _downloadAsPdf(context, cv),
              ),
              IconButton(
                icon: Icon(Icons.auto_fix_high, color: AppColors.primaryColor),
                tooltip: 'Reformuler',
                onPressed: () => _showReformulateDialog(context, vm, cv),
              ),
            ],
          ),
        ),

        // CV Content — Dynamic rendering (HTML or Markdown)
        Expanded(
          child: _buildCvContent(cv.content),
        ),
      ],
    );
  }

  // ---- CV Content Renderer (HTML or Markdown) ----

  Widget _buildCvContent(String content) {
    // Detect if content is HTML (new template-based output)
    bool isHtml = content.trim().startsWith('<!DOCTYPE') || 
                  content.trim().startsWith('<html') ||
                  content.trim().startsWith('<HTML');
    
    if (isHtml) {
      // Render as HTML using flutter_html
      return SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Html(
          data: content,
          style: {
            "html": Style(
              backgroundColor: Colors.white,
              margin: Margins.all(0),
              padding: HtmlPaddings.all(8),
              fontSize: FontSize(14),
            ),
            "body": Style(
              backgroundColor: Colors.white,
              margin: Margins.all(0),
              padding: HtmlPaddings.all(8),
            ),
            "h1": Style(
              fontSize: FontSize(24),
              fontWeight: FontWeight.bold,
              margin: Margins.symmetric(vertical: 12),
              color: Colors.black87,
            ),
            "h2": Style(
              fontSize: FontSize(20),
              fontWeight: FontWeight.bold,
              margin: Margins.symmetric(vertical: 10),
              color: Colors.black87,
            ),
            "h3": Style(
              fontSize: FontSize(16),
              fontWeight: FontWeight.w600,
              margin: Margins.symmetric(vertical: 8),
            ),
            "p": Style(
              fontSize: FontSize(14),
              lineHeight: LineHeight(1.6),
              margin: Margins.symmetric(vertical: 4),
            ),
            "li": Style(
              fontSize: FontSize(13),
              lineHeight: LineHeight(1.6),
              margin: Margins.symmetric(vertical: 2),
            ),
            "strong": Style(fontWeight: FontWeight.bold),
            "em": Style(fontStyle: FontStyle.italic),
          },
          onLinkTap: (url, _, __) {
            if (url != null) {
              print('Link tapped: $url');
            }
          },
        ),
      );
    } else {
      // Render as Markdown (legacy support)
      return Markdown(
        data: content,
        selectable: true,
        padding: const EdgeInsets.all(16),
        styleSheet: MarkdownStyleSheet(
          h1: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          h3: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          p: const TextStyle(fontSize: 15, height: 1.6),
          listBullet: const TextStyle(fontSize: 15),
          strong: const TextStyle(fontWeight: FontWeight.bold),
          blockSpacing: 12,
        ),
      );
    }
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
              ? AppColors.primaryColor.withValues(alpha: 0.15)
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
            fontSize: 14,
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
              ? AppColors.primaryColor.withValues(alpha: 0.15)
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
                fontSize: 14,
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
          fontSize: 14,
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
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showDeleteDialog(
      BuildContext context, AiCvViewModel vm, AiCvModel cv) async {
    final confirmed = await CustomAlertDialog.showConfirmation(
      context: context,
      title: 'Supprimer ce CV ?',
      message: 'Voulez-vous supprimer "${cv.title}" ?',
      confirmText: 'Supprimer',
      isDangerous: true,
    );
    if (confirmed && cv.id != null && context.mounted) {
      final success = await vm.deleteCv(cv.id!);
      if (context.mounted) {
        if (success) {
          CustomToast.success(context, 'CV supprimé');
        } else {
          CustomToast.error(
              context, vm.error ?? 'Erreur lors de la suppression');
        }
      }
    }
  }

  void _showReformulateDialog(
      BuildContext context, AiCvViewModel vm, AiCvModel cv) async {
    final instructions = await CustomAlertDialog.showInput(
      context: context,
      title: 'Reformuler le CV',
      message: 'L\'IA va améliorer et reformuler votre CV. Vous pouvez ajouter des instructions spécifiques.',
      hintText: 'Instructions (optionnel)\nEx: "Ton plus formel", "Ajoute des mots-clés ATS"',
      confirmText: 'Reformuler',
    );
    if (instructions != null && cv.id != null) {
      vm.reformulateCv(
        cv.id!,
        instructions: instructions.isNotEmpty ? instructions : null,
      );
    }
  }

  Future<void> _downloadAsPdf(BuildContext context, AiCvModel cv) async {
    if (cv.id == null) {
      if (context.mounted) {
        CustomToast.error(context, 'ID du CV manquant');
      }
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Télécharger le CV',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.download, color: AppColors.primaryColor),
                ),
                title: const Text('Design par défaut',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Télécharger directement avec le template standard'),
                onTap: () {
                  Navigator.pop(ctx);
                  _quickDownload(context, cv);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.palette_outlined, color: Colors.orange),
                ),
                title: const Text('Personnaliser',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Choisir template, couleur et police avant téléchargement'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CvCustomizationScreen(
                        cvId: cv.id!,
                        cvTitle: cv.title,
                        cvType: 'ai',
                        currentFormat: cv.format,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _quickDownload(BuildContext context, AiCvModel cv) async {
    try {
      CustomToast.info(context, 'Génération du PDF en cours...', title: 'PDF');
      final repo = AiCvRepository();
      final pdfBytes = await repo.downloadPdf(
        cv.id!,
        primaryColor: '#1e3a8a',
        fontFamily: 'Arial',
        format: cv.format.isNotEmpty ? cv.format : 'standard',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      final filename =
          '${cv.title.replaceAll(RegExp(r'[^\w\s-]'), '').trim()}.pdf';
      await PdfDownloadService.shareOrSave(pdfBytes, filename);

      if (context.mounted) {
        CustomToast.success(context, 'PDF généré avec succès');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        CustomToast.error(context, '$e', title: 'Erreur PDF');
      }
    }
  }
}

