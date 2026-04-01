import 'package:cv_tech/data/models/job_model.dart';

class JobMatchModel {
  final JobModel job;
  final int matchScore;

  const JobMatchModel({
    required this.job,
    required this.matchScore,
  });

  factory JobMatchModel.fromJson(Map<String, dynamic> json) {
    return JobMatchModel(
      job: JobModel.fromJson(json),
      matchScore: (json['matchScore'] as num?)?.toInt() ?? 0,
    );
  }
}
