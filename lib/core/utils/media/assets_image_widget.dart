// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:cv_tech/core/utils/media/base_api_image.dart';

class AssetsImageWidget extends BaseApiImage {
  const AssetsImageWidget({
    super.key,
    required super.imageFileName,
    super.isProfilePicture,
    super.fit,
    super.hasImageView,
    super.height,
    super.width,
  });

  @override
  Widget build(BuildContext context) {
    return buildImage(
      context,
      AssetImage(imageFileName!),
    );
  }

  @override
  Widget placeHolderImage(BuildContext context, {bool isLoading = false}) {
    // TODO: implement placeHolderImage
    throw UnimplementedError();
  }

  @override
  Widget buildImage(BuildContext context, ImageProvider<Object> imageProvider) {
    // TODO: implement buildImage
    throw UnimplementedError();
  }
}
