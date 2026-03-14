// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:cv_tech/core/enums/vote.dart';
import 'package:cv_tech/presentation/views_models/home/voted_post_view_model.dart';
import '../../../../core/constants/app_colors.dart';

class VotedPostWidget extends StatelessWidget {
  final int votes;
  const VotedPostWidget({super.key, required this.votes});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => VotedPostViewModel(context, votes: votes),
      child: Consumer<VotedPostViewModel>(
        builder: (context, viewModel, child) => _buildVotedPost(viewModel),
      ),
    );
  }

  Widget _buildVotedPost(VotedPostViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.grey.withOpacity(0.05),
      child: Column(
        children: [
          IconButton(
            icon: Icon(
              viewModel.voteType.isUp ? Icons.thumb_up : Icons.thumb_up_outlined,
              color: viewModel.voteType.isUp
                  ? AppColors.primaryColor
                  : AppColors.textMutedColor,
              size: 20,
            ),
            onPressed: viewModel.upVote,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '${viewModel.votes}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: viewModel.voteType.isUp
                    ? AppColors.primaryColor
                    : viewModel.voteType.isDown
                        ? Colors.blue
                        : AppColors.textMutedColor,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              viewModel.voteType.isDown ? Icons.thumb_down : Icons.thumb_down_outlined,
              color: viewModel.voteType.isDown
                  ? Colors.blue
                  : AppColors.textMutedColor,
              size: 20,
            ),
            onPressed: viewModel.downVote,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
