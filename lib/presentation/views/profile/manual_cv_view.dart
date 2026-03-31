import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/data/models/profile/manual_cv_model.dart';
import 'package:cv_tech/presentation/views_models/profile/manual_cv_view_model.dart';
import 'package:cv_tech/presentation/widgets/common/custom_toast.dart';
import 'package:cv_tech/presentation/widgets/common/custom_alert_dialog.dart';
import 'package:cv_tech/presentation/views/profile/manual_cv_form_view.dart';
import 'package:cv_tech/presentation/views/profile/cv_preview_screen.dart';

import 'package:cv_tech/presentation/views/profile/cv_customization_screen.dart';

class ManualCvView extends StatelessWidget {
  const ManualCvView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ManualCvViewModel()..loadCvs(),
      child: const _ManualCvContent(),
    );
  }
}

class _ManualCvContent extends StatelessWidget {
  const _ManualCvContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes CVs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ManualCvViewModel>().loadCvs(),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'import',
            backgroundColor: AppColors.secondaryColor,
            onPressed: () => _importFromProfile(context),
            child: const Icon(Icons.download_rounded, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'create',
            backgroundColor: AppColors.primaryColor,
            onPressed: () => _navigateToForm(context),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
      body: Consumer<ManualCvViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading && vm.cvs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.cvs.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: vm.loadCvs,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vm.cvs.length,
              itemBuilder: (context, index) =>
                  _buildCvCard(context, vm, vm.cvs[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Aucun CV manuel',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Créez votre CV manuellement ou importez les données de votre profil.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Importer profil'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryColor,
                    side: BorderSide(color: AppColors.primaryColor),
                  ),
                  onPressed: () => _importFromProfile(context),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Créer un CV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _navigateToForm(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCvCard(
      BuildContext context, ManualCvViewModel vm, ManualCvModel cv) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToForm(context, cv: cv),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.description,
                        color: AppColors.primaryColor, size: 22),
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cv.personalInfo.fullName.isNotEmpty
                              ? cv.personalInfo.fullName
                              : 'Sans nom',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (action) =>
                        _handleAction(context, vm, cv, action),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'preview',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, size: 18),
                            SizedBox(width: 8),
                            Text('Aperçu'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'pdf',
                        child: Row(
                          children: [
                            Icon(Icons.picture_as_pdf, size: 18),
                            SizedBox(width: 8),
                            Text('Télécharger PDF'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Supprimer',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildChip(cv.format.toUpperCase(), Icons.style),
                  _buildChip(cv.language.toUpperCase(), Icons.language),
                  _buildChip('${cv.experiences.length} exp.', Icons.work_outline),
                  _buildChip('${cv.educations.length} form.', Icons.school_outlined),
                  _buildChip('${cv.skills.length} comp.', Icons.star_outline),
                ],
              ),
              if (cv.updatedAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Modifié le ${_formatDate(cv.updatedAt!)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: AppColors.primaryColor),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _navigateToForm(BuildContext context, {ManualCvModel? cv}) {
    final vm = context.read<ManualCvViewModel>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManualCvFormView(existingCv: cv, viewModel: vm),
      ),
    );
  }

  void _importFromProfile(BuildContext context) async {
    final vm = context.read<ManualCvViewModel>();
    if (vm.isSaving) return;

    final confirmed = await CustomAlertDialog.showConfirmation(
      context: context,
      title: 'Importer le profil',
      message:
          'Les informations de votre profil (expériences, formations, compétences) seront importées dans un nouveau CV.',
      confirmText: 'Importer',
    );

    if (!confirmed || !context.mounted) return;

    final success = await vm.importFromProfile();
    if (!context.mounted) return;

    if (success) {
      CustomToast.success(context, 'Profil importé avec succès');
    } else {
      CustomToast.error(context, vm.error ?? 'Erreur lors de l\'import');
    }
  }

  void _handleAction(BuildContext context, ManualCvViewModel vm,
      ManualCvModel cv, String action) async {
    switch (action) {
      case 'preview':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CvPreviewScreen(cv: cv),
          ),
        );
        break;
      case 'edit':
        _navigateToForm(context, cv: cv);
        break;
      case 'pdf':
        _downloadPdf(context, vm, cv);
        break;
      case 'delete':
        final confirmed = await CustomAlertDialog.showConfirmation(
          context: context,
          title: 'Supprimer le CV',
          message: 'Voulez-vous vraiment supprimer "${cv.title}" ?',
          confirmText: 'Supprimer',
          isDangerous: true,
        );
        if (confirmed && context.mounted) {
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
        break;
    }
  }

  void _downloadPdf(
      BuildContext context, ManualCvViewModel vm, ManualCvModel cv) {
    if (cv.id == null) {
      CustomToast.error(context, 'ID du CV manquant');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CvCustomizationScreen(
          cvId: cv.id!,
          cvTitle: cv.title,
          cvType: 'manual',
          currentFormat: cv.format,
        ),
      ),
    );
  }
}
