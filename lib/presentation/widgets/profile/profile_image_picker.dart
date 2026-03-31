// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/presentation/views_models/profile/profile_view_model.dart';
import 'package:cv_tech/presentation/widgets/common/custom_toast.dart';

class ProfileImagePicker extends StatefulWidget {
  final String? currentImageUrl;
  final bool isCover;

  const ProfileImagePicker({
    super.key,
    this.currentImageUrl,
    this.isCover = false,
  });

  @override
  State<ProfileImagePicker> createState() => _ProfileImagePickerState();
}

class _ProfileImagePickerState extends State<ProfileImagePicker> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickAndUploadImage(BuildContext context) async {
    try {
      // Afficher les options (caméra ou galerie)
      final ImageSource? source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Galerie'),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Caméra'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
              ],
            ),
          );
        },
      );

      if (source == null) return;

      // Sélectionner l'image
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: widget.isCover ? 1920 : 800,
        maxHeight: widget.isCover ? 1080 : 800,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      // Uploader l'image
      final profileViewModel = context.read<ProfileViewModel>();
      
      // Sur web, XFile.path n'est pas disponible, on utilise readAsBytes
      // Sur mobile, on peut utiliser soit path soit bytes
      final imageBytes = await image.readAsBytes();
      final bool success;

      if (widget.isCover) {
        success = await profileViewModel.uploadCoverImage(null, coverBytes: imageBytes);
      } else {
        success = await profileViewModel.uploadProfileImage(null, imageBytes: imageBytes);
      }

      setState(() => _isUploading = false);

      if (mounted) {
        if (success) {
          CustomToast.success(
            context,
            widget.isCover
                ? 'Image de couverture mise à jour'
                : 'Photo de profil mise à jour',
          );
        } else {
          CustomToast.error(
            context,
            profileViewModel.errorMessage ?? 'Erreur lors de la mise à jour',
          );
        }
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        CustomToast.error(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isUploading ? null : () => _pickAndUploadImage(context),
      child: Stack(
        children: [
          // Image actuelle ou placeholder
          if (widget.currentImageUrl != null &&
              widget.currentImageUrl!.isNotEmpty)
            _buildNetworkImage()
          else
            _buildPlaceholder(),

          // Overlay avec icône caméra
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: widget.isCover ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: widget.isCover ? BorderRadius.circular(12) : null,
              ),
              child: Center(
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: widget.isCover ? 48 : 32,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkImage() {
    if (widget.isCover) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: NetworkImage(widget.currentImageUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return CircleAvatar(
        radius: 60,
        backgroundImage: NetworkImage(widget.currentImageUrl!),
      );
    }
  }

  Widget _buildPlaceholder() {
    if (widget.isCover) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              AppColors.primaryColor.withOpacity(0.3),
              AppColors.primaryColor.withOpacity(0.1),
            ],
          ),
        ),
        child: const Center(
          child: Icon(Icons.add_photo_alternate, size: 48, color: Colors.white),
        ),
      );
    } else {
      return CircleAvatar(
        radius: 60,
        backgroundColor: AppColors.primaryColor.withOpacity(0.2),
        child: Icon(
          Icons.person,
          size: 50,
          color: AppColors.primaryColor,
        ),
      );
    }
  }
}
