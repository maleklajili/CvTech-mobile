// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:cv_tech/core/constants/dimension.dart';
import '../../../../../core/utils/media/api_image_widget.dart';

class AvatarUser extends StatelessWidget {
  const AvatarUser({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: Theme.of(context).colorScheme.surface,
              width: 4,
            ),
            borderRadius: Dimensions.smallBorderRadius,
          ),
          child: const ApiImageWidget(
            height: 80,
            width: 80,
            borderRadius: Dimensions.smallBorderRadius,
            imageFileName: '',
            imageNetworUrl:
                'https://farm3.staticflickr.com/2378/2178054924_423324aac8.jpg',
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.surface,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
