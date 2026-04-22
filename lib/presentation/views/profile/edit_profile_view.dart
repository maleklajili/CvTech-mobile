// Flutter imports:
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

// Package imports:
import 'package:image_picker/image_picker.dart';

// Project imports:
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/constants/professional_domains.dart';
import 'package:cv_tech/constants/professional_categories.dart';
import 'package:cv_tech/data/models/auth/user_model.dart';
import 'package:cv_tech/data/repositories/user_repository.dart';
import 'package:cv_tech/data/repositories/ai_cv_repository.dart';
import 'package:cv_tech/theme/app_theme.dart';
import 'package:cv_tech/presentation/widgets/common/custom_toast.dart';
import 'package:cv_tech/core/l10n/app_localizations.dart';

class EditProfileView extends StatefulWidget {
  final UserModel user;
  final Function(UserModel) onProfileUpdated;

  const EditProfileView({
    super.key,
    required this.user,
    required this.onProfileUpdated,
  });

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  late TabController _tabController;

  // Controllers for Basic Info
  late TextEditingController _fullNameController;
  late TextEditingController _userNameController;
  late TextEditingController _professionalTitleController;
  late TextEditingController _bioController;
  bool _availability = false;

  // Controllers for Contact Info
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _cityController;
  late TextEditingController _addressController;
  late TextEditingController _postalCodeController;
  late TextEditingController _websiteController;
  String _phoneCode = '+216';

  // Controllers for Professional Profile
  String _professionalStatus = '';
  String _previousDomain = '';
  String _currentDomain = '';
  String _professionalCategory = '';
  late TextEditingController _keywordsController;
  File? _cvFile;

  // Image handling
  Uint8List? _profileImageBytes;
  Uint8List? _coverImageBytes;
  bool _removeProfileImage = false;
  bool _removeCoverImage = false;

  // Loading states
  bool _isLoading = false;
  bool _isGeolocating = false;

  // Track modified sections for rewards
  Set<String> _modifiedSections = {};

  // AI bio improvement
  bool _isImprovingBio = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeControllers();
  }

  void _initializeControllers() {
    // Basic Info
    _fullNameController = TextEditingController(
        text: '${widget.user.firstName} ${widget.user.lastName}');
    _userNameController = TextEditingController(text: widget.user.userName);
    _professionalTitleController =
        TextEditingController(text: widget.user.professionalTitle ?? '');
    _bioController = TextEditingController(text: widget.user.bio ?? '');
    _keywordsController =
        TextEditingController(text: widget.user.keywords ?? '');
    _availability = true;

    // Contact Info
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone ?? '');
    _cityController = TextEditingController(text: widget.user.city ?? '');
    _addressController = TextEditingController(text: widget.user.address ?? '');
    _postalCodeController = TextEditingController(text: '');
    _websiteController = TextEditingController(text: widget.user.website ?? '');

    // Professional Profile
    _professionalStatus = widget.user.professionalStatus ?? 'professional';
    _previousDomain = widget.user.previousDomain ?? '';
    _currentDomain = widget.user.currentDomain ?? '';
    _professionalCategory = widget.user.professionalCategory ?? '';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fullNameController.dispose();
    _userNameController.dispose();
    _professionalTitleController.dispose();
    _bioController.dispose();
    _keywordsController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _postalCodeController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  bool _canRewardSection(String sectionName) {
    // Check if section has been modified and can award coins
    return !_modifiedSections.contains(sectionName);
  }

  void _markSectionModified(String sectionName) {
    setState(() {
      _modifiedSections.add(sectionName);
    });
  }

  Future<void> _detectLocation() async {
    setState(() => _isGeolocating = true);
    try {
      // Simulate location detection
      await Future.delayed(const Duration(seconds: 2));
      _cityController.text = "Paris";
      _addressController.text = "123 Rue de la République";
      _postalCodeController.text = "75001";
      _markSectionModified('contactInfo');
    } finally {
      setState(() => _isGeolocating = false);
    }
  }

  Future<void> _pickImage(ImageSource source, bool isProfile) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          if (isProfile) {
            _profileImageBytes = bytes;
            _removeProfileImage = false;
            _markSectionModified('profileImage');
          } else {
            _coverImageBytes = bytes;
            _removeCoverImage = false;
            _markSectionModified('coverImage');
          }
        });
      }
    } catch (e) {
      CustomToast.error(context, '$e', title: 'Erreur de sélection');
    }
  }

  Widget _buildCoinsRewardBadge(int amount, bool showBadge) {
    if (!showBadge) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars, size: 14, color: AppColors.primaryColor),
          const SizedBox(width: 4),
          Text(
            '+$amount',
            style: const TextStyle(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required Widget child,
    String? rewardSection,
    int rewardAmount = 10,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (rewardSection != null)
                  _buildCoinsRewardBadge(
                    rewardAmount,
                    _canRewardSection(rewardSection),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            child,
          ],
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
    TextInputType? keyboardType,
    Widget? prefixIcon,
    VoidCallback? onTap,
    bool readOnly = false,
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
                ? [
                    const TextSpan(
                        text: ' *', style: TextStyle(color: Colors.red))
                  ]
                : [],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon,
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
              borderSide:
                  const BorderSide(color: AppColors.primaryColor, width: 2),
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

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required String hint,
    bool required = false,
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
                ? [
                    const TextSpan(
                        text: ' *', style: TextStyle(color: Colors.red))
                  ]
                : [],
          ),
        ),
        const SizedBox(height: 8),
        Builder(builder: (context) {
          // Guard against values not present in the items list to avoid
          // DropdownButton assertion errors when legacy/unknown values come
          // from the backend.
          final normalizedValue = (value == null || value.isEmpty)
              ? null
              : (items.any((item) => item.value == value) ? value : null);
          return DropdownButtonFormField<String>(
            value: normalizedValue,
            decoration: InputDecoration(
            hintText: hint,
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
              borderSide:
                  const BorderSide(color: AppColors.primaryColor, width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: items,
          onChanged: onChanged,
          validator: validator,
          isExpanded: true,
        );
        }),
      ],
    );
  }

  Widget _buildSwitchField({
    required String label,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primaryColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppTheme.isLight ? Colors.grey.shade50 : Colors.grey.shade900,
      appBar: AppBar(
        backgroundColor: AppTheme.isLight ? Colors.white : Colors.grey.shade800,
        elevation: 0,
        title: Text(AppLocalizations.of(context).editProfile),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: _buildCoinsRewardBadge(50, _modifiedSections.isNotEmpty),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Modern Tab Bar
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.primaryColor,
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey.shade600,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                labelPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                tabs: const [
                  Tab(text: 'Informations personnelles'),
                  Tab(text: 'Apparence'),
                  Tab(text: 'Confidentialité'),
                ],
              ),
            ),
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPersonalInfoTab(),
                  _buildAppearanceTab(),
                  _buildPrivacyTab(),
                ],
              ),
            ),
            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildBasicInfoSection(),
          const SizedBox(height: 16),
          _buildContactInfoSection(),
          const SizedBox(height: 16),
          _buildProfessionalProfileSection(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildCard(
      title: 'Informations de base',
      subtitle:
          'Modifiez vos informations personnelles visibles sur votre profil.',
      rewardSection: 'basicInfo',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextFormField(
                  controller: _fullNameController,
                  label: AppLocalizations.of(context).yourFullName,
                  hintText: 'Votre nom complet',
                  required: true,
                  validator: (value) => value?.isEmpty == true
                      ? 'Le nom complet est requis'
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextFormField(
                  controller: _userNameController,
                  label: 'Nom d\'utilisateur',
                  hintText: '@username',
                  required: true,
                  validator: (value) => value?.isEmpty == true
                      ? 'Le nom d\'utilisateur est requis'
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextFormField(
            controller: _professionalTitleController,
            label: 'Titre professionnel',
            hintText: 'Ex: Développeur Full Stack',
          ),
          const SizedBox(height: 16),
          _buildTextFormField(
            controller: _bioController,
            label: 'Biographie',
            hintText: 'Parlez-nous de vous...',
            maxLines: 4,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _isImprovingBio ? null : _improveBioWithAI,
              icon: _isImprovingBio
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome, size: 18),
              label: Text(
                _isImprovingBio ? 'Amélioration...' : 'Améliorer avec IA',
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSwitchField(
            label: AppLocalizations.of(context).availableNewOpportunities,
            description: AppLocalizations.of(context).showAvailabilityRecruiters,
            value: _availability,
            onChanged: (value) {
              setState(() => _availability = value);
              _markSectionModified('basicInfo');
            },
          ),
        ],
      ),
    );
  }

  Future<void> _improveBioWithAI() async {
    setState(() => _isImprovingBio = true);
    try {
      final repo = AiCvRepository();
      final result = await repo.improveBio();
      final summary = result['professional_summary'] as String?;
      if (summary != null && summary.isNotEmpty) {
        setState(() {
          _bioController.text = summary;
          _markSectionModified('basicInfo');
        });
        if (mounted) {
          CustomToast.success(context, 'Biographie améliorée avec succès !');
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isImprovingBio = false);
    }
  }

  Widget _buildContactInfoSection() {
    return _buildCard(
      title: 'Informations de contact',
      subtitle: 'Gérez vos informations de contact et de localisation.',
      rewardSection: 'contactInfo',
      child: Column(
        children: [
          _buildTextFormField(
            controller: _emailController,
            label: AppLocalizations.of(context).email,
            keyboardType: TextInputType.emailAddress,
            required: true,
            validator: (value) =>
                value?.isEmpty == true ? 'L\'email est requis' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 130,
                child: _buildDropdownField(
                  label: 'Code',
                  value: _phoneCode,
                  hint: '+216',
                  items: const [
                    DropdownMenuItem(
                        value: '+216', child: Text('🇹🇳 +216')),
                    DropdownMenuItem(value: '+33', child: Text('🇫🇷 +33')),
                    DropdownMenuItem(value: '+1', child: Text('🇺🇸 +1')),
                    DropdownMenuItem(value: '+44', child: Text('🇬🇧 +44')),
                    DropdownMenuItem(value: '+49', child: Text('🇩🇪 +49')),
                    DropdownMenuItem(value: '+39', child: Text('🇮🇹 +39')),
                  ],
                  onChanged: (value) =>
                      setState(() => _phoneCode = value ?? '+216'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextFormField(
                  controller: _phoneController,
                  label: AppLocalizations.of(context).phone,
                  hintText: '20 123 456',
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildTextFormField(
                  controller: _cityController,
                  label: AppLocalizations.of(context).city,
                  hintText: 'Paris',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextFormField(
                  controller: _postalCodeController,
                  label: 'Code postal',
                  hintText: '75001',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextFormField(
            controller: _addressController,
            label: AppLocalizations.of(context).address,
            hintText: '123 Rue de la République',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextFormField(
                  controller: _websiteController,
                  label: 'Site web',
                  hintText: 'https://monsite.com',
                  keyboardType: TextInputType.url,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _isGeolocating ? null : _detectLocation,
                icon: _isGeolocating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.location_on, size: 16),
                label: Text(_isGeolocating ? 'Détection...' : 'Localiser'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalProfileSection() {
    return _buildCard(
      title: 'Profil professionnel',
      subtitle: 'Renseignez vos informations professionnelles.',
      rewardSection: 'professionalProfile',
      child: Column(
        children: [
          _buildDropdownField(
            label: 'Statut professionnel',
            value: _professionalStatus,
            hint: 'Sélectionner un statut',
            required: true,
            items: ['professional', 'student', 'freelancer', 'unemployed']
                .map((status) =>
                    DropdownMenuItem(value: status, child: Text(status)))
                .toList(),
            onChanged: (value) =>
                setState(() => _professionalStatus = value ?? ''),
            validator: (value) => value?.isEmpty == true
                ? 'Le statut professionnel est requis'
                : null,
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            label: 'Domaine précédent',
            value: _previousDomain,
            hint: 'Sélectionner votre domaine précédent',
            items: previousDomains
                .map((domain) => DropdownMenuItem(
                      value: domain.value,
                      child: Text(domain.label),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _previousDomain = value ?? ''),
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            label: 'Domaine actuel',
            value: _currentDomain,
            hint: 'Sélectionner votre domaine actuel',
            required: true,
            items: reconversionDomains
                .map((domain) => DropdownMenuItem(
                      value: domain.value,
                      child: Text(domain.label),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _currentDomain = value ?? ''),
            validator: (value) =>
                value?.isEmpty == true ? 'Le domaine actuel est requis' : null,
          ),
          const SizedBox(height: 16),
          _buildDropdownField(
            label: 'Catégorie professionnelle',
            value: _professionalCategory,
            hint: 'Sélectionner une catégorie',
            required: true,
            items: professionalCategories
                .map((category) => DropdownMenuItem(
                      value: category.value,
                      child: Text(category.label),
                    ))
                .toList(),
            onChanged: (value) =>
                setState(() => _professionalCategory = value ?? ''),
            validator: (value) => value?.isEmpty == true
                ? 'La catégorie professionnelle est requise'
                : null,
          ),
          const SizedBox(height: 16),
          _buildTextFormField(
            controller: _keywordsController,
            label: 'Mots-clés',
            hintText: 'React, Node.js, Python...',
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          // CV Upload Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CV',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (_cvFile == null)
                  GestureDetector(
                    onTap: () {
                      // TODO: Implement CV file picker
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.grey.shade300,
                            style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.cloud_upload_outlined,
                              size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'Cliquer pour télécharger votre CV',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      const Icon(Icons.description, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_cvFile!.path.split('/').last)),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => setState(() => _cvFile = null),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildCoverImageSection(),
          const SizedBox(height: 16),
          _buildProfileImageSection(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCoverImageSection() {
    return _buildCard(
      title: 'Photo de couverture',
      subtitle: 'Téléchargez une image de couverture pour votre profil (3:1).',
      rewardSection: 'coverImage',
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _showImageSourceDialog(false),
            child: Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _coverImageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(_coverImageBytes!, fit: BoxFit.cover),
                    )
                  : widget.user.coverUrl != null && !_removeCoverImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            widget.user.coverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildEmptyImagePlaceholder(false),
                          ),
                        )
                      : _buildEmptyImagePlaceholder(false),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showImageSourceDialog(false),
                  icon: const Icon(Icons.upload),
                  label: const Text('Changer'),
                ),
              ),
              if (_coverImageBytes != null ||
                  (widget.user.coverUrl != null && !_removeCoverImage)) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _coverImageBytes = null;
                        _removeCoverImage = true;
                      });
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Supprimer'),
                    style:
                        OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return _buildCard(
      title: 'Photo de profil',
      subtitle: 'Téléchargez une photo de profil professionnelle (1:1).',
      rewardSection: 'profileImage',
      child: Column(
        children: [
          Center(
            child: GestureDetector(
              onTap: () => _showImageSourceDialog(true),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(60),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: _profileImageBytes != null
                    ? ClipOval(
                        child: Image.memory(_profileImageBytes!,
                            fit: BoxFit.cover),
                      )
                    : widget.user.imageUrl != null && !_removeProfileImage
                        ? ClipOval(
                            child: Image.network(
                              widget.user.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildEmptyImagePlaceholder(true),
                            ),
                          )
                        : _buildEmptyImagePlaceholder(true),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showImageSourceDialog(true),
                  icon: const Icon(Icons.upload),
                  label: const Text('Changer'),
                ),
              ),
              if (_profileImageBytes != null ||
                  (widget.user.imageUrl != null && !_removeProfileImage)) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _profileImageBytes = null;
                        _removeProfileImage = true;
                      });
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Supprimer'),
                    style:
                        OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildCard(
            title: 'Paramètres de confidentialité',
            subtitle: 'Gérez la visibilité de vos informations.',
            child: Column(
              children: [
                _buildSwitchField(
                  label: 'Profil public',
                  description:
                      'Votre profil sera visible par tous les utilisateurs',
                  value: true,
                  onChanged: (value) {},
                ),
                const SizedBox(height: 16),
                _buildSwitchField(
                  label: 'Afficher l\'email',
                  description:
                      'Votre adresse email sera visible sur votre profil',
                  value: false,
                  onChanged: (value) {},
                ),
                const SizedBox(height: 16),
                _buildSwitchField(
                  label: 'Afficher le téléphone',
                  description:
                      'Votre numéro de téléphone sera visible sur votre profil',
                  value: false,
                  onChanged: (value) {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEmptyImagePlaceholder(bool isProfile) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isProfile ? Icons.person_outline : Icons.image_outlined,
            size: isProfile ? 40 : 48,
            color: Colors.grey.shade400,
          ),
          if (!isProfile) ...[
            const SizedBox(height: 8),
            Text(
              'Photo de couverture\nnon définie',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showImageSourceDialog(bool isProfile) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isProfile ? 'Photo de profil' : 'Photo de couverture',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.camera, isProfile);
                          },
                          icon: const Icon(
                            Icons.camera_alt,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Caméra'),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.gallery, isProfile);
                          },
                          icon: const Icon(
                            Icons.photo_library,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Galerie'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
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
              child: Text(
                AppLocalizations.of(context).cancel,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Enregistrement...'),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context).save,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userRepository = UserRepository();

      // Extraire firstName et lastName du fullName
      final nameParts = _fullNameController.text.trim().split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : '';
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      // Parser le postalCode
      int? postalCode;
      if (_postalCodeController.text.isNotEmpty) {
        postalCode = int.tryParse(_postalCodeController.text);
      }

      // Créer la requête de mise à jour
      final request = UpdateProfileRequest(
        firstName: firstName,
        lastName: lastName,
        userName: _userNameController.text.trim(),
        email: _emailController.text.trim(),
        bio: _bioController.text.trim(),
        city: _cityController.text.trim(),
        address: _addressController.text.trim(),
        professionalTitle: _professionalTitleController.text.trim(),
        postalCode: postalCode,
        phone: _phoneController.text.trim(),
        website: _websiteController.text.trim(),
        professionalStatus:
            _professionalStatus.isNotEmpty ? _professionalStatus : null,
        previousDomain: _previousDomain.isNotEmpty ? _previousDomain : null,
        currentDomain: _currentDomain.isNotEmpty ? _currentDomain : null,
        professionalCategory:
            _professionalCategory.isNotEmpty ? _professionalCategory : null,
        keywords: _keywordsController.text.trim().isNotEmpty
            ? _keywordsController.text.trim()
            : null,
        removeImage: _removeProfileImage,
        removeCover: _removeCoverImage,
      );

      // Préparer les images si nécessaire
      // Note: Sur web, on utilise directement les bytes
      // Sur mobile/desktop, on pourrait utiliser des chemins de fichiers
      List<int>? imageBytes;
      List<int>? coverBytes;

      // Si une nouvelle image de profil a été sélectionnée
      if (_profileImageBytes != null && !_removeProfileImage) {
        imageBytes = _profileImageBytes;
      }

      // Si une nouvelle image de couverture a été sélectionnée
      if (_coverImageBytes != null && !_removeCoverImage) {
        coverBytes = _coverImageBytes;
      }

      print('📤 Saving profile with request: ${request.toJson()}');
      print('📤 Image bytes length: ${imageBytes?.length}');
      print('📤 Cover bytes length: ${coverBytes?.length}');

      // Appeler l'API
      final updatedUser = await userRepository.updateProfile(
        request,
        imageBytes: imageBytes,
        coverBytes: coverBytes,
      );

      print('✅ Profile updated successfully: ${updatedUser.fullName}');

      // Notifier le parent avec l'utilisateur mis à jour
      widget.onProfileUpdated(updatedUser);

      if (mounted) {
        CustomToast.success(context, AppLocalizations.of(context).profileUpdated);
        Navigator.pop(context);
      }
    } catch (e) {
      print('❌ Error saving profile: $e');
      if (mounted) {
        CustomToast.error(context, '$e', title: 'Mise à jour échouée');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
