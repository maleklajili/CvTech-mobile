// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/core/utils/media/i_show_image_viewer.dart';

abstract class BaseApiImage extends StatelessWidget
    implements IShowImageViewer {
  final String? imageFileName;
  final String? imageNetworUrl;
  final BoxFit? fit;
  final double width;
  final double height;
  final bool isProfilePicture;
  final BorderRadius? borderRadius;

  final bool hasImageView;
  final Color color;
  final String? placeholderAssetPath;

  final Border? border;
  final List<BoxShadow>? boxShadow;

  const BaseApiImage({
    super.key,
    required this.imageFileName,
    this.isProfilePicture = false,
    this.imageNetworUrl,
    this.fit,
    this.height = 80.0,
    this.width = 80.0,
    this.hasImageView = false,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.color = AppColors.textMutedColor,
    this.placeholderAssetPath,
  });

  Widget buildImage(
    BuildContext context,
    ImageProvider imageProvider,
  ) {
    return InkWell(
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      onTap: hasImageView ? () => showImageViewer(context) : null,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: color,
          border: border,
          boxShadow: boxShadow,
          borderRadius: isProfilePicture ? null : borderRadius,
          shape: isProfilePicture ? BoxShape.circle : BoxShape.rectangle,
        ),
        child: Image(
          image: imageProvider,
          fit: fit,
          height: height,
          width: width,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context);

  @override
  void showImageViewer(BuildContext context) {
    // TODO: implement showImageViewer
  }

  Widget placeHolderImage(BuildContext context, {bool isLoading = false});
}
