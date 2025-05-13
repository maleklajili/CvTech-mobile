// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:cv_tech/core/constants/dimension.dart';
import 'package:cv_tech/presentation/views/profile/widgets/profile_information/action_buttons.dart';
import 'principal_information.dart';

class ProfileInformation extends StatelessWidget {
  const ProfileInformation({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: Dimensions.paddingAllMedium,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Dimensions.heightHuge,
          // Informations principales
          PrincipalInformation(),
          Dimensions.heightExtraLarge,
          // Boutons d'action
          ActionButtons()
        ],
      ),
    );
  }
}
