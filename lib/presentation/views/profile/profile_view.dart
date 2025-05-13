// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:cv_tech/core/constants/dimension.dart';
import 'package:cv_tech/presentation/views/profile/widgets/app_bar.dart/silver_app_bar.dart';
import 'package:cv_tech/presentation/views/profile/widgets/profile_information/profile_information.dart';
import 'package:cv_tech/presentation/views/profile/widgets/statistiques/statistques_widget.dart';
import 'package:cv_tech/presentation/views/profile/widgets/tab_profile/tab_bar_pofile.dart';
import 'package:cv_tech/presentation/views_models/profile/profile_view_model.dart';
import 'package:cv_tech/theme/app_theme.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProfileViewModel(context),
      child: Consumer<ProfileViewModel>(
        builder: (context, viewModel, child) => Scaffold(
          backgroundColor: AppTheme.isLight ? Colors.grey.shade100 : null,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: AppBar(
              title: Text(
                'Profile',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              actions: [
                Container(
                  margin: Dimensions.horizontalPaddingMedium,
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.settings_outlined,
                    ),
                  ),
                )
              ],
            ),
          ),
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              const SliverAppBar(
                expandedHeight: 150,
                automaticallyImplyLeading: false,
                flexibleSpace: ProfileAppBar(),
              )
            ],
            body: const Column(
              children: [
                // Informations du profil
                ProfileInformation(),
                // Statistiques
                StatistquesWidget(),
                Dimensions.heightExtraLarge,
                // Tabs
                Expanded(
                  child: TabBarPofile(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
