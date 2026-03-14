// Project imports:
import 'package:cv_tech/core/enums/vote.dart';
import 'package:cv_tech/data/repositories/feed_repository.dart';
import 'package:cv_tech/presentation/views_models/base/base_view_model.dart';
import 'package:cv_tech/presentation/views_models/home/interfaces/home_interfaces.dart';
import 'package:flutter/foundation.dart';

class VotedPostViewModel extends BaseViewModel implements IVotedPost {
  int votes;
  final String? postId;
  final FeedRepository? _repository;
  
  VotedPostViewModel(
    super.context, {
    required this.votes,
    this.postId,
    FeedRepository? repository,
  }) : _repository = repository ?? (postId != null ? FeedRepository() : null);
  
  Vote voteType = Vote.neutre;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  @override
  void downVote() {
    if (_isLoading) return;
    
    final previousVoteType = voteType;
    final previousVotes = votes;

    // Optimistic update - immediate UI feedback
    if (voteType.isUp || voteType.isNeutre) {
      votes--;
      voteType = Vote.down;
    } else {
      // If already down, toggle off (neutre)
      votes++;
      voteType = Vote.neutre;
    }
    update();

    // Sync with backend if postId exists (fire-and-forget with error handling)
    if (postId != null && _repository != null) {
      _isLoading = true;
      
      // Determine the vote value to send:
      // - If new voteType is 'down', send 'down'
      // - If new voteType is 'neutre', send empty string (to remove vote)
      // - If new voteType is 'up', send 'up'
      final voteValue = voteType == Vote.down 
          ? 'down' 
          : (voteType == Vote.up ? 'up' : '');

      // Note: postId and _repository are guaranteed non-null here
      // ignore: unnecessary_non_null_assertion
      _repository!.votePost(
        postId!,
        vote: voteValue,
      ).then((result) {
        // Update with server response
        votes = result['votes'] ?? votes;
        update();
      }).catchError((e) {
        if (kDebugMode) print('Down vote error: $e');
        // Rollback on error
        votes = previousVotes;
        voteType = previousVoteType;
        update();
      }).whenComplete(() {
        _isLoading = false;
      });
    }
  }

  @override
  void upVote() {
    if (_isLoading) return;
    
    final previousVoteType = voteType;
    final previousVotes = votes;

    // Optimistic update - immediate UI feedback
    if (voteType.isDown || voteType.isNeutre) {
      votes++;
      voteType = Vote.up;
    } else {
      // If already up, toggle off (neutre)
      votes--;
      voteType = Vote.neutre;
    }
    update();

    // Sync with backend if postId exists (fire-and-forget with error handling)
    if (postId != null && _repository != null) {
      _isLoading = true;
      
      // Determine the vote value to send:
      // - If new voteType is 'up', send 'up'
      // - If new voteType is 'neutre', send empty string (to remove vote)
      // - If new voteType is 'down', send 'down'
      final voteValue = voteType == Vote.up 
          ? 'up' 
          : (voteType == Vote.down ? 'down' : '');

      // Note: postId and _repository are guaranteed non-null here
      // ignore: unnecessary_non_null_assertion
      _repository!.votePost(
        postId!,
        vote: voteValue,
      ).then((result) {
        // Update with server response
        votes = result['votes'] ?? votes;
        update();
      }).catchError((e) {
        if (kDebugMode) print('Up vote error: $e');
        // Rollback on error
        votes = previousVotes;
        voteType = previousVoteType;
        update();
      }).whenComplete(() {
        _isLoading = false;
      });
    }
  }
}
