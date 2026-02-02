// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:cv_tech/core/constants/dimension.dart';
import '../../../../widgets/custom_tab_bar.dart';
import 'contenu_tab/contenu_tab.dart';
import 'info_tab/info_tab.dart';
import 'parcours_tab/parcours_tab.dart';

class TabBarPofile extends StatelessWidget {
  const TabBarPofile({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                  borderRadius: Dimensions.smallBorderRadius,
                ),
                child: CustomTabBar(
                  context: context,
                  tabs: const [
                    Tab(text: 'Info'),
                    Tab(text: 'Parcours'),
                    Tab(text: 'Contenu'),
                  ],
                ),
              ),
              Flexible(
                child: TabBarView(
                  children: const [
                    InfoTab(),
                    ParcoursTab(),
                    ContenuTab(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
