// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:cv_tech/data/test/fake_data.dart';
import 'package:cv_tech/presentation/views/home/widgets/post_card.dart';

class HomeView extends StatelessWidget {
  final ScrollController scrollController;
  const HomeView({
    super.key,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      controller: scrollController,
      itemCount: posts.length,
      itemBuilder: (context, index) => PostCard(post: posts[index]),
    );
  }
}
