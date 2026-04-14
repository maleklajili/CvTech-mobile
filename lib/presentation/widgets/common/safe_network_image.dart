import 'package:flutter/material.dart';

/// Safe network image provider that handles decompression errors gracefully.
/// Returns null if the URL is null or empty.
ImageProvider? safeNetworkImage(String? url) {
  if (url == null || url.isEmpty) return null;
  return NetworkImage(url);
}

/// Error handler for CircleAvatar.onBackgroundImageError.
/// Silently catches image decompression/load errors.
void onImageError(Object error, StackTrace? stackTrace) {
  debugPrint('Image load error: $error');
}

/// A safe Image.network wrapper that shows a fallback icon on error.
class SafeNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const SafeNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return errorWidget ??
          Icon(Icons.person, size: width ?? 40, color: Colors.grey);
    }
    return Image.network(
      imageUrl!,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ??
            SizedBox(
              width: width,
              height: height,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ??
            Icon(Icons.broken_image, size: width ?? 40, color: Colors.grey);
      },
    );
  }
}

/// A safe CircleAvatar that handles image errors.
class SafeCircleAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Widget? child;
  final Color? backgroundColor;

  const SafeCircleAvatar({
    super.key,
    this.imageUrl,
    this.radius = 20,
    this.child,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.grey.shade200,
      backgroundImage:
          (imageUrl != null && imageUrl!.isNotEmpty)
              ? NetworkImage(imageUrl!)
              : null,
      onBackgroundImageError:
          (imageUrl != null && imageUrl!.isNotEmpty)
              ? (_, __) => debugPrint('Avatar image error: $imageUrl')
              : null,
      child:
          (imageUrl == null || imageUrl!.isEmpty)
              ? (child ?? Icon(Icons.person, size: radius, color: Colors.grey))
              : child,
    );
  }
}
