import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/core/utils/image_url_helper.dart';
import 'package:cv_tech/data/models/profile/manual_cv_model.dart';
import 'package:cv_tech/presentation/views_models/profile/manual_cv_view_model.dart';
import 'package:cv_tech/presentation/widgets/common/custom_toast.dart';

class ManualCvFormView extends StatefulWidget {
  final ManualCvModel? existingCv;
  final ManualCvViewModel viewModel;

  const ManualCvFormView({
    super.key,
    this.existingCv,
    required this.viewModel,
  });

  @override
  State<ManualCvFormView> createState() => _ManualCvFormViewState();
}

class _ManualCvFormViewState extends State<ManualCvFormView> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  late bool _isEditing;

  // CV metadata
  late final TextEditingController _titleCtrl;
  String _format = 'standard';
  String _language = 'fr';

  // Personal info
  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _proTitleCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _countryCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _summaryCtrl;
  String? _photoUrl;
  File? _pickedPhoto;

  // Dynamic lists
  List<_ExperienceEntry> _experiences = [];
  List<_EducationEntry> _educations = [];
  List<_SkillEntry> _skills = [];
  List<_LanguageEntry> _languages = [];
  List<_ProjectEntry> _projects = [];
  List<_CertificationEntry> _certifications = [];
  List<TextEditingController> _interests = [];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.existingCv != null;
    final cv = widget.existingCv;

    _titleCtrl = TextEditingController(text: cv?.title ?? 'Mon CV');
    _format = cv?.format ?? 'standard';
    _language = cv?.language ?? 'fr';

    _fullNameCtrl =
        TextEditingController(text: cv?.personalInfo.fullName ?? '');
    _proTitleCtrl =
        TextEditingController(text: cv?.personalInfo.professionalTitle ?? '');
    _emailCtrl = TextEditingController(text: cv?.personalInfo.email ?? '');
    _phoneCtrl = TextEditingController(text: cv?.personalInfo.phone ?? '');
    _addressCtrl = TextEditingController(text: cv?.personalInfo.address ?? '');
    _cityCtrl = TextEditingController(text: cv?.personalInfo.city ?? '');
    _countryCtrl = TextEditingController(text: cv?.personalInfo.country ?? '');
    _websiteCtrl = TextEditingController(text: cv?.personalInfo.website ?? '');
    _summaryCtrl = TextEditingController(text: cv?.personalInfo.summary ?? '');
    _photoUrl = cv != null
        ? ImageUrlHelper.getImageUrlSync(cv.personalInfo.photoUrl, cv.userId)
        : null;

    if (cv != null) {
      _experiences = cv.experiences
          .map((e) => _ExperienceEntry.fromModel(e))
          .toList();
      _educations =
          cv.educations.map((e) => _EducationEntry.fromModel(e)).toList();
      _skills = cv.skills.map((e) => _SkillEntry.fromModel(e)).toList();
      _languages =
          cv.languages.map((e) => _LanguageEntry.fromModel(e)).toList();
      _projects = cv.projects.map((e) => _ProjectEntry.fromModel(e)).toList();
      _certifications =
          cv.certifications.map((e) => _CertificationEntry.fromModel(e)).toList();
      _interests =
          cv.interests.map((e) => TextEditingController(text: e)).toList();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _fullNameCtrl.dispose();
    _proTitleCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    _websiteCtrl.dispose();
    _summaryCtrl.dispose();
    for (final e in _experiences) {
      e.dispose();
    }
    for (final e in _educations) {
      e.dispose();
    }
    for (final e in _skills) {
      e.dispose();
    }
    for (final e in _languages) {
      e.dispose();
    }
    for (final c in _projects) {
      c.dispose();
    }
    for (final c in _certifications) {
      c.dispose();
    }
    for (final c in _interests) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _pickedPhoto = File(picked.path);
        _photoUrl = picked.path;
      });
    }
  }

  Map<String, dynamic> _buildPayload() {
    return {
      'title': _titleCtrl.text.trim(),
      'format': _format,
      'language': _language,
      'personalInfo': {
        'fullName': _fullNameCtrl.text.trim(),
        if (_proTitleCtrl.text.trim().isNotEmpty)
          'professionalTitle': _proTitleCtrl.text.trim(),
        if (_emailCtrl.text.trim().isNotEmpty) 'email': _emailCtrl.text.trim(),
        if (_phoneCtrl.text.trim().isNotEmpty) 'phone': _phoneCtrl.text.trim(),
        if (_addressCtrl.text.trim().isNotEmpty)
          'address': _addressCtrl.text.trim(),
        if (_cityCtrl.text.trim().isNotEmpty) 'city': _cityCtrl.text.trim(),
        if (_countryCtrl.text.trim().isNotEmpty)
          'country': _countryCtrl.text.trim(),
        if (_websiteCtrl.text.trim().isNotEmpty)
          'website': _websiteCtrl.text.trim(),
        if (_summaryCtrl.text.trim().isNotEmpty)
          'summary': _summaryCtrl.text.trim(),
        if (_photoUrl != null && _photoUrl!.isNotEmpty)
          'photoUrl': _photoUrl,
      },
      'experiences': _experiences.map((e) => e.toJson()).toList(),
      'educations': _educations.map((e) => e.toJson()).toList(),
      'skills': _skills.map((e) => e.toJson()).toList(),
      'languages': _languages.map((e) => e.toJson()).toList(),
      'projects': _projects.map((e) => e.toJson()).toList(),
      'certifications': _certifications.map((e) => e.toJson()).toList(),
      'interests': _interests
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
    };
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final data = _buildPayload();
    bool success;

    if (_isEditing && widget.existingCv?.id != null) {
      success = await widget.viewModel.updateCv(widget.existingCv!.id!, data);
    } else {
      success = await widget.viewModel.createCv(data);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      CustomToast.success(
          context, _isEditing ? 'CV mis à jour' : 'CV créé avec succès');
      Navigator.pop(context);
    } else {
      CustomToast.error(
          context, widget.viewModel.error ?? 'Erreur lors de la sauvegarde');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? null : const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Modifier le CV' : 'Nouveau CV',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Sauvegarder'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryColor,
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                onPressed: _save,
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            _buildSectionCard(
              title: 'Informations du CV',
              icon: Icons.settings_outlined,
              child: _buildMetadataFields(),
            ),
            // --- Photo import for European CV ---
            if (_format == 'european') ...[
              const SizedBox(height: 12),
              _buildSectionCard(
                title: 'Photo de profil',
                icon: Icons.camera_alt_outlined,
                child: _buildPhotoSection(),
              ),
            ],
            const SizedBox(height: 12),
            _buildSectionCard(
              title: 'Informations personnelles',
              icon: Icons.person_outline,
              child: _buildPersonalInfoFields(),
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              title: 'Expériences',
              icon: Icons.work_outline,
              onAdd: () =>
                  setState(() => _experiences.add(_ExperienceEntry())),
              child: _buildExperiencesList(),
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              title: 'Formation',
              icon: Icons.school_outlined,
              onAdd: () =>
                  setState(() => _educations.add(_EducationEntry())),
              child: _buildEducationsList(),
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              title: 'Compétences',
              icon: Icons.star_outline,
              onAdd: () => setState(() => _skills.add(_SkillEntry())),
              child: _buildSkillsList(),
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              title: 'Langues',
              icon: Icons.translate,
              onAdd: () =>
                  setState(() => _languages.add(_LanguageEntry())),
              child: _buildLanguagesList(),
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              title: 'Projets',
              icon: Icons.folder_outlined,
              onAdd: () =>
                  setState(() => _projects.add(_ProjectEntry())),
              child: _buildProjectsList(),
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              title: 'Certifications',
              icon: Icons.verified_outlined,
              onAdd: () =>
                  setState(() => _certifications.add(_CertificationEntry())),
              child: _buildCertificationsList(),
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              title: 'Centres d\'intérêt',
              icon: Icons.interests_outlined,
              onAdd: () =>
                  setState(() => _interests.add(TextEditingController())),
              child: _buildInterestsList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(
                    _isEditing ? Icons.save_rounded : Icons.add_rounded,
                    size: 20),
                label: Text(
                  _isEditing ? 'Mettre à jour' : 'Créer le CV',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _isSaving ? null : _save,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ---- Reusable section card ----

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    VoidCallback? onAdd,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.primaryColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
                if (onAdd != null)
                  IconButton(
                    icon: Icon(Icons.add_circle_outline,
                        color: AppColors.primaryColor, size: 22),
                    onPressed: onAdd,
                    tooltip: 'Ajouter',
                  ),
              ],
            ),
          ),
          Divider(
              height: 1,
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          // Section content
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: child,
          ),
        ],
      ),
    );
  }

  // ---- Styled input decoration ----

  InputDecoration _inputDeco(String label, {String? hint, IconData? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 18, color: Colors.grey.shade500)
          : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5),
      ),
      filled: true,
      fillColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey.shade800
          : Colors.grey.shade50,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Widget _buildMetadataFields() {
    return Column(
      children: [
        TextFormField(
          controller: _titleCtrl,
          decoration: _inputDeco('Titre du CV *',
              hint: 'Ex: CV Développeur Web', prefixIcon: Icons.title),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Titre requis' : null,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _format,
                decoration: _inputDeco('Format', prefixIcon: Icons.style),
                items: const [
                  DropdownMenuItem(value: 'standard', child: Text('Standard')),
                  DropdownMenuItem(value: 'canadian', child: Text('Canadien')),
                  DropdownMenuItem(value: 'modern', child: Text('Moderne')),
                  DropdownMenuItem(value: 'european', child: Text('Européen')),
                ],
                onChanged: (v) => setState(() => _format = v ?? 'standard'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _language,
                decoration: _inputDeco('Langue', prefixIcon: Icons.language),
                items: const [
                  DropdownMenuItem(value: 'fr', child: Text('Français')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'ar', child: Text('العربية')),
                ],
                onChanged: (v) => setState(() => _language = v ?? 'fr'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickPhoto,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryColor.withValues(alpha: 0.08),
                border: Border.all(
                  color: AppColors.primaryColor.withValues(alpha: 0.3),
                  width: 2,
                ),
                image: _pickedPhoto != null
                    ? DecorationImage(
                        image: FileImage(_pickedPhoto!),
                        fit: BoxFit.cover,
                      )
                    : (_photoUrl != null && _photoUrl!.isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(_photoUrl!),
                            fit: BoxFit.cover,
                            onError: (_, __) {},
                          )
                        : null,
              ),
              child: (_pickedPhoto == null &&
                      (_photoUrl == null || _photoUrl!.isEmpty))
                  ? Icon(Icons.person_add_alt_1_rounded,
                      size: 36, color: AppColors.primaryColor)
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            icon: const Icon(Icons.photo_camera_outlined, size: 16),
            label: Text(
              _pickedPhoto != null || (_photoUrl != null && _photoUrl!.isNotEmpty)
                  ? 'Changer la photo'
                  : 'Ajouter une photo',
              style: const TextStyle(fontSize: 13),
            ),
            style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryColor),
            onPressed: _pickPhoto,
          ),
          Text(
            'Recommandé pour le format Européen',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoFields() {
    return Column(
      children: [
        TextFormField(
          controller: _fullNameCtrl,
          decoration: _inputDeco('Nom complet *', prefixIcon: Icons.person),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Nom requis' : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _proTitleCtrl,
          decoration: _inputDeco('Titre professionnel',
              hint: 'Ex: Développeur Full Stack', prefixIcon: Icons.badge),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _emailCtrl,
                decoration: _inputDeco('Email', prefixIcon: Icons.email_outlined),
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _phoneCtrl,
                decoration: _inputDeco('Téléphone', prefixIcon: Icons.phone_outlined),
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _addressCtrl,
          decoration: _inputDeco('Adresse',
              hint: 'Ex: 12 rue de la Paix', prefixIcon: Icons.location_on_outlined),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _cityCtrl,
                decoration: _inputDeco('Ville', prefixIcon: Icons.location_city),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _countryCtrl,
                decoration: _inputDeco('Pays', prefixIcon: Icons.flag_outlined),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _websiteCtrl,
          decoration: _inputDeco('Site web', prefixIcon: Icons.link),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _summaryCtrl,
          decoration: _inputDeco('Résumé / Profil',
              hint: 'Décrivez-vous en quelques lignes...'),
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildExperiencesList() {
    if (_experiences.isEmpty) {
      return _buildEmptyHint('Aucune expérience ajoutée');
    }
    return Column(
      children: _experiences.asMap().entries.map((entry) {
        final i = entry.key;
        final exp = entry.value;
        return _buildExperienceCard(i, exp);
      }).toList(),
    );
  }

  Widget _buildExperienceCard(int index, _ExperienceEntry exp) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade800
            : Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Expérience ${index + 1}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: Colors.red.shade400, size: 20),
                onPressed: () => setState(() {
                  _experiences[index].dispose();
                  _experiences.removeAt(index);
                }),
              ),
            ],
          ),
          TextFormField(
            controller: exp.jobTitle,
            decoration: _inputDeco('Poste *'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Requis' : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: exp.company,
            decoration: _inputDeco('Entreprise *'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Requis' : null,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: exp.startDate,
                  decoration: _inputDeco('Début (AAAA-MM)'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: exp.endDate,
                  decoration: _inputDeco('Fin (AAAA-MM)'),
                  enabled: !exp.currentValue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          CheckboxListTile(
            value: exp.currentValue,
            onChanged: (v) => setState(() => exp.currentValue = v ?? false),
            title: const Text('Poste actuel', style: TextStyle(fontSize: 13)),
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
          TextFormField(
            controller: exp.description,
            decoration: _inputDeco('Description'),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildEducationsList() {
    if (_educations.isEmpty) {
      return _buildEmptyHint('Aucune formation ajoutée');
    }
    return Column(
      children: _educations.asMap().entries.map((entry) {
        final i = entry.key;
        final edu = entry.value;
        return _buildEducationCard(i, edu);
      }).toList(),
    );
  }

  Widget _buildEducationCard(int index, _EducationEntry edu) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade800
            : Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Formation ${index + 1}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: Colors.red.shade400, size: 20),
                onPressed: () => setState(() {
                  _educations[index].dispose();
                  _educations.removeAt(index);
                }),
              ),
            ],
          ),
          TextFormField(
            controller: edu.degree,
            decoration: _inputDeco('Diplôme *'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Requis' : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: edu.school,
            decoration: _inputDeco('Établissement *'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Requis' : null,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: edu.startDate,
                  decoration: _inputDeco('Début (AAAA-MM)'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: edu.endDate,
                  decoration: _inputDeco('Fin (AAAA-MM)'),
                  enabled: !edu.currentValue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          CheckboxListTile(
            value: edu.currentValue,
            onChanged: (v) => setState(() => edu.currentValue = v ?? false),
            title: const Text('En cours', style: TextStyle(fontSize: 13)),
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
          TextFormField(
            controller: edu.description,
            decoration: _inputDeco('Description'),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsList() {
    if (_skills.isEmpty) {
      return _buildEmptyHint('Aucune compétence ajoutée');
    }
    return Column(
      children: _skills.asMap().entries.map((entry) {
        final i = entry.key;
        final skill = entry.value;
        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade800
                : Colors.grey.shade50,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: skill.name,
                  decoration: _inputDeco('Compétence'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: skill.levelValue.isEmpty ? null : skill.levelValue,
                  decoration: _inputDeco('Niveau'),
                  items: const [
                    DropdownMenuItem(
                        value: 'Débutant', child: Text('Débutant')),
                    DropdownMenuItem(
                        value: 'Intermédiaire',
                        child: Text('Intermédiaire')),
                    DropdownMenuItem(
                        value: 'Avancé', child: Text('Avancé')),
                    DropdownMenuItem(
                        value: 'Expert', child: Text('Expert')),
                  ],
                  onChanged: (v) =>
                      setState(() => skill.levelValue = v ?? ''),
                ),
              ),
              IconButton(
                icon: Icon(Icons.remove_circle_outline,
                    color: Colors.red.shade400, size: 20),
                onPressed: () => setState(() {
                  _skills[i].dispose();
                  _skills.removeAt(i);
                }),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLanguagesList() {
    if (_languages.isEmpty) {
      return _buildEmptyHint('Aucune langue ajoutée');
    }
    return Column(
      children: _languages.asMap().entries.map((entry) {
        final i = entry.key;
        final lang = entry.value;
        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade800
                : Colors.grey.shade50,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: lang.name,
                  decoration: _inputDeco('Langue'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: lang.levelValue.isEmpty ? null : lang.levelValue,
                  decoration: _inputDeco('Niveau'),
                  items: const [
                    DropdownMenuItem(value: 'A1', child: Text('A1')),
                    DropdownMenuItem(value: 'A2', child: Text('A2')),
                    DropdownMenuItem(value: 'B1', child: Text('B1')),
                    DropdownMenuItem(value: 'B2', child: Text('B2')),
                    DropdownMenuItem(value: 'C1', child: Text('C1')),
                    DropdownMenuItem(value: 'C2', child: Text('C2')),
                    DropdownMenuItem(value: 'Natif', child: Text('Natif')),
                  ],
                  onChanged: (v) =>
                      setState(() => lang.levelValue = v ?? ''),
                ),
              ),
              IconButton(
                icon: Icon(Icons.remove_circle_outline,
                    color: Colors.red.shade400, size: 20),
                onPressed: () => setState(() {
                  _languages[i].dispose();
                  _languages.removeAt(i);
                }),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProjectsList() {
    if (_projects.isEmpty) {
      return _buildEmptyHint('Aucun projet ajouté');
    }
    return Column(
      children: _projects.asMap().entries.map((entry) {
        final i = entry.key;
        final proj = entry.value;
        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade800
                : Colors.grey.shade50,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Projet ${i + 1}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: Colors.red.shade400, size: 20),
                    onPressed: () => setState(() {
                      _projects[i].dispose();
                      _projects.removeAt(i);
                    }),
                  ),
                ],
              ),
              TextFormField(
                controller: proj.name,
                decoration: _inputDeco('Nom du projet *'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: proj.description,
                decoration: _inputDeco('Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: proj.link,
                decoration: _inputDeco('Lien (URL)', prefixIcon: Icons.link),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: proj.startDate,
                      decoration: _inputDeco('Début (optionnel)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: proj.endDate,
                      decoration: _inputDeco('Fin (optionnel)'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCertificationsList() {
    if (_certifications.isEmpty) {
      return _buildEmptyHint('Aucune certification ajoutée');
    }
    return Column(
      children: _certifications.asMap().entries.map((entry) {
        final i = entry.key;
        final cert = entry.value;
        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade800
                : Colors.grey.shade50,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Certification ${i + 1}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: Colors.red.shade400, size: 20),
                    onPressed: () => setState(() {
                      _certifications[i].dispose();
                      _certifications.removeAt(i);
                    }),
                  ),
                ],
              ),
              TextFormField(
                controller: cert.name,
                decoration: _inputDeco('Nom *'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: cert.organization,
                decoration: _inputDeco('Organisation',
                    hint: 'Ex: Cisco, Google'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: cert.date,
                decoration: _inputDeco('Date (AAAA-MM)'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: cert.description,
                decoration: _inputDeco('Description (optionnel)'),
                maxLines: 2,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInterestsList() {
    if (_interests.isEmpty) {
      return _buildEmptyHint('Aucun centre d\'intérêt ajouté');
    }
    return Column(
      children: _interests.asMap().entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: entry.value,
                  decoration: _inputDeco('Centre d\'intérêt'),
                ),
              ),
              IconButton(
                icon: Icon(Icons.remove_circle_outline,
                    color: Colors.red.shade400, size: 20),
                onPressed: () => setState(() {
                  _interests[entry.key].dispose();
                  _interests.removeAt(entry.key);
                }),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyHint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
      ),
    );
  }
}

// ---- Helper classes for managing form entries ----

class _ExperienceEntry {
  final TextEditingController jobTitle;
  final TextEditingController company;
  final TextEditingController startDate;
  final TextEditingController endDate;
  bool currentValue;
  final TextEditingController description;

  _ExperienceEntry({
    String? jobTitleText,
    String? companyText,
    String? startDateText,
    String? endDateText,
    this.currentValue = false,
    String? descriptionText,
  })  : jobTitle = TextEditingController(text: jobTitleText ?? ''),
        company = TextEditingController(text: companyText ?? ''),
        startDate = TextEditingController(text: startDateText ?? ''),
        endDate = TextEditingController(text: endDateText ?? ''),
        description = TextEditingController(text: descriptionText ?? '');

  factory _ExperienceEntry.fromModel(ManualCvExperience model) {
    return _ExperienceEntry(
      jobTitleText: model.jobTitle,
      companyText: model.company,
      startDateText: model.startDate,
      endDateText: model.endDate,
      currentValue: model.current,
      descriptionText: model.description,
    );
  }

  Map<String, dynamic> toJson() => {
        'jobTitle': jobTitle.text.trim(),
        'company': company.text.trim(),
        'startDate': startDate.text.trim(),
        if (endDate.text.trim().isNotEmpty) 'endDate': endDate.text.trim(),
        'current': currentValue,
        if (description.text.trim().isNotEmpty)
          'description': description.text.trim(),
      };

  void dispose() {
    jobTitle.dispose();
    company.dispose();
    startDate.dispose();
    endDate.dispose();
    description.dispose();
  }
}

class _EducationEntry {
  final TextEditingController degree;
  final TextEditingController school;
  final TextEditingController startDate;
  final TextEditingController endDate;
  bool currentValue;
  final TextEditingController description;

  _EducationEntry({
    String? degreeText,
    String? schoolText,
    String? startDateText,
    String? endDateText,
    this.currentValue = false,
    String? descriptionText,
  })  : degree = TextEditingController(text: degreeText ?? ''),
        school = TextEditingController(text: schoolText ?? ''),
        startDate = TextEditingController(text: startDateText ?? ''),
        endDate = TextEditingController(text: endDateText ?? ''),
        description = TextEditingController(text: descriptionText ?? '');

  factory _EducationEntry.fromModel(ManualCvEducation model) {
    return _EducationEntry(
      degreeText: model.degree,
      schoolText: model.school,
      startDateText: model.startDate,
      endDateText: model.endDate,
      currentValue: model.current,
      descriptionText: model.description,
    );
  }

  Map<String, dynamic> toJson() => {
        'degree': degree.text.trim(),
        'school': school.text.trim(),
        'startDate': startDate.text.trim(),
        if (endDate.text.trim().isNotEmpty) 'endDate': endDate.text.trim(),
        'current': currentValue,
        if (description.text.trim().isNotEmpty)
          'description': description.text.trim(),
      };

  void dispose() {
    degree.dispose();
    school.dispose();
    startDate.dispose();
    endDate.dispose();
    description.dispose();
  }
}

class _SkillEntry {
  final TextEditingController name;
  String levelValue;

  _SkillEntry({String? nameText, this.levelValue = ''})
      : name = TextEditingController(text: nameText ?? '');

  factory _SkillEntry.fromModel(ManualCvSkill model) {
    return _SkillEntry(nameText: model.name, levelValue: model.level ?? '');
  }

  Map<String, dynamic> toJson() => {
        'name': name.text.trim(),
        if (levelValue.isNotEmpty) 'level': levelValue,
      };

  void dispose() {
    name.dispose();
  }
}

class _LanguageEntry {
  final TextEditingController name;
  String levelValue;

  _LanguageEntry({String? nameText, this.levelValue = ''})
      : name = TextEditingController(text: nameText ?? '');

  factory _LanguageEntry.fromModel(ManualCvLanguage model) {
    return _LanguageEntry(nameText: model.name, levelValue: model.level ?? '');
  }

  Map<String, dynamic> toJson() => {
        'name': name.text.trim(),
        if (levelValue.isNotEmpty) 'level': levelValue,
      };

  void dispose() {
    name.dispose();
  }
}

class _ProjectEntry {
  final TextEditingController name;
  final TextEditingController description;
  final TextEditingController link;
  final TextEditingController startDate;
  final TextEditingController endDate;

  _ProjectEntry({
    String? nameText,
    String? descriptionText,
    String? linkText,
    String? startDateText,
    String? endDateText,
  })  : name = TextEditingController(text: nameText ?? ''),
        description = TextEditingController(text: descriptionText ?? ''),
        link = TextEditingController(text: linkText ?? ''),
        startDate = TextEditingController(text: startDateText ?? ''),
        endDate = TextEditingController(text: endDateText ?? '');

  factory _ProjectEntry.fromModel(ManualCvProject model) {
    return _ProjectEntry(
      nameText: model.name,
      descriptionText: model.description,
      linkText: model.link,
      startDateText: model.startDate,
      endDateText: model.endDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name.text.trim(),
        if (description.text.trim().isNotEmpty)
          'description': description.text.trim(),
        if (link.text.trim().isNotEmpty) 'link': link.text.trim(),
        if (startDate.text.trim().isNotEmpty)
          'startDate': startDate.text.trim(),
        if (endDate.text.trim().isNotEmpty) 'endDate': endDate.text.trim(),
      };

  void dispose() {
    name.dispose();
    description.dispose();
    link.dispose();
    startDate.dispose();
    endDate.dispose();
  }
}

class _CertificationEntry {
  final TextEditingController name;
  final TextEditingController organization;
  final TextEditingController date;
  final TextEditingController description;

  _CertificationEntry({
    String? nameText,
    String? organizationText,
    String? dateText,
    String? descriptionText,
  })  : name = TextEditingController(text: nameText ?? ''),
        organization = TextEditingController(text: organizationText ?? ''),
        date = TextEditingController(text: dateText ?? ''),
        description = TextEditingController(text: descriptionText ?? '');

  factory _CertificationEntry.fromModel(ManualCvCertification model) {
    return _CertificationEntry(
      nameText: model.name,
      organizationText: model.organization,
      dateText: model.date,
      descriptionText: model.description,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name.text.trim(),
        if (organization.text.trim().isNotEmpty)
          'organization': organization.text.trim(),
        if (date.text.trim().isNotEmpty) 'date': date.text.trim(),
        if (description.text.trim().isNotEmpty)
          'description': description.text.trim(),
      };

  void dispose() {
    name.dispose();
    organization.dispose();
    date.dispose();
    description.dispose();
  }
}
