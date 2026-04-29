// Flutter imports:
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

// Project imports:
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/data/models/profile/experience_model.dart';
import 'package:cv_tech/data/models/profile/skill_reference_model.dart';
import 'package:cv_tech/presentation/views_models/profile/professional_profile_view_model.dart';
import 'package:cv_tech/theme/app_theme.dart';
import 'package:cv_tech/presentation/widgets/common/custom_toast.dart';

class ExperienceFormView extends StatefulWidget {
  final ExperienceModel? experience;
  final String? userId;

  const ExperienceFormView({super.key, this.experience, this.userId});

  @override
  State<ExperienceFormView> createState() => _ExperienceFormViewState();
}

class _ExperienceFormViewState extends State<ExperienceFormView> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _postController;
  late TextEditingController _entrepriseController;
  late TextEditingController _placeController;
  late TextEditingController _descriptionController;
  late TextEditingController _achievementController;
  late TextEditingController _skillSearchController;

  // State
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _currentPost = false;
  bool _isLoading = false;
  List<String> _keyAchievements = [];
  List<Map<String, dynamic>> _skills = [];
  List<Map<String, dynamic>> _certificates = [];
  Map<String, bool> _expandedSkills = {};

  ProfessionalProfileViewModel? _viewModel;

  // Skill categories matching Next.js
  final Map<String, List<String>> _skillsByCategory = {
    'Frontend': ['React', 'Vue.js', 'Angular', 'Next.js', 'TypeScript', 'JavaScript', 'HTML', 'CSS', 'Tailwind CSS', 'SASS'],
    'Backend': ['Node.js', 'Express', 'NestJS', 'Python', 'Django', 'FastAPI', 'Java', 'Spring Boot', 'PHP', 'Laravel'],
    'DevOps': ['Docker', 'Kubernetes', 'AWS', 'Azure', 'GCP', 'CI/CD', 'Jenkins', 'GitHub Actions', 'Terraform'],
    'Mobile': ['Flutter', 'React Native', 'Swift', 'Kotlin', 'iOS', 'Android'],
    'Database': ['PostgreSQL', 'MySQL', 'MongoDB', 'Redis', 'Firebase', 'Prisma'],
    'Other': ['Git', 'Agile', 'Scrum', 'REST API', 'GraphQL', 'Testing', 'UI/UX'],
  };

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadExistingData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewModel ??= context.read<ProfessionalProfileViewModel>();
  }

  void _initControllers() {
    _postController = TextEditingController();
    _entrepriseController = TextEditingController();
    _placeController = TextEditingController();
    _descriptionController = TextEditingController();
    _achievementController = TextEditingController();
    _skillSearchController = TextEditingController();
  }

  void _loadExistingData() {
    if (widget.experience != null) {
      _postController.text = widget.experience!.post;
      _entrepriseController.text = widget.experience!.entreprise;
      _placeController.text = widget.experience!.place;
      _descriptionController.text = widget.experience!.description;
      _startDate = widget.experience!.startDate;
      _endDate = widget.experience!.endDate;
      _currentPost = widget.experience!.currentPost;
      _keyAchievements = List.from(widget.experience!.keyAchievements);
      _skills = widget.experience!.skills.map((s) {
        return <String, dynamic>{
          'name': s.name,
          'category': s.category,
          '_id': s.id,
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
        };
      }).toList();
    }
  }

  @override
  void dispose() {
    _postController.dispose();
    _entrepriseController.dispose();
    _placeController.dispose();
    _descriptionController.dispose();
    _achievementController.dispose();
    _skillSearchController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : (_endDate ?? DateTime.now()),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Clear end date if it's before start date
          if (_endDate != null && _endDate!.isBefore(_startDate)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _addAchievement() {
    final text = _achievementController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _keyAchievements.add(text);
        _achievementController.clear();
      });
    }
  }

  void _removeAchievement(int index) {
    setState(() {
      _keyAchievements.removeAt(index);
    });
  }

  void _addSkill(String skillName, String category) {
    if (!_skills.any((s) => s['name'] == skillName)) {
      setState(() {
        _skills.add({'name': skillName, 'category': category, 'id': DateTime.now().millisecondsSinceEpoch.toString()});
      });
    }
  }

  void _removeSkill(String skillId) {
    setState(() {
      _skills.removeWhere((s) => s['id'] == skillId);
    });
  }

  Future<void> _pickCertificate() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result != null) {
        setState(() {
          _certificates.add({
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'name': result.files.single.name,
            'bytes': result.files.single.bytes,
            'file': kIsWeb ? null : File(result.files.single.path!),
            'type': result.files.single.extension,
          });
        });
      }
    } catch (e) {
      CustomToast.error(context, '$e', title: 'Erreur de sélection');
    }
  }

  void _removeCertificate(String id) {
    setState(() {
      _certificates.removeWhere((c) => c['id'] == id);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = _viewModel;
    if (viewModel == null) {
      CustomToast.error(context, 'Session expirée, veuillez réessayer.');
      return;
    }

    setState(() => _isLoading = true);

    final userId = widget.userId ?? '';

    final experience = ExperienceModel(
      id: widget.experience?.id,
      userId: userId,
      post: _postController.text.trim(),
      entreprise: _entrepriseController.text.trim(),
      place: _placeController.text.trim(),
      description: _descriptionController.text.trim(),
      startDate: _startDate,
      endDate: _currentPost ? null : _endDate,
      currentPost: _currentPost,
      keyAchievements: _keyAchievements,
      skills: _skills.map((s) => SkillReference(
        name: s['name'] as String,
        category: s['category'] as String? ?? 'Other',
        id: s['_id'] as String?,
      )).toList(),
    );

    // Préparer les fichiers de certificats
    final List<List<int>>? certFiles = _certificates.isNotEmpty
        ? _certificates
            .where((c) => c['bytes'] != null)
            .map((c) => (c['bytes'] as List<int>))
            .toList()
        : null;

    bool success;
    if (widget.experience == null) {
      success = await viewModel.addExperienceV2(experience, certFiles);
    } else {
      success = await viewModel.updateExperienceV2(
        widget.experience!.id!,
        experience,
        certFiles,
        null,
      );
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        CustomToast.success(
          context,
          widget.experience == null
              ? 'Expérience ajoutée avec succès'
              : 'Expérience modifiée avec succès',
        );
      } else {
        CustomToast.error(context, viewModel.experienceError ?? 'Une erreur est survenue');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.isLight ? Colors.grey.shade50 : Colors.grey.shade900,
      appBar: AppBar(
        title: Text(widget.experience == null
            ? 'Ajouter une expérience'
            : 'Modifier l\'expérience'),
        backgroundColor: AppTheme.isLight ? Colors.white : Colors.grey.shade800,
        elevation: 0,
        actions: [
          if (widget.experience == null)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stars, size: 16, color: AppColors.primaryColor),
                  SizedBox(width: 4),
                  Text(
                    '+15',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPostField(),
                  const SizedBox(height: 24),
                  _buildCompanyField(),
                  const SizedBox(height: 24),
                  _buildLocationField(),
                  const SizedBox(height: 24),
                  _buildDateFields(),
                  const SizedBox(height: 24),
                  _buildDescriptionField(),
                  const SizedBox(height: 24),
                  _buildAchievementsSection(),
                  const SizedBox(height: 24),
                  _buildSkillsSection(),
                  const SizedBox(height: 24),
                  _buildCertificatesSection(),
                  const SizedBox(height: 32),
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    bool required = false,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: Colors.black87,
            ),
            children: required
                ? [const TextSpan(text: ' *', style: TextStyle(color: Colors.red))]
                : [],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines > 1 ? 16 : 12,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPostField() {
    return _buildTextFormField(
      controller: _postController,
      label: 'Poste',
      hintText: 'Ex: Développeur Full Stack Senior',
      required: true,
      validator: (value) => value?.isEmpty == true ? 'Le poste est requis' : null,
    );
  }

  Widget _buildCompanyField() {
    return _buildTextFormField(
      controller: _entrepriseController,
      label: 'Entreprise',
      hintText: 'Ex: Google, Apple, Microsoft...',
      required: true,
      validator: (value) => value?.isEmpty == true ? 'L\'entreprise est requise' : null,
    );
  }

  Widget _buildLocationField() {
    return _buildTextFormField(
      controller: _placeController,
      label: 'Lieu',
      hintText: 'Ex: Paris, France',
      required: true,
      validator: (value) => value?.isEmpty == true ? 'Le lieu est requis' : null,
    );
  }

  Widget _buildDateFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Période',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(
                      text: 'Date de début',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                      children: [
                        TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _selectDate(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${_startDate.month.toString().padLeft(2, '0')}/${_startDate.year}',
                              style: const TextStyle(fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date de fin',
                    style: TextStyle(
                      fontSize: 14,
                      color: _currentPost ? Colors.grey.shade400 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _currentPost ? null : () => _selectDate(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _currentPost ? Colors.grey.shade200 : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: _currentPost ? Colors.grey.shade50 : null,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _currentPost
                                  ? 'En cours'
                                  : _endDate != null
                                      ? '${_endDate!.month.toString().padLeft(2, '0')}/${_endDate!.year}'
                                      : 'Sélectionner',
                              style: TextStyle(
                                fontSize: 16,
                                color: _currentPost ? Colors.grey.shade400 : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: _currentPost ? Colors.grey.shade300 : Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          value: _currentPost,
          onChanged: (value) {
            setState(() {
              _currentPost = value ?? false;
              if (_currentPost) _endDate = null;
            });
          },
          title: const Text('Poste actuel'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppColors.primaryColor,
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Décrivez vos responsabilités et réalisations...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Réalisations clés',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _achievementController,
                decoration: InputDecoration(
                  hintText: 'Ajouter une réalisation...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => _addAchievement(),
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filled(
              onPressed: _addAchievement,
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_keyAchievements.isNotEmpty)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _keyAchievements.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 18, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_keyAchievements[index])),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                      onPressed: () => _removeAchievement(index),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            },
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Text(
              'Aucune réalisation ajoutée',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Compétences utilisées',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        // Selected skills chips
        if (_skills.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _skills.map((skill) {
              return Chip(
                label: Text(skill['name']),
                onDeleted: () => _removeSkill(skill['id']),
                deleteIcon: const Icon(Icons.close, size: 16),
                backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
                labelStyle: const TextStyle(color: AppColors.primaryColor),
              );
            }).toList(),
          ),
        const SizedBox(height: 16),
        // Skills by category
        ..._skillsByCategory.entries.map((category) {
          final isExpanded = _expandedSkills[category.key] ?? false;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              title: Row(
                children: [
                  _getCategoryIcon(category.key),
                  const SizedBox(width: 8),
                  Text(category.key),
                ],
              ),
              initiallyExpanded: isExpanded,
              onExpansionChanged: (expanded) {
                setState(() => _expandedSkills[category.key] = expanded);
              },
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: category.value.map((skill) {
                      final isSelected = _skills.any((s) => s['name'] == skill);
                      return FilterChip(
                        label: Text(skill),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            _addSkill(skill, category.key);
                          } else {
                            final skillToRemove = _skills.firstWhere(
                              (s) => s['name'] == skill,
                              orElse: () => {},
                            );
                            if (skillToRemove.isNotEmpty) {
                              _removeSkill(skillToRemove['id']);
                            }
                          }
                        },
                        selectedColor: AppColors.primaryColor.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.primaryColor,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _getCategoryIcon(String category) {
    switch (category) {
      case 'Frontend':
        return const Icon(Icons.code, size: 20, color: Colors.blue);
      case 'Backend':
        return const Icon(Icons.dns, size: 20, color: Colors.green);
      case 'DevOps':
        return const Icon(Icons.cloud, size: 20, color: Colors.purple);
      case 'Mobile':
        return const Icon(Icons.smartphone, size: 20, color: Colors.orange);
      case 'Database':
        return const Icon(Icons.storage, size: 20, color: Colors.indigo);
      default:
        return const Icon(Icons.category, size: 20, color: Colors.grey);
    }
  }

  Widget _buildCertificatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Certificats et attestations',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickCertificate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.grey),
                const SizedBox(height: 8),
                Text(
                  'Cliquer pour ajouter un certificat',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  'PDF, JPG, PNG (max 5MB)',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_certificates.isNotEmpty)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _certificates.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final cert = _certificates[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.description, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cert['name'],
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            cert['type'].toString().toUpperCase(),
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.visibility, color: Colors.blue),
                      onPressed: () {
                        // TODO: Preview certificate
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeCertificate(cert['id']),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: const Text(
              'Annuler',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    widget.experience == null ? 'Ajouter l\'expérience' : 'Sauvegarder',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }
}