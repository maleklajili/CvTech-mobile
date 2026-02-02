// Flutter imports:
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

// Project imports:
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/data/models/profile/education_model.dart';
import 'package:cv_tech/data/models/profile/skill_reference_model.dart';
import 'package:cv_tech/presentation/views_models/profile/professional_profile_view_model.dart';
import 'package:cv_tech/presentation/views_models/profile/profile_view_model.dart';
import 'package:cv_tech/theme/app_theme.dart';

class EducationFormView extends StatefulWidget {
  final EducationModel? education;

  const EducationFormView({super.key, this.education});

  @override
  State<EducationFormView> createState() => _EducationFormViewState();
}

class _EducationFormViewState extends State<EducationFormView> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _degreeController;
  late TextEditingController _schoolController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  late TextEditingController _gradeController;
  late TextEditingController _skillSearchController;

  // State
  EducationType _selectedType = EducationType.diploma;
  EducationLevel? _selectedLevel;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _currentlyStudying = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _skills = [];
  List<Map<String, dynamic>> _certificates = [];
  Map<String, bool> _expandedSkills = {};

  // Education types matching Next.js
  final List<Map<String, dynamic>> _educationTypes = [
    {'value': EducationType.diploma, 'label': 'Diplôme', 'icon': Icons.school},
    {'value': EducationType.certification, 'label': 'Certification', 'icon': Icons.verified},
    {'value': EducationType.course, 'label': 'Formation', 'icon': Icons.book},
  ];

  // Education levels - matching EducationLevel enum
  final List<Map<String, dynamic>> _educationLevels = [
    {'value': EducationLevel.beginner, 'label': 'Débutant'},
    {'value': EducationLevel.intermediate, 'label': 'Intermédiaire'},
    {'value': EducationLevel.advanced, 'label': 'Avancé'},
    {'value': EducationLevel.expert, 'label': 'Expert'},
  ];

  // Skills by category
  final Map<String, List<String>> _skillsByCategory = {
    'Programmation': ['Python', 'Java', 'C++', 'JavaScript', 'TypeScript', 'Go', 'Rust', 'PHP'],
    'Web': ['HTML', 'CSS', 'React', 'Vue.js', 'Angular', 'Node.js', 'Django', 'Laravel'],
    'Data Science': ['Machine Learning', 'Deep Learning', 'TensorFlow', 'PyTorch', 'Pandas', 'NumPy'],
    'Design': ['Figma', 'Adobe XD', 'Photoshop', 'Illustrator', 'UI/UX'],
    'Gestion': ['Gestion de projet', 'Agile', 'Scrum', 'Leadership', 'Communication'],
    'Langues': ['Anglais', 'Français', 'Espagnol', 'Allemand', 'Arabe', 'Chinois'],
  };

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadExistingData();
  }

  void _initControllers() {
    _degreeController = TextEditingController();
    _schoolController = TextEditingController();
    _locationController = TextEditingController();
    _descriptionController = TextEditingController();
    _gradeController = TextEditingController();
    _skillSearchController = TextEditingController();
  }

  void _loadExistingData() {
    if (widget.education != null) {
      _degreeController.text = widget.education!.degree;
      _schoolController.text = widget.education!.school;
      _locationController.text = widget.education!.location;
      _descriptionController.text = widget.education!.description;
      _gradeController.text = widget.education!.grade ?? '';
      _selectedType = widget.education!.type;
      _selectedLevel = widget.education!.level;
      _startDate = widget.education!.startDate;
      _endDate = widget.education!.endDate;
      _currentlyStudying = widget.education!.current;
      _skills = widget.education!.skills.map((s) => {'name': s, 'id': DateTime.now().millisecondsSinceEpoch.toString()}).toList();
    }
  }

  @override
  void dispose() {
    _degreeController.dispose();
    _schoolController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _gradeController.dispose();
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
            colorScheme: const ColorScheme.light(
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
          if (_endDate != null && _endDate!.isBefore(_startDate)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _addSkill(String skillName) {
    if (!_skills.any((s) => s['name'] == skillName)) {
      setState(() {
        _skills.add({'name': skillName, 'id': DateTime.now().millisecondsSinceEpoch.toString()});
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sélection: $e')),
      );
    }
  }

  void _removeCertificate(String id) {
    setState(() {
      _certificates.removeWhere((c) => c['id'] == id);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final viewModel = context.read<ProfessionalProfileViewModel>();
    final profileViewModel = context.read<ProfileViewModel>();
    final userId = profileViewModel.user?.id ?? '';

    final education = EducationModel(
      id: widget.education?.id,
      userId: userId,
      degree: _degreeController.text.trim(),
      school: _schoolController.text.trim(),
      location: _locationController.text.trim(),
      description: _descriptionController.text.trim(),
      type: _selectedType,
      level: _selectedLevel,
      startDate: _startDate,
      endDate: _currentlyStudying ? null : _endDate,
      current: _currentlyStudying,
      grade: _gradeController.text.trim().isEmpty ? null : _gradeController.text.trim(),
      skills: _skills.map((s) => SkillReference(
        name: s['name'] as String,
        category: s['category'] as String? ?? 'Other',
        id: s['_id'] as String?,
      )).toList(),
    );

    bool success;
    if (widget.education == null) {
      success = await viewModel.addEducation(education);
    } else {
      success = await viewModel.updateEducation(widget.education!.id!, education);
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.education == null
                  ? 'Formation ajoutée avec succès'
                  : 'Formation modifiée avec succès',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.educationError ?? 'Une erreur est survenue'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.isLight ? Colors.grey.shade50 : Colors.grey.shade900,
      appBar: AppBar(
        title: Text(widget.education == null
            ? 'Ajouter une formation'
            : 'Modifier la formation'),
        backgroundColor: AppTheme.isLight ? Colors.white : Colors.grey.shade800,
        elevation: 0,
        actions: [
          if (widget.education == null)
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
                  _buildTypeSelector(),
                  const SizedBox(height: 24),
                  _buildDegreeField(),
                  const SizedBox(height: 24),
                  _buildSchoolField(),
                  const SizedBox(height: 24),
                  _buildLocationField(),
                  const SizedBox(height: 24),
                  if (_selectedType == EducationType.diploma) ...[
                    _buildLevelField(),
                    const SizedBox(height: 24),
                  ],
                  _buildDateFields(),
                  const SizedBox(height: 24),
                  _buildGradeField(),
                  const SizedBox(height: 24),
                  _buildDescriptionField(),
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

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: 'Type de formation',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black87),
            children: [
              TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: _educationTypes.map((type) {
            final isSelected = _selectedType == type['value'];
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedType = type['value']),
                child: Container(
                  margin: EdgeInsets.only(right: type != _educationTypes.last ? 12 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryColor.withValues(alpha: 0.1) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryColor : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        type['icon'],
                        color: isSelected ? AppColors.primaryColor : Colors.grey.shade600,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        type['label'],
                        style: TextStyle(
                          color: isSelected ? AppColors.primaryColor : Colors.grey.shade600,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
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

  Widget _buildDegreeField() {
    String label;
    String hint;
    switch (_selectedType) {
      case EducationType.diploma:
        label = 'Diplôme';
        hint = 'Ex: Master en Informatique';
        break;
      case EducationType.certification:
        label = 'Certification';
        hint = 'Ex: AWS Solutions Architect';
        break;
      case EducationType.course:
        label = 'Formation';
        hint = 'Ex: Formation React Avancé';
        break;
    }

    return _buildTextFormField(
      controller: _degreeController,
      label: label,
      hintText: hint,
      required: true,
      validator: (value) => value?.isEmpty == true ? 'Ce champ est requis' : null,
    );
  }

  Widget _buildSchoolField() {
    return _buildTextFormField(
      controller: _schoolController,
      label: 'École / Organisme',
      hintText: 'Ex: Université Paris-Saclay, Coursera...',
      required: true,
      validator: (value) => value?.isEmpty == true ? 'Ce champ est requis' : null,
    );
  }

  Widget _buildLocationField() {
    return _buildTextFormField(
      controller: _locationController,
      label: 'Lieu',
      hintText: 'Ex: Paris, France',
    );
  }

  Widget _buildLevelField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Niveau',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: DropdownButtonFormField<EducationLevel>(
            value: _selectedLevel,
            decoration: InputDecoration(
              hintText: 'Sélectionner un niveau',
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
            items: _educationLevels.map((level) {
              return DropdownMenuItem<EducationLevel>(
                value: level['value'],
                child: Text(level['label']),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedLevel = value),
          ),
        ),
      ],
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_startDate.month.toString().padLeft(2, '0')}/${_startDate.year}',
                            style: const TextStyle(fontSize: 16),
                          ),
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
                      color: _currentlyStudying ? Colors.grey.shade400 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _currentlyStudying ? null : () => _selectDate(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _currentlyStudying ? Colors.grey.shade200 : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: _currentlyStudying ? Colors.grey.shade50 : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _currentlyStudying
                                ? 'En cours'
                                : _endDate != null
                                    ? '${_endDate!.month.toString().padLeft(2, '0')}/${_endDate!.year}'
                                    : 'Sélectionner',
                            style: TextStyle(
                              fontSize: 16,
                              color: _currentlyStudying ? Colors.grey.shade400 : Colors.black87,
                            ),
                          ),
                          Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: _currentlyStudying ? Colors.grey.shade300 : Colors.grey,
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
          value: _currentlyStudying,
          onChanged: (value) {
            setState(() {
              _currentlyStudying = value ?? false;
              if (_currentlyStudying) _endDate = null;
            });
          },
          title: const Text('En cours'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppColors.primaryColor,
        ),
      ],
    );
  }

  Widget _buildGradeField() {
    return _buildTextFormField(
      controller: _gradeController,
      label: 'Mention / Note',
      hintText: 'Ex: Mention Très Bien, 16/20...',
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
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Décrivez votre formation, les matières étudiées...',
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

  Widget _buildSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Compétences acquises',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 12),
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
        ..._skillsByCategory.entries.map((category) {
          final isExpanded = _expandedSkills[category.key] ?? false;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ExpansionTile(
              title: Text(category.key),
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
                            _addSkill(skill);
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

  Widget _buildCertificatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Diplômes et certificats',
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
                  'Cliquer pour ajouter un diplôme',
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
                      onPressed: () {},
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
                    widget.education == null ? 'Ajouter la formation' : 'Sauvegarder',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }
}