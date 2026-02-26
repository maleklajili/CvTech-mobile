// Flutter imports:
import 'package:flutter/material.dart';
import 'dart:typed_data';

// Package imports:
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

// Project imports:
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/core/constants/project_constants.dart';
import 'package:cv_tech/data/models/profile/project_model.dart';
import 'package:cv_tech/presentation/views_models/profile/professional_profile_view_model.dart';
import 'package:cv_tech/theme/app_theme.dart';

class ProjectFormView extends StatefulWidget {
  final ProjectModel? project;

  const ProjectFormView({super.key, this.project});

  @override
  State<ProjectFormView> createState() => _ProjectFormViewState();
}

class _ProjectFormViewState extends State<ProjectFormView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _liveUrlController;
  late TextEditingController _githubUrlController;
  late TextEditingController _techSearchController;

  String? _selectedCategory;
  String? _selectedProjectType;
  String _selectedColor = '#64748b';
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _current = false;
  bool _featured = false;
  bool _isLoading = false;
  Uint8List? _selectedImageBytes;
  List<String> _technologies = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.project?.title);
    _descriptionController =
        TextEditingController(text: widget.project?.description);
    _liveUrlController = TextEditingController(text: widget.project?.liveUrl);
    _githubUrlController =
        TextEditingController(text: widget.project?.githubUrl);
    _techSearchController = TextEditingController();

    if (widget.project != null) {
      _selectedCategory = widget.project!.category;
      _selectedProjectType = widget.project!.projectType;
      _selectedColor = widget.project!.color ?? '#64748b';
      _startDate = widget.project!.startDate;
      _endDate = widget.project!.endDate;
      _current = widget.project!.current;
      _featured = widget.project!.featured ?? false;
      _technologies = List.from(widget.project!.technologies);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _liveUrlController.dispose();
    _githubUrlController.dispose();
    _techSearchController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : (_endDate ?? DateTime.now()),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
      });
    }
  }

  void _addTechnology(String tech) {
    if (!_technologies.contains(tech) && tech.trim().isNotEmpty) {
      setState(() {
        _technologies.add(tech.trim());
      });
    }
  }

  void _removeTechnology(String tech) {
    setState(() {
      _technologies.remove(tech);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation des dropdowns
    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une catégorie'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedProjectType == null || _selectedProjectType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un type de projet'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_technologies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter au moins une technologie'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final viewModel = context.read<ProfessionalProfileViewModel>();

    final project = ProjectModel(
      id: widget.project?.id,
      userId: widget.project?.userId ?? '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory!,
      projectType: _selectedProjectType!,
      color: _selectedColor,
      startDate: _startDate,
      endDate: _current ? null : _endDate,
      current: _current,
      featured: _featured,
      technologies: _technologies,
      liveUrl: _liveUrlController.text.trim().isEmpty
          ? null
          : _liveUrlController.text.trim(),
      githubUrl: _githubUrlController.text.trim().isEmpty
          ? null
          : _githubUrlController.text.trim(),
    );

    bool success;
    if (widget.project == null) {
      success = await viewModel.addProject(project);
    } else {
      success = await viewModel.updateProject(widget.project!.id!, project);
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.project == null
                  ? 'Projet ajouté avec succès'
                  : 'Projet modifié avec succès',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.projectsError ?? 'Une erreur est survenue'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceFirst('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.isLight ? Colors.grey.shade50 : Colors.grey.shade900,
      appBar: AppBar(
        title: Text(widget.project == null
            ? 'Ajouter un projet'
            : 'Modifier le projet'),
        backgroundColor: AppTheme.isLight ? Colors.white : Colors.grey.shade800,
        elevation: 0,
        actions: [
          if (widget.project == null)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.stars, size: 16, color: AppColors.primaryColor),
                  SizedBox(width: 4),
                  Text(
                    '+10',
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
                  _buildTitleField(),
                  const SizedBox(height: 24),
                  _buildProjectTypeField(),
                  const SizedBox(height: 24),
                  _buildCategoryField(),
                  const SizedBox(height: 24),
                  _buildDescriptionField(),
                  const SizedBox(height: 24),
                  _buildDateFields(),
                  const SizedBox(height: 24),
                  _buildTechnologiesField(),
                  const SizedBox(height: 24),
                  _buildUrlFields(),
                  const SizedBox(height: 24),
                  _buildColorPicker(),
                  const SizedBox(height: 24),
                  _buildImageSection(),
                  const SizedBox(height: 24),
                  _buildOptionsSection(),
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

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: 'Titre du projet',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black87),
            children: [
              TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'Ex: Plateforme de gestion de projets',
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
          validator: (value) =>
              value?.isEmpty ?? true ? 'Le titre est requis' : null,
        ),
      ],
    );
  }

  Widget _buildProjectTypeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: 'Type de projet',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black87),
            children: [
              TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedProjectType,
          decoration: InputDecoration(
            hintText: 'Sélectionner un type de projet',
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
          items: ProjectConstants.projectTypes.entries.expand((group) {
            return [
              DropdownMenuItem<String>(
                enabled: false,
                value: null,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    group.key,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              ...group.value.map((type) => DropdownMenuItem<String>(
                    value: type,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(type),
                    ),
                  )),
            ];
          }).toList(),
          onChanged: (value) => setState(() => _selectedProjectType = value),
          validator: (value) => value == null ? 'Le type de projet est requis' : null,
        ),
      ],
    );
  }

  Widget _buildCategoryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: 'Catégorie',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black87),
            children: [
              TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: InputDecoration(
            hintText: 'Sélectionner une catégorie',
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
          items: ProjectConstants.projectCategories.entries.expand((group) {
            return [
              DropdownMenuItem<String>(
                enabled: false,
                value: null,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    group.key,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              ...group.value.map((cat) => DropdownMenuItem<String>(
                    value: cat['value'],
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(cat['label']!),
                    ),
                  )),
            ];
          }).toList(),
          onChanged: (value) => setState(() => _selectedCategory = value),
          validator: (value) => value == null ? 'La catégorie est requise' : null,
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: 'Description',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black87),
            children: [
              TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Décrivez votre projet en détail...',
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
          validator: (value) =>
              value?.isEmpty ?? true ? 'La description est requise' : null,
        ),
      ],
    );
  }

  Widget _buildDateFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Période du projet',
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
                      color: _current ? Colors.grey.shade400 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _current ? null : () => _selectDate(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _current ? Colors.grey.shade200 : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: _current ? Colors.grey.shade50 : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _current
                                ? 'En cours'
                                : _endDate != null
                                    ? '${_endDate!.month.toString().padLeft(2, '0')}/${_endDate!.year}'
                                    : 'Sélectionner',
                            style: TextStyle(
                              fontSize: 16,
                              color: _current ? Colors.grey.shade400 : Colors.black87,
                            ),
                          ),
                          Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: _current ? Colors.grey.shade300 : Colors.grey,
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
          value: _current,
          onChanged: (value) {
            setState(() {
              _current = value ?? false;
              if (_current) _endDate = null;
            });
          },
          title: const Text('Projet en cours'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppColors.primaryColor,
        ),
      ],
    );
  }

  Widget _buildTechnologiesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: 'Technologies utilisées',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black87),
            children: [
              TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _techSearchController,
          decoration: InputDecoration(
            hintText: 'Ajouter une technologie...',
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
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                if (_techSearchController.text.trim().isNotEmpty) {
                  _addTechnology(_techSearchController.text.trim());
                  _techSearchController.clear();
                }
              },
            ),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              _addTechnology(value.trim());
              _techSearchController.clear();
            }
          },
        ),
        const SizedBox(height: 12),
        if (_technologies.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _technologies.map((tech) => Chip(
              label: Text(tech),
              onDeleted: () => _removeTechnology(tech),
              deleteIcon: const Icon(Icons.close, size: 18),
              backgroundColor: AppColors.primaryColor.withValues(alpha: 0.1),
              labelStyle: TextStyle(color: AppColors.primaryColor),
            )).toList(),
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
              'Aucune technologie ajoutée',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildUrlFields() {
    return Column(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'URL de démonstration',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _liveUrlController,
              decoration: InputDecoration(
                hintText: 'https://mon-projet.com',
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
                prefixIcon: const Icon(Icons.link),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lien GitHub',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _githubUrlController,
              decoration: InputDecoration(
                hintText: 'https://github.com/username/projet',
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
                prefixIcon: const Icon(Icons.code),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildColorPicker() {
    final colorOptions = [
      '#3b82f6', '#10b981', '#8b5cf6', '#f59e0b', '#ec4899', '#6366f1',
      '#64748b', '#ef4444', '#14b8a6', '#f97316', '#06b6d4',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Couleur du projet',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colorOptions.map((color) {
            final isSelected = _selectedColor == color;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = color),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _parseColor(color),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.grey.shade300,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Image du projet',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: _selectedImageBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _selectedImageBytes!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 48,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cliquer pour ajouter une image',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Options',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          value: _featured,
          onChanged: (value) => setState(() => _featured = value ?? false),
          title: const Text('Projet en vedette'),
          subtitle: const Text('Afficher ce projet en priorité sur votre profil'),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppColors.primaryColor,
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
                    widget.project == null ? 'Ajouter le projet' : 'Sauvegarder',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }
}