import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/data/repositories/job_application_repository.dart';
import 'package:cv_tech/presentation/widgets/common/custom_toast.dart';

/// Screen shown to recruiters: applicants ranked by NLP TF-IDF match score.
class JobRankedCandidatesView extends StatefulWidget {
  final String jobId;
  final String jobTitle;

  const JobRankedCandidatesView({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  @override
  State<JobRankedCandidatesView> createState() =>
      _JobRankedCandidatesViewState();
}

class _JobRankedCandidatesViewState extends State<JobRankedCandidatesView> {
  final _repo = JobApplicationRepository();

  List<Map<String, dynamic>> _candidates = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _repo.getRankedCandidates(jobId: widget.jobId);
      if (!mounted) return;
      setState(() {
        _candidates = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
      CustomToast.error(context, 'Erreur de chargement: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Candidats classés',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              widget.jobTitle,
              style: const TextStyle(
                color: Colors.black45,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryColor,
              ),
            )
          : _error != null
              ? _buildError()
              : _candidates.isEmpty
                  ? _buildEmpty()
                  : _buildList(),
    );
  }

  Widget _buildError() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 56, color: Colors.black26),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Erreur inconnue',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
              ),
            ),
          ],
        ),
      );

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.people_outline, size: 64, color: Colors.black26),
            SizedBox(height: 12),
            Text(
              'Aucun candidat pour cette offre',
              style: TextStyle(color: Colors.black54, fontSize: 15),
            ),
          ],
        ),
      );

  Widget _buildList() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primaryColor,
            onRefresh: _load,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: _candidates.length,
              itemBuilder: (ctx, i) =>
                  _CandidateCard(rank: i + 1, data: _candidates[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final scored = _candidates.where((c) => c['score'] != null).length;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, size: 16, color: AppColors.primaryColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$scored candidat${scored > 1 ? 's' : ''} scoré${scored > 1 ? 's' : ''} par IA · TF-IDF + Cosine',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Candidate card
// ─────────────────────────────────────────────────────────────────

class _CandidateCard extends StatefulWidget {
  final int rank;
  final Map<String, dynamic> data;

  const _CandidateCard({required this.rank, required this.data});

  @override
  State<_CandidateCard> createState() => _CandidateCardState();
}

class _CandidateCardState extends State<_CandidateCard> {
  final _repo = JobApplicationRepository();
  bool _downloading = false;

  Future<void> _downloadCv() async {
    final appId = widget.data['_id']?.toString();
    if (appId == null || appId.isEmpty) return;
    setState(() => _downloading = true);
    try {
      final path = await _repo.downloadApplicationCv(applicationId: appId);
      if (!mounted) return;
      CustomToast.success(context, 'CV téléchargé');
      OpenFilex.open(path);
    } catch (e) {
      if (!mounted) return;
      CustomToast.error(context, 'Erreur: $e');
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _str(widget.data['applicantName'], 'Candidat inconnu');
    final title = _str(widget.data['professionalTitle'], '');
    final status = _str(widget.data['status'], 'pending');
    final score = widget.data['score'] as int?;
    final appliedAt = _parseDate(widget.data['appliedAt']);
    final avatar = widget.data['avatar'] as String?;
    final hasCv = widget.data['cvFileName'] != null &&
        widget.data['cvFileName'].toString().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Rank badge
                _RankBadge(rank: widget.rank),
                const SizedBox(width: 12),
                // Avatar
                _Avatar(url: avatar, name: name),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (title.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black45,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _StatusChip(status: status),
                          if (appliedAt != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              _relativeDate(appliedAt),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black38,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Score badge
                _ScoreBadge(score: score),
              ],
            ),
            // CV download row
            if (hasCv) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: _downloading ? null : _downloadCv,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primaryColor.withOpacity(0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _downloading ? Icons.hourglass_empty : Icons.description_outlined,
                        size: 16,
                        color: AppColors.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _downloading ? 'Téléchargement...' : 'Voir le CV du candidat',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.open_in_new,
                        size: 14,
                        color: AppColors.primaryColor.withOpacity(0.6),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _str(dynamic v, String fallback) {
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  static String _relativeDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'il y a ${diff.inDays}j';
    return '${d.day}/${d.month}/${d.year}';
  }
}

// ─── Score badge ─────────────────────────────────────────────────

class _ScoreBadge extends StatelessWidget {
  final int? score;

  const _ScoreBadge({this.score});

  @override
  Widget build(BuildContext context) {
    if (score == null) {
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            '—',
            style: TextStyle(
              fontSize: 18,
              color: Colors.black38,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    final Color bg;
    final Color fg;
    final Color ring;

    if (score! >= 70) {
      bg = const Color(0xFFEAF7F0);
      fg = const Color(0xFF1D9E75);
      ring = const Color(0xFF1D9E75);
    } else if (score! >= 45) {
      bg = const Color(0xFFFFF3EE);
      fg = AppColors.primaryColor;
      ring = AppColors.primaryColor;
    } else {
      bg = const Color(0xFFFFEBEB);
      fg = const Color(0xFFE24B4A);
      ring = const Color(0xFFE24B4A);
    }

    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ring.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$score',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: fg,
              height: 1.0,
            ),
          ),
          Text(
            '/100',
            style: TextStyle(
              fontSize: 9,
              color: fg.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Rank badge ──────────────────────────────────────────────────

class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    if (rank <= 3) {
      final colors = [
        const Color(0xFFFFD700), // gold
        const Color(0xFFC0C0C0), // silver
        const Color(0xFFCD7F32), // bronze
      ];
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: colors[rank - 1].withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: colors[rank - 1], width: 1.5),
        ),
        child: Center(
          child: Text(
            '#$rank',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: colors[rank - 1],
            ),
          ),
        ),
      );
    }
    return SizedBox(
      width: 28,
      child: Center(
        child: Text(
          '#$rank',
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black38,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─── Avatar ──────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String? url;
  final String name;

  const _Avatar({this.url, required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return CircleAvatar(
      radius: 22,
      backgroundColor: AppColors.primaryColor.withOpacity(0.12),
      backgroundImage: (url != null && url!.isNotEmpty)
          ? NetworkImage(url!)
          : null,
      child: (url == null || url!.isEmpty)
          ? Text(
              initials,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryColor,
              ),
            )
          : null,
    );
  }
}

// ─── Status chip ─────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'pending' => ('En attente', const Color(0xFFF59E0B)),
      'viewed' => ('Vue', const Color(0xFF6366F1)),
      'shortlisted' => ('Sélectionné', const Color(0xFF1D9E75)),
      'accepted' => ('Accepté', const Color(0xFF16A34A)),
      'rejected' => ('Refusé', const Color(0xFFE24B4A)),
      'withdrawn' => ('Retiré', Colors.grey),
      _ => ('En attente', const Color(0xFFF59E0B)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
