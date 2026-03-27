import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/presentation/views_models/friend_group/friend_group_view_model.dart';
import 'package:cv_tech/presentation/widgets/reddit_feedback_widgets.dart';
import 'package:cv_tech/theme/app_theme.dart';

class FriendGroupFormSheet extends StatefulWidget {
  final String? groupId;
  final String? initialName;
  final String? initialDescription;
  final String? initialIcon;
  final String? initialColor;

  const FriendGroupFormSheet({
    super.key,
    this.groupId,
    this.initialName,
    this.initialDescription,
    this.initialIcon,
    this.initialColor,
  });

  bool get isEditMode => groupId != null && groupId!.isNotEmpty;

  @override
  State<FriendGroupFormSheet> createState() => _FriendGroupFormSheetState();
}

class _FriendGroupFormSheetState extends State<FriendGroupFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedIcon = 'group'; // Material icon name
  String _selectedColor = '#FF6B35'; // Orange by default

  static const List<String> _iconOptions = [
    'group',
    'people_alt',
    'favorite',
    'handshake',
    'work',
    'school',
    'sports_esports',
    'palette',
    'music_note',
    'sports_soccer',
    'home',
    'public',
  ];

  static const List<String> _colorOptions = [
    '#FF6B35',
    '#FF4B7C',
    '#9B59B6',
    '#3498DB',
    '#1ABC9C',
    '#2ECC71',
    '#F39C12',
    '#E74C3C',
    '#34495E',
    '#F1C40F',
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName ?? '';
    _descriptionController.text = widget.initialDescription ?? '';

    if (widget.initialIcon != null && _iconOptions.contains(widget.initialIcon)) {
      _selectedIcon = widget.initialIcon!;
    }
    if (widget.initialColor != null && _colorOptions.contains(widget.initialColor)) {
      _selectedColor = widget.initialColor!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitGroup() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = context.read<FriendGroupViewModel>();
    final success = widget.isEditMode
        ? await vm.updateGroup(
            widget.groupId!,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            icon: _selectedIcon,
            color: _selectedColor,
          )
        : await vm.createGroup(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            icon: _selectedIcon,
            color: _selectedColor,
          );

    if (mounted) {
      if (success) {
        RedditToastService.show(
          context,
          message: widget.isEditMode
              ? 'Groupe modifié avec succès'
              : 'Groupe créé avec succès',
          type: RedditToastType.mod,
        );
        Navigator.pop(context, true);
      } else {
        RedditToastService.show(
          context,
          message: vm.error ?? 'Erreur',
          type: RedditToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FriendGroupViewModel?>();
    if (vm == null) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Erreur de contexte',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Le provider FriendGroupViewModel est introuvable.',
                style: TextStyle(color: AppTheme.textMutedColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.isEditMode ? 'Modifier le groupe' : 'Créer un groupe',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Name field
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nom du groupe *',
                      hintText: 'Ex: Mes meilleurs amis',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) {
                        return 'Le nom est requis';
                      }
                      if (value!.length < 2) {
                        return 'Le nom doit contenir au moins 2 caractères';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  // Description field
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Décrivez ce groupe d\'amis',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 3,
                    maxLength: 200,
                  ),
                  const SizedBox(height: 12),
                  // Icon selector
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Icône',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textColor,
                      ),
                    ),
                  ),
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      border: Border.all(color: AppTheme.dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _iconOptions.map((icon) {
                        final isSelected = icon == _selectedIcon;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedIcon = icon),
                            child: Container(
                              width: 44,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryColor
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Icon(
                                  _getIconData(icon),
                                  size: 24,
                                  color: isSelected
                                      ? AppColors.primaryColor
                                      : AppTheme.textColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Color selector
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Couleur',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textColor,
                      ),
                    ),
                  ),
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      border: Border.all(color: AppTheme.dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _colorOptions.map((color) {
                        final isSelected = color == _selectedColor;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedColor = color),
                            child: Container(
                              width: 44,
                              decoration: BoxDecoration(
                                color: _parseColor(color),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Preview
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      border: Border.all(color: AppTheme.dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aperçu',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMutedColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: _parseColor(_selectedColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _parseColor(_selectedColor),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Icon(
                                    _getIconData(_selectedIcon),
                                    size: 24,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _nameController.text.trim().isEmpty
                                          ? 'Nom du groupe'
                                          : _nameController.text.trim(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '0 membres',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (vm.isCreating || vm.isUpdating) ? null : _submitGroup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: (vm.isCreating || vm.isUpdating)
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(widget.isEditMode
                                  ? 'Enregistrer'
                                  : 'Créer le groupe'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Color _parseColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xff')));
    } catch (_) {
      return AppColors.primaryColor;
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'group':
        return Icons.group;
      case 'people_alt':
        return Icons.people_alt;
      case 'favorite':
        return Icons.favorite;
      case 'handshake':
        return Icons.handshake;
      case 'work':
        return Icons.work;
      case 'school':
        return Icons.school;
      case 'sports_esports':
        return Icons.sports_esports;
      case 'palette':
        return Icons.palette;
      case 'music_note':
        return Icons.music_note;
      case 'sports_soccer':
        return Icons.sports_soccer;
      case 'home':
        return Icons.home;
      case 'public':
        return Icons.public;
      default:
        return Icons.group;
    }
  }
}
