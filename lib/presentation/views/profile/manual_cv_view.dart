import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/core/services/pdf_download_service.dart';
import 'package:cv_tech/data/models/profile/manual_cv_model.dart';
import 'package:cv_tech/data/repositories/manual_cv_repository.dart';
import 'package:cv_tech/presentation/views_models/profile/manual_cv_view_model.dart';
import 'package:cv_tech/presentation/widgets/common/custom_toast.dart';
import 'package:cv_tech/presentation/widgets/common/custom_alert_dialog.dart';
import 'package:cv_tech/presentation/views/profile/manual_cv_form_view.dart';
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

class _ManualCvContent extends StatefulWidget {
  const _ManualCvContent();

  @override
  State<_ManualCvContent> createState() => _ManualCvContentState();
}

class _ManualCvContentState extends State<_ManualCvContent> {
  String _searchQuery = '';

  List<ManualCvModel> _filtered(List<ManualCvModel> cvs) {
    if (_searchQuery.isEmpty) return cvs;
    final q = _searchQuery.toLowerCase();
    return cvs
        .where((cv) =>
            cv.title.toLowerCase().contains(q) ||
            cv.personalInfo.fullName.toLowerCase().contains(q) ||
            cv.format.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? null : const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          'Mes CVs',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      body: Consumer<ManualCvViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading && vm.cvs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final shown = _filtered(vm.cvs);

          return RefreshIndicator(
            onRefresh: vm.loadCvs,
            child: CustomScrollView(
              slivers: [
                // --- Header with Create button ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: _buildCreateButton(context),
                  ),
                ),

                // --- Search bar ---
                if (vm.cvs.length > 1)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          hintText: 'Rechercher un CV...',
                          hintStyle: TextStyle(fontSize: 15, color: Colors.grey.shade500),
                          prefixIcon: Icon(Icons.search, size: 20, color: Colors.grey.shade400),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: () => setState(() => _searchQuery = ''),
                                  child: Icon(Icons.close, size: 18, color: Colors.grey.shade400),
                                )
                              : null,
                          filled: true,
                          fillColor: isDark ? Colors.grey.shade900 : Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ),

                // --- CV count ---
                if (vm.cvs.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                      child: Text(
                        '${shown.length} CV${shown.length > 1 ? 's' : ''}${_searchQuery.isNotEmpty ? ' trouvÃ©${shown.length > 1 ? 's' : ''}' : ''}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),

                // --- CVs or Empty state ---
                if (shown.isEmpty && _searchQuery.isNotEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'Aucun rÃ©sultat pour "$_searchQuery"',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (vm.cvs.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(context),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _buildCvCard(context, vm, shown[index]),
                        childCount: shown.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCreateButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'CrÃ©er un CV',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        onPressed: () => _navigateToForm(context),
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.description_outlined,
                  size: 48, color: AppColors.primaryColor),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aucun CV pour le moment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Commencez par crÃ©er votre premier CV\npour mettre en valeur votre profil.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCvCard(
      BuildContext context, ManualCvViewModel vm, ManualCvModel cv) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          // --- Header row ---
          InkWell(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(14)),
            onTap: () => _navigateToForm(context, cv: cv),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(Icons.description_outlined,
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
                            fontSize: 15,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      cv.format.toUpperCase(),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- Info chips ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildChip(cv.language.toUpperCase(), Icons.language),
                _buildChip(
                    '${cv.experiences.length} exp.', Icons.work_outline),
                _buildChip(
                    '${cv.educations.length} form.', Icons.school_outlined),
                _buildChip('${cv.skills.length} comp.', Icons.star_outline),
              ],
            ),
          ),

          if (cv.updatedAt != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Row(
                children: [
                  Icon(Icons.access_time,
                      size: 12, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    'ModifiÃ© le ${_formatDate(cv.updatedAt!)}',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),

          // --- Action buttons bar ---
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
            child: Row(
              children: [
                _buildActionBtn(
                  icon: Icons.edit_outlined,
                  label: 'Modifier',
                  onTap: () => _navigateToForm(context, cv: cv),
                ),
                _buildActionBtn(
                  icon: Icons.picture_as_pdf_outlined,
                  label: 'PDF',
                  onTap: () => _downloadPdf(context, vm, cv),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: Colors.red.shade400, size: 20),
                  tooltip: 'Supprimer',
                  onPressed: () => _deleteCv(context, vm, cv),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return TextButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 14)),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onTap,
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 15,
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w500),
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
    ).then((_) {
      if (context.mounted) vm.loadCvs();
    });
  }

  Future<void> _deleteCv(
      BuildContext context, ManualCvViewModel vm, ManualCvModel cv) async {
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
          CustomToast.success(context, 'CV supprimÃ©');
        } else {
          CustomToast.error(
              context, vm.error ?? 'Erreur lors de la suppression');
        }
      }
    }
  }

  void _downloadPdf(
      BuildContext context, ManualCvViewModel vm, ManualCvModel cv) {
    if (cv.id == null) {
      CustomToast.error(context, 'ID du CV manquant');
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
                'TÃ©lÃ©charger le CV',
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
                title: const Text('Design par dÃ©faut',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text(
                    'TÃ©lÃ©charger directement avec le template standard'),
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
                  child: const Icon(Icons.palette_outlined,
                      color: Colors.orange),
                ),
                title: const Text('Personnaliser',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text(
                    'Choisir template, couleur et police avant tÃ©lÃ©chargement'),
                onTap: () {
                  Navigator.pop(ctx);
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
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _quickDownload(BuildContext context, ManualCvModel cv) async {
    try {
      CustomToast.info(context, 'GÃ©nÃ©ration du PDF en cours...', title: 'PDF');
      final repo = ManualCvRepository();
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
        CustomToast.success(context, 'PDF gÃ©nÃ©rÃ© avec succÃ¨s');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        CustomToast.error(context, '$e', title: 'Erreur PDF');
      }
    }
  }
}


