// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

// Project imports:
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/core/constants/skill_categories.dart';
import 'package:cv_tech/data/models/profile/experience_model.dart';
import 'package:cv_tech/data/models/profile/skill_reference_model.dart';
import 'package:cv_tech/data/models/profile/certificate_reference_model.dart';
import 'package:cv_tech/presentation/views_models/profile/professional_profile_view_model.dart';
import 'package:cv_tech/presentation/views_models/profile/profile_view_model.dart';
import 'package:cv_tech/theme/app_theme.dart';

class ExperienceFormViewV2 extends StatefulWidget {
  final ExperienceModel? experience;

  const ExperienceFormViewV2({super.key, this.experience});

  @override
  State<ExperienceFormViewV2> createState() => _ExperienceFormViewV2State();
}

class _ExperienceFormViewV2State extends State<ExperienceFormViewV2> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _postController;
  late TextEditingController _entrepriseController;
  late TextEditingController _placeController;
  late TextEditingController _descriptionController;
  late TextEditingController _achievementController;

  // State
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _currentPost = false;
  bool _isLoading = false;
  List<String> _keyAchievements = [];
  List<SkillReference> _skills = [];
  List<CertificateReference> _certificates = [];
  List<String> _certificatesToDelete = [];

  // Skill selection
  String? _selectedCategory;
  // String _skillSearchQuery = ''; // Supprimé car non utilisé
  final TextEditingController _skillSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadExistingData();
  }

  void _initControllers() {
    _postController = TextEditingController();
    _entrepriseController = TextEditingController();
    _placeController = TextEditingController();
    _descriptionController = TextEditingController();
    _achievementController = TextEditingController();
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
      _skills = List.from(widget.experience!.skills);
      _certificates = List.from(widget.experience!.certificates);
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
    if (!_skills.any((s) => s.name == skillName)) {
      setState(() {
        _skills.add(SkillReference(
          name: skillName,
          category: category,
        ));
      });
    }
  }

  void _removeSkill(SkillReference skill) {
    setState(() {
      _skills.remove(skill);
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
          _certificates.add(CertificateReference.forUpload(
            name: result.files.single.name,
            type: result.files.single.extension ?? 'pdf',
            bytes: result.files.single.bytes!,
          ));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection: $e')),
        );
      }
    }
  }

  void _removeCertificate(CertificateReference cert) {
    setState(() {
      if (cert.isUploaded) {
        _certificatesToDelete.add(cert.id);
      }
      _certificates.remove(cert);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_currentPost && _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une date de fin ou cocher "Poste actuel"'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final viewModel = context.read<ProfessionalProfileViewModel>();
    final profileViewModel = context.read<ProfileViewModel>();
    final userId = profileViewModel.user?.id ?? '';

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
      skills: _skills,
      certificates: _certificates,
    );

    // Extract certificate bytes for upload
    final certificateFiles = _certificates
        .where((c) => c.bytes != null)
        .map((c) => c.bytes!)
        .toList();

    bool success;
    if (widget.experience == null) {
      success = await viewModel.addExperienceV2(experience, certificateFiles);
    } else {
      success = await viewModel.updateExperienceV2(
        widget.experience!.id!,
        experience,
        certificateFiles,
        _certificatesToDelete,
      );
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.experience == null
                  ? 'Expérience ajoutée avec succès'
                  : 'Expérience modifiée avec succès',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.experienceError ?? 'Une erreur est survenue'),
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
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  _buildPostField(),
                  const SizedBox(height: 24),
                  _buildCompanyField(),
                  const SizedBox(height: 24),
                  _buildPlaceField(),
                  const SizedBox(height: 24),
                  _buildDateSection(),
                  const SizedBox(height: 24),
                  _buildDescriptionField(),
                  const SizedBox(height: 32),
                  _buildSkillsSection(),
                  const SizedBox(height: 32),
                  _buildCertificatesSection(),
                  const SizedBox(height: 32),
                  _buildAchievementsSection(),
                  const SizedBox(height: 32),
                  _buildActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostField() {
    return TextFormField(
      controller: _postController,
      decoration: InputDecoration(
        labelText: 'Titre du poste *',
        hintText: 'Ex: Développeur Full Stack',
        prefixIcon: const Icon(Icons.work_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Veuillez entrer le titre du poste';
        }
        return null;
      },
    );
  }

  Widget _buildCompanyField() {
    return TextFormField(
      controller: _entrepriseController,
      decoration: InputDecoration(
        labelText: 'Entreprise *',
        hintText: 'Ex: Google',
        prefixIcon: const Icon(Icons.business),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Veuillez entrer le nom de l\'entreprise';
        }
        return null;
      },
    );
  }

  Widget _buildPlaceField() {
    return TextFormField(
      controller: _placeController,
      decoration: InputDecoration(
        labelText: 'Lieu *',
        hintText: 'Ex: Paris, France',
        prefixIcon: const Icon(Icons.location_on),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Veuillez entrer le lieu';
        }
        return null;
      },
    );
  }

  Widget _buildDateSection() {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(context, true),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date de début *',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(dateFormat.format(_startDate)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: _currentPost ? null : () => _selectDate(context, false),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date de fin',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabled: !_currentPost,
                  ),
                  child: Text(
                    _currentPost
                        ? 'Présent'
                        : (_endDate != null ? dateFormat.format(_endDate!) : 'Non définie'),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          title: const Text('Je travaille actuellement dans ce poste'),
          value: _currentPost,
          onChanged: (value) {
            setState(() {
              _currentPost = value ?? false;
              if (_currentPost) {
                _endDate = null;
              }
            });
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: 'Description',
        hintText: 'Décrivez vos responsabilités et réalisations...',
        prefixIcon: const Icon(Icons.description),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        alignLabelWithHint: true,
      ),
      maxLines: 5,
      textAlignVertical: TextAlignVertical.top,
    );
  }

  Widget _buildSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Compétences utilisées',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        // Skill search/add
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: SkillCategories.categories.map((category) {
                  return DropdownMenuItem(value: category, child: Text(category));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            if (_selectedCategory != null)
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Compétence',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: SkillCategories.getSkillsForCategory(_selectedCategory!)
                      .map((skill) {
                    return DropdownMenuItem(value: skill, child: Text(skill));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null && _selectedCategory != null) {
                      _addSkill(value, _selectedCategory!);
                    }
                  },
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Selected skills
        if (_skills.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _skills.map((skill) {
              return Chip(
                label: Text(skill.name),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => _removeSkill(skill),
                backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                labelStyle: const TextStyle(color: AppColors.primaryColor),
              );
            }).toList(),
          )
        else
          const Text(
            'Aucune compétence ajoutée',
            style: TextStyle(color: Colors.grey),
          ),
      ],
    );
  }

  Widget _buildCertificatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Certificats/Attestations',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: _pickCertificate,
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text('Ajouter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (_certificates.isNotEmpty)
          Column(
            children: _certificates.map((cert) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    cert.type == 'pdf' ? Icons.picture_as_pdf : Icons.image,
                    color: AppColors.primaryColor,
                  ),
                  title: Text(cert.name),
                  subtitle: cert.isLocal
                      ? const Text('Nouveau fichier')
                      : const Text('Déjà uploadé'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeCertificate(cert),
                  ),
                ),
              );
            }).toList(),
          )
        else
          const Text(
            'Aucun certificat ajouté',
            style: TextStyle(color: Colors.grey),
          ),
      ],
    );
  }

  Widget _buildAchievementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Réalisations clés (optionnel)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _achievementController,
                decoration: InputDecoration(
                  hintText: 'Ajoutez une réalisation...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onFieldSubmitted: (_) => _addAchievement(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _addAchievement,
              icon: const Icon(Icons.add_circle),
              color: AppColors.primaryColor,
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        if (_keyAchievements.isNotEmpty)
          Column(
            children: _keyAchievements.asMap().entries.map((entry) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(entry.value),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeAchievement(entry.key),
                  ),
                ),
              );
            }).toList(),
          )
        else
          const Text(
            'Aucune réalisation ajoutée',
            style: TextStyle(color: Colors.grey),
          ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Annuler'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                : Text(widget.experience == null ? 'Ajouter' : 'Modifier'),
          ),
        ),
      ],
    );
  }
}
