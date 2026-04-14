import 'package:flutter/material.dart';
import 'package:cv_tech/data/models/job_model.dart';
import 'package:cv_tech/data/models/job_match_model.dart';

class JobSuggestionsWidget extends StatelessWidget {
  final List<JobMatchModel> jobs;
  final VoidCallback? onSeeAll;
  final void Function(JobMatchModel)? onApply;

  const JobSuggestionsWidget({
    super.key,
    required this.jobs,
    this.onSeeAll,
    this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'OFFRES POUR VOUS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  letterSpacing: 0.5,
                ),
              ),
              GestureDetector(
                onTap: onSeeAll,
                child: const Text(
                  'Voir tout →',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF0A66C2),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Job rows
          ...jobs.take(3).map((match) => _buildJobRow(context, match)),
        ],
      ),
    );
  }

  Widget _buildJobRow(BuildContext context, JobMatchModel match) {
    final job = match.job;
    final matchScore = match.matchScore;

    // Pick logo color based on contract type
    final logoColors = {
      ContractType.CDI: const Color(0xFFE8F0F9),
      ContractType.CDD: const Color(0xFFEAF3DE),
      ContractType.Stage: const Color(0xFFFFF3E0),
      ContractType.Alternance: const Color(0xFFF3E5F5),
      ContractType.Freelance: const Color(0xFFE0F2F1),
    };
    final logoIcons = {
      ContractType.CDI: Icons.business,
      ContractType.CDD: Icons.schedule,
      ContractType.Stage: Icons.school,
      ContractType.Alternance: Icons.autorenew,
      ContractType.Freelance: Icons.laptop_mac,
    };

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Job logo
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: logoColors[job.contractType] ?? const Color(0xFFE8F0F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              logoIcons[job.contractType] ?? Icons.work,
              size: 18,
              color: const Color(0xFF0A66C2),
            ),
          ),
          const SizedBox(width: 10),
          // Job info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  '${_contractLabel(job.contractType)} · ${job.location}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                if (matchScore > 0)
                  Text(
                    '$matchScore% match',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF1D9E75),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Apply button
          GestureDetector(
            onTap: () => onApply?.call(match),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF0A66C2),
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Text(
                'Postuler',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _contractLabel(ContractType type) {
    switch (type) {
      case ContractType.CDI:
        return 'CDI';
      case ContractType.CDD:
        return 'CDD';
      case ContractType.Stage:
        return 'Stage';
      case ContractType.Alternance:
        return 'Alternance';
      case ContractType.Freelance:
        return 'Freelance';
    }
  }
}
