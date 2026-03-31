import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/data/models/feed/feed_post_model.dart';
import 'package:cv_tech/presentation/views_models/feed/feed_view_model.dart';
import 'package:cv_tech/theme/app_theme.dart';
import 'package:cv_tech/presentation/widgets/common/custom_toast.dart';

/// Page de création / édition d'un post (style LinkedIn)
class CreatePostView extends StatefulWidget {
  final FeedPostModel? post; // null = création, non-null = édition
  final String? communityId;
  final String? communityTitle;

  const CreatePostView({
    super.key,
    this.post,
    this.communityId,
    this.communityTitle,
  });

  @override
  State<CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends State<CreatePostView> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  final List<String> _tags = [];
  bool _isLoading = false;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  bool get isEditing => widget.post != null;

  @override
  void initState() {
    super.initState();
    if (widget.post != null) {
      _titleController.text = widget.post!.title;
      _contentController.text = widget.post!.content;
      _tags.addAll(widget.post!.tags);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = picked.name;
      });
    }
  }

  void _addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isNotEmpty && !_tags.contains(trimmed)) {
      setState(() {
        _tags.add(trimmed);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      CustomToast.warning(context, 'Le titre est obligatoire');
      return;
    }

    if (content.isEmpty) {
      CustomToast.warning(context, 'Le contenu est obligatoire');
      return;
    }

    setState(() => _isLoading = true);

    final viewModel = context.read<FeedViewModel>();
    bool success;

    if (isEditing) {
      success = await viewModel.updatePost(
        widget.post!.id!,
        title: title,
        content: content,
        tags: _tags.isEmpty ? null : _tags,
        imageBytes: _selectedImageBytes,
        imageName: _selectedImageName,
      );
    } else {
      success = await viewModel.createPost(
        title: title,
        content: content,
        communityId: widget.communityId,
        tags: _tags.isEmpty ? null : _tags,
        imageBytes: _selectedImageBytes,
        imageName: _selectedImageName,
      );
    }

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        CustomToast.success(
          context,
          isEditing
              ? 'Post modifie'
              : (widget.communityId != null
                  ? 'Post publie dans la communaute'
                  : 'Post publie'),
        );
      } else {
        CustomToast.error(context, viewModel.errorMessage ?? 'Erreur');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? 'Modifier le post'
              : (widget.communityTitle != null && widget.communityTitle!.isNotEmpty
                  ? 'Publier dans ${widget.communityTitle}'
                  : 'Creer un post'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(isEditing ? 'Enregistrer' : 'Publier'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title field
            TextField(
              controller: _titleController,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                hintText: 'Titre de votre publication',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const Divider(),
            // Content field
            TextField(
              controller: _contentController,
              style: const TextStyle(fontSize: 16, height: 1.5),
              decoration: const InputDecoration(
                hintText: 'De quoi voulez-vous parler ?',
                border: InputBorder.none,
              ),
              maxLines: null,
              minLines: 5,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            // Image preview
            if (_selectedImageBytes != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _selectedImageBytes!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedImageBytes = null;
                        _selectedImageName = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            // Tags
            if (!isEditing && widget.communityTitle != null && widget.communityTitle!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCFE7FF)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.groups_2_outlined, size: 16, color: AppColors.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Communaute ciblee: ${widget.communityTitle}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_tags.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text('#$tag', style: const TextStyle(fontSize: 13)),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeTag(tag),
                    backgroundColor:
                        AppColors.primaryColor.withOpacity(0.1),
                    side: BorderSide.none,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            if (_tags.isNotEmpty) const SizedBox(height: 8),
            // Tag input
            TextField(
              controller: _tagController,
              decoration: InputDecoration(
                hintText: 'Ajouter un tag...',
                prefixIcon: const Icon(Icons.tag, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppTheme.dividerColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              onSubmitted: _addTag,
            ),
            const SizedBox(height: 24),
            // Media actions
            const Text(
              'Ajouter à votre publication',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _MediaButton(
                  icon: Icons.image,
                  label: 'Photo',
                  color: Colors.green,
                  onTap: _pickImage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MediaButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: AppTheme.textMutedColor)),
          ],
        ),
      ),
    );
  }
}
