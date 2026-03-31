import 'package:flutter/material.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
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
    _photoUrl = cv?.personalInfo.photoUrl;

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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier le CV' : 'Nouveau CV'),
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
            TextButton(
              onPressed: _save,
              child: Text(
                'Sauvegarder',
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildMetadataSection(),
            const SizedBox(height: 20),
            _buildPersonalInfoSection(),
            const SizedBox(height: 20),
            _buildExperiencesSection(),
            const SizedBox(height: 20),
            _buildEducationsSection(),
            const SizedBox(height: 20),
            _buildSkillsSection(),
            const SizedBox(height: 20),
            _buildLanguagesSection(),
            const SizedBox(height: 20),
            _buildProjectsSection(),
            const SizedBox(height: 20),
            _buildCertificationsSection(),
            const SizedBox(height: 20),
            _buildStringListSection(
              title: 'Centres d\'intérêt',
              icon: Icons.interests_outlined,
              items: _interests,
              hint: 'Centre d\'intérêt',
              onAdd: () =>
                  setState(() => _interests.add(TextEditingController())),
              onRemove: (i) => setState(() {
                _interests[i].dispose();
                _interests.removeAt(i);
              }),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _isEditing ? 'Mettre à jour' : 'Créer le CV',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ---- Sections ----

  Widget _buildSectionHeader(String title, IconData icon,
      {VoidCallback? onAdd}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryColor),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600)),
        const Spacer(),
        if (onAdd != null)
          IconButton(
            icon: Icon(Icons.add_circle_outline,
                color: AppColors.primaryColor, size: 22),
            onPressed: onAdd,
          ),
      ],
    );
  }

  Widget _buildMetadataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Informations du CV', Icons.settings_outlined),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleCtrl,
          decoration: const InputDecoration(
            labelText: 'Titre du CV *',
            hintText: 'Ex: CV Développeur Web',
            border: OutlineInputBorder(),
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Titre requis' : null,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _format,
                decoration: const InputDecoration(
                  labelText: 'Format',
                  border: OutlineInputBorder(),
                ),
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
                initialValue: _language,
                decoration: const InputDecoration(
                  labelText: 'Langue',
                  border: OutlineInputBorder(),
                ),
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

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Informations personnelles', Icons.person_outline),
        const SizedBox(height: 8),
        TextFormField(
          controller: _fullNameCtrl,
          decoration: const InputDecoration(
            labelText: 'Nom complet *',
            border: OutlineInputBorder(),
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Nom requis' : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _proTitleCtrl,
          decoration: const InputDecoration(
            labelText: 'Titre professionnel',
            hintText: 'Ex: Développeur Full Stack',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _addressCtrl,
          decoration: const InputDecoration(
            labelText: 'Adresse',
            hintText: 'Ex: 12 rue de la Paix',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _cityCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ville',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _countryCtrl,
                decoration: const InputDecoration(
                  labelText: 'Pays',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _websiteCtrl,
          decoration: const InputDecoration(
            labelText: 'Site web',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _summaryCtrl,
          decoration: const InputDecoration(
            labelText: 'Résumé / Profil',
            hintText: 'Décrivez-vous en quelques lignes...',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildExperiencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Expériences', Icons.work_outline,
            onAdd: () =>
                setState(() => _experiences.add(_ExperienceEntry()))),
        ..._experiences.asMap().entries.map((entry) {
          final i = entry.key;
          final exp = entry.value;
          return _buildExperienceCard(i, exp);
        }),
      ],
    );
  }

  Widget _buildExperienceCard(int index, _ExperienceEntry exp) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Expérience ${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                  onPressed: () => setState(() {
                    _experiences[index].dispose();
                    _experiences.removeAt(index);
                  }),
                ),
              ],
            ),
            TextFormField(
              controller: exp.jobTitle,
              decoration: const InputDecoration(
                labelText: 'Poste *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: exp.company,
              decoration: const InputDecoration(
                labelText: 'Entreprise *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: exp.startDate,
                    decoration: const InputDecoration(
                      labelText: 'Début (AAAA-MM)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: exp.endDate,
                    decoration: const InputDecoration(
                      labelText: 'Fin (AAAA-MM)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
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
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Formation', Icons.school_outlined,
            onAdd: () => setState(() => _educations.add(_EducationEntry()))),
        ..._educations.asMap().entries.map((entry) {
          final i = entry.key;
          final edu = entry.value;
          return _buildEducationCard(i, edu);
        }),
      ],
    );
  }

  Widget _buildEducationCard(int index, _EducationEntry edu) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Formation ${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                  onPressed: () => setState(() {
                    _educations[index].dispose();
                    _educations.removeAt(index);
                  }),
                ),
              ],
            ),
            TextFormField(
              controller: edu.degree,
              decoration: const InputDecoration(
                labelText: 'Diplôme *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: edu.school,
              decoration: const InputDecoration(
                labelText: 'Établissement *',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: edu.startDate,
                    decoration: const InputDecoration(
                      labelText: 'Début (AAAA-MM)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: edu.endDate,
                    decoration: const InputDecoration(
                      labelText: 'Fin (AAAA-MM)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    enabled: !edu.currentValue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            CheckboxListTile(
              value: edu.currentValue,
              onChanged: (v) => setState(() => edu.currentValue = v ?? false),
              title:
                  const Text('En cours', style: TextStyle(fontSize: 13)),
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            TextFormField(
              controller: edu.description,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Compétences', Icons.star_outline,
            onAdd: () => setState(() => _skills.add(_SkillEntry()))),
        ..._skills.asMap().entries.map((entry) {
          final i = entry.key;
          final skill = entry.value;
          return Card(
            margin: const EdgeInsets.only(top: 8),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: skill.name,
                      decoration: const InputDecoration(
                        labelText: 'Compétence',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: skill.levelValue.isEmpty ? null : skill.levelValue,
                      decoration: const InputDecoration(
                        labelText: 'Niveau',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
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
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.red, size: 20),
                    onPressed: () => setState(() {
                      _skills[i].dispose();
                      _skills.removeAt(i);
                    }),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLanguagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Langues', Icons.translate,
            onAdd: () => setState(() => _languages.add(_LanguageEntry()))),
        ..._languages.asMap().entries.map((entry) {
          final i = entry.key;
          final lang = entry.value;
          return Card(
            margin: const EdgeInsets.only(top: 8),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: lang.name,
                      decoration: const InputDecoration(
                        labelText: 'Langue',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: lang.levelValue.isEmpty ? null : lang.levelValue,
                      decoration: const InputDecoration(
                        labelText: 'Niveau',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'A1', child: Text('A1')),
                        DropdownMenuItem(value: 'A2', child: Text('A2')),
                        DropdownMenuItem(value: 'B1', child: Text('B1')),
                        DropdownMenuItem(value: 'B2', child: Text('B2')),
                        DropdownMenuItem(value: 'C1', child: Text('C1')),
                        DropdownMenuItem(value: 'C2', child: Text('C2')),
                        DropdownMenuItem(
                            value: 'Natif', child: Text('Natif')),
                      ],
                      onChanged: (v) =>
                          setState(() => lang.levelValue = v ?? ''),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Colors.red, size: 20),
                    onPressed: () => setState(() {
                      _languages[i].dispose();
                      _languages.removeAt(i);
                    }),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildProjectsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Projets', Icons.folder_outlined,
            onAdd: () => setState(() => _projects.add(_ProjectEntry()))),
        ..._projects.asMap().entries.map((entry) {
          final i = entry.key;
          final proj = entry.value;
          return Card(
            margin: const EdgeInsets.only(top: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Projet ${i + 1}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red, size: 20),
                        onPressed: () => setState(() {
                          _projects[i].dispose();
                          _projects.removeAt(i);
                        }),
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: proj.name,
                    decoration: const InputDecoration(
                      labelText: 'Nom du projet *',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: proj.description,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: proj.link,
                    decoration: const InputDecoration(
                      labelText: 'Lien (URL)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: proj.startDate,
                          decoration: const InputDecoration(
                            labelText: 'Début (optionnel)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: proj.endDate,
                          decoration: const InputDecoration(
                            labelText: 'Fin (optionnel)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCertificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Certifications', Icons.verified_outlined,
            onAdd: () =>
                setState(() => _certifications.add(_CertificationEntry()))),
        ..._certifications.asMap().entries.map((entry) {
          final i = entry.key;
          final cert = entry.value;
          return Card(
            margin: const EdgeInsets.only(top: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Certification ${i + 1}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red, size: 20),
                        onPressed: () => setState(() {
                          _certifications[i].dispose();
                          _certifications.removeAt(i);
                        }),
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: cert.name,
                    decoration: const InputDecoration(
                      labelText: 'Nom *',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: cert.organization,
                    decoration: const InputDecoration(
                      labelText: 'Organisation',
                      hintText: 'Ex: Cisco, Google',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: cert.date,
                    decoration: const InputDecoration(
                      labelText: 'Date (AAAA-MM)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: cert.description,
                    decoration: const InputDecoration(
                      labelText: 'Description (optionnel)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStringListSection({
    required String title,
    required IconData icon,
    required List<TextEditingController> items,
    required String hint,
    required VoidCallback onAdd,
    required void Function(int) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(title, icon, onAdd: onAdd),
        ...items.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: entry.value,
                    decoration: InputDecoration(
                      hintText: hint,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      color: Colors.red, size: 20),
                  onPressed: () => onRemove(entry.key),
                ),
              ],
            ),
          );
        }),
      ],
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
