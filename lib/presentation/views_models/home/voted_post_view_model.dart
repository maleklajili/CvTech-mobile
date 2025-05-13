// Project imports:
import 'package:cv_tech/core/enums/vote.dart';
import 'package:cv_tech/presentation/views_models/base/base_view_model.dart';
import 'package:cv_tech/presentation/views_models/home/interfaces/home_interfaces.dart';

class VotedPostViewModel extends BaseViewModel implements IVotedPost {
  int votes;
  VotedPostViewModel(super.context, {required this.votes});
  Vote voteType = Vote.neutre;
  @override
  void downVote() {
    if (voteType.isUp || voteType.isNeutre) {
      votes--;
      voteType = Vote.down;
    } else {
      votes++;
      voteType = Vote.neutre;
    }

    update();
  }

  @override
  void upVote() {
    if (voteType.isDown || voteType.isNeutre) {
      votes++;
      voteType = Vote.up;
    } else {
      votes--;
      voteType = Vote.neutre;
    }

    update();
  }
}
