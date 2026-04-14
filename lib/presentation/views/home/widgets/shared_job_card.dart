import 'package:flutter/material.dart';
import 'package:cv_tech/data/models/job_model.dart';

/// LinkedIn-style shared job offer card for the feed
class SharedJobCard extends StatelessWidget {
  final JobModel job;
  final int matchScore;
  final VoidCallback? onApply;
  final VoidCallback? onSave;

  const SharedJobCard({
    super.key,
    required this.job,
    this.matchScore = 0,
    this.onApply,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with match badge
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.business,
                    size: 18,
                    color: Color(0xFF0A66C2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Offre recommandée',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      Text(
                        'Basée sur votre profil',
                        style: TextStyle(
                          fontSize: 9,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                if (matchScore > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0F9),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '$matchScore% match',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF0C447C),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Job details card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0C447C),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _buildSubtitle(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF185FA5),
                  ),
                ),
                const SizedBox(height: 8),
                // Skills chips
                if (job.skills.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: job.skills.take(4).map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          skill,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFF0C447C),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.3),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onApply,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.send, size: 14, color: Color(0xFF0A66C2)),
                        SizedBox(width: 4),
                        Text(
                          'Postuler',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF0A66C2),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 0.5,
                  height: 16,
                  color: Theme.of(context).dividerColor,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: onSave,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bookmark_border, size: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color),
                        const SizedBox(width: 4),
                        Text(
                          'Sauvegarder',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];
    parts.add(_contractLabel(job.contractType));
    if (job.location.isNotEmpty) parts.add(job.location);
    if (job.salaryMin != null && job.salaryMax != null) {
      parts.add('${job.salaryMin!.toInt()}–${job.salaryMax!.toInt()} TND');
    }
    parts.add(_remotePolicyLabel(job.remotePolicy));
    return parts.join(' · ');
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

  String _remotePolicyLabel(RemotePolicy policy) {
    switch (policy) {
      case RemotePolicy.OnSite:
        return 'Sur place';
      case RemotePolicy.Hybrid:
        return 'Hybride';
      case RemotePolicy.FullRemote:
        return 'Full Remote';
    }
  }
}
