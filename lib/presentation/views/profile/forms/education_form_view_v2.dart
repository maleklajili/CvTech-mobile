// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

// Project imports:
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/core/constants/skill_categories.dart';
import 'package:cv_tech/data/models/profile/education_model.dart';
import 'package:cv_tech/data/models/profile/skill_reference_model.dart';
import 'package:cv_tech/data/models/profile/certificate_reference_model.dart';
import 'package:cv_tech/presentation/views_models/profile/professional_profile_view_model.dart';
import 'package:cv_tech/presentation/views_models/profile/profile_view_model.dart';
import 'package:cv_tech/theme/app_theme.dart';
import 'package:cv_tech/presentation/widgets/common/custom_toast.dart';
import 'package:cv_tech/core/l10n/app_localizations.dart';

class EducationFormViewV2 extends StatefulWidget {
  final EducationModel? education;

  const EducationFormViewV2({super.key, this.education});

  @override
  State<EducationFormViewV2> createState() => _EducationFormViewV2State();
}

class _EducationFormViewV2State extends State<EducationFormViewV2> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _degreeController;
  late TextEditingController _schoolController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  late TextEditingController _gradeController;
  late TextEditingController _urlController;

  // State
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _current = false;
  bool _isLoading = false;
  EducationType _type = EducationType.diploma;
  List<SkillReference> _skills = [];
  List<CertificateReference> _certificates = [];
  List<String> _certificatesToDelete = [];

  // Skill selection
  String? _selectedCategory;

  ProfessionalProfileViewModel? _viewModel;

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
    _degreeController = TextEditingController();
    _schoolController = TextEditingController();
    _locationController = TextEditingController();
    _descriptionController = TextEditingController();
    _gradeController = TextEditingController();
    _urlController = TextEditingController();
  }

  void _loadExistingData() {
    if (widget.education != null) {
      _degreeController.text = widget.education!.degree;
      _schoolController.text = widget.education!.school;
      _locationController.text = widget.education!.location;
      _descriptionController.text = widget.education!.description;
      _gradeController.text = widget.education!.grade ?? '';
      _urlController.text = widget.education!.url ?? '';
      _startDate = widget.education!.startDate;
      _endDate = widget.education!.endDate;
      _current = widget.education!.current;
      _type = widget.education!.type;
      _skills = List.from(widget.education!.skills);
      _certificates = List.from(widget.education!.certificates);
    }
  }

  @override
  void dispose() {
    _degreeController.dispose();
    _schoolController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _gradeController.dispose();
    _urlController.dispose();
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
        CustomToast.error(context, '$e', title: AppLocalizations.of(context).selectionError);
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

    if (!_current && _endDate == null) {
      CustomToast.warning(context, AppLocalizations.of(context).pleaseSelectEndDateOrCurrentTraining);
      return;
    }

    setState(() => _isLoading = true);

    final viewModel = _viewModel;
    if (viewModel == null) {
      CustomToast.error(context, 'Session expirée, veuillez réessayer.');
      setState(() => _isLoading = false);
      return;
    }
    final profileViewModel = context.read<ProfileViewModel>();
    final userId = profileViewModel.user?.id ?? '';

    final education = EducationModel(
      id: widget.education?.id,
      userId: userId,
      degree: _degreeController.text.trim(),
      school: _schoolController.text.trim(),
      location: _locationController.text.trim(),
      description: _descriptionController.text.trim(),
      startDate: _startDate,
      endDate: _current ? null : _endDate,
      current: _current,
      type: _type,
      grade: _gradeController.text.trim().isEmpty ? null : _gradeController.text.trim(),
      url: _urlController.text.trim().isEmpty ? null : _urlController.text.trim(),
      skills: _skills,
      certificates: _certificates,
    );

    // Extract certificate bytes for upload
    final certificateFiles = _certificates
        .where((c) => c.bytes != null)
        .map((c) => c.bytes!)
        .toList();

    bool success;
    if (widget.education == null) {
      success = await viewModel.addEducationV2(education, certificateFiles);
    } else {
      success = await viewModel.updateEducationV2(
        widget.education!.id!,
        education,
        certificateFiles,
        _certificatesToDelete,
      );
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        CustomToast.success(
          context,
          widget.education == null
              ? AppLocalizations.of(context).educationAddedSuccess
              : AppLocalizations.of(context).educationModifiedSuccess,
        );
      } else {
        CustomToast.error(context, viewModel.educationError ?? AppLocalizations.of(context).errorOccurred);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.isLight ? Colors.grey.shade50 : Colors.grey.shade900,
      appBar: AppBar(
        title: Text(widget.education == null
            ? AppLocalizations.of(context).addEducation
            : AppLocalizations.of(context).editEducation),
        backgroundColor: AppTheme.isLight ? Colors.white : Colors.grey.shade800,
        elevation: 0,
        actions: [
          if (widget.education == null)
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
                  _buildTypeField(),
                  const SizedBox(height: 24),
                  _buildDegreeField(),
                  const SizedBox(height: 24),
                  _buildSchoolField(),
                  const SizedBox(height: 24),
                  _buildLocationField(),
                  const SizedBox(height: 24),
                  _buildDateSection(),
                  const SizedBox(height: 24),
                  _buildGradeField(),
                  const SizedBox(height: 24),
                  _buildUrlField(),
                  const SizedBox(height: 24),
                  _buildDescriptionField(),
                  const SizedBox(height: 32),
                  _buildSkillsSection(),
                  const SizedBox(height: 32),
                  _buildCertificatesSection(),
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

  Widget _buildTypeField() {
    return DropdownButtonFormField<EducationType>(
      value: _type,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context).educationType,
        prefixIcon: const Icon(Icons.category),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: [
        DropdownMenuItem(value: EducationType.diploma, child: Text(AppLocalizations.of(context).diplomaLabel)),
        DropdownMenuItem(value: EducationType.certification, child: Text(AppLocalizations.of(context).certificationLabel)),
        DropdownMenuItem(value: EducationType.course, child: Text(AppLocalizations.of(context).courseTraining)),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() => _type = value);
        }
      },
    );
  }

  Widget _buildDegreeField() {
    return TextFormField(
      controller: _degreeController,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context).diplomaCertification,
        hintText: AppLocalizations.of(context).diplomaHint,
        prefixIcon: const Icon(Icons.school),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return AppLocalizations.of(context).pleaseEnterDiplomaName;
        }
        return null;
      },
    );
  }

  Widget _buildSchoolField() {
    return TextFormField(
      controller: _schoolController,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context).schoolInstitution,
        hintText: AppLocalizations.of(context).schoolHint,
        prefixIcon: const Icon(Icons.business),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return AppLocalizations.of(context).pleaseEnterSchoolName;
        }
        return null;
      },
    );
  }

  Widget _buildLocationField() {
    return TextFormField(
      controller: _locationController,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context).locationLabel,
        hintText: AppLocalizations.of(context).locationHint,
        prefixIcon: const Icon(Icons.location_on),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return AppLocalizations.of(context).pleaseEnterLocation;
        }
        return null;
      },
    );
  }

  Widget _buildGradeField() {
    return TextFormField(
      controller: _gradeController,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context).gradeOptional,
        hintText: AppLocalizations.of(context).gradeHint,
        prefixIcon: const Icon(Icons.grade),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildUrlField() {
    return TextFormField(
      controller: _urlController,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context).webLinkOptional,
        hintText: AppLocalizations.of(context).webLinkHint,
        prefixIcon: const Icon(Icons.link),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: TextInputType.url,
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
                    labelText: AppLocalizations.of(context).startDate,
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
                onTap: _current ? null : () => _selectDate(context, false),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).endDate,
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabled: !_current,
                  ),
                  child: Text(
                    _current
                        ? AppLocalizations.of(context).inProgress
                        : (_endDate != null ? dateFormat.format(_endDate!) : AppLocalizations.of(context).notDefined),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          title: Text(AppLocalizations.of(context).trainingInProgress),
          value: _current,
          onChanged: (value) {
            setState(() {
              _current = value ?? false;
              if (_current) {
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
        labelText: AppLocalizations.of(context).descriptionLabel,
        hintText: AppLocalizations.of(context).describeTraining,
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
        Text(
          AppLocalizations.of(context).acquiredSkills,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        // Skill search/add
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).categoryLabel,
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
                    labelText: AppLocalizations.of(context).skillLabel,
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
          Text(
            AppLocalizations.of(context).noSkillAdded,
            style: const TextStyle(color: Colors.grey),
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
            Text(
              AppLocalizations.of(context).certificatesDiplomas,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: _pickCertificate,
              icon: const Icon(Icons.upload_file, size: 18),
              label: Text(AppLocalizations.of(context).add),
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
                      ? Text(AppLocalizations.of(context).newFile)
                      : Text(AppLocalizations.of(context).alreadyUploaded),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeCertificate(cert),
                  ),
                ),
              );
            }).toList(),
          )
        else
          Text(
            AppLocalizations.of(context).noCertificateAdded,
            style: const TextStyle(color: Colors.grey),
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
            child: Text(AppLocalizations.of(context).cancel),
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
                : Text(widget.education == null ? AppLocalizations.of(context).add : AppLocalizations.of(context).edit),
          ),
        ),
      ],
    );
  }
}
