import 'package:flutter/material.dart';

import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/data/models/job_model.dart';
import 'package:cv_tech/data/repositories/job_application_repository.dart';
import 'package:cv_tech/data/repositories/job_repository.dart';
import 'package:cv_tech/theme/app_theme.dart';
import 'package:cv_tech/presentation/widgets/common/custom_toast.dart';
import 'package:cv_tech/presentation/views/job/job_swipe_view.dart';

enum _ApplicationFilter { all, pending, interview, accepted, rejected }

class _JobApplicationItem {
  final String applicationId;
  final String? jobId;
  final String jobTitle;
  final String companyName;
  final String location;
  final String contractType;
  final DateTime? appliedAt;
  final DateTime? interviewAt;
  final String status;

  const _JobApplicationItem({
    required this.applicationId,
    required this.jobId,
    required this.jobTitle,
    required this.companyName,
    required this.location,
    required this.contractType,
    required this.appliedAt,
    required this.interviewAt,
    required this.status,
  });
}

class JobsView extends StatefulWidget {
  const JobsView({super.key});

  @override
  State<JobsView> createState() => _JobsViewState();
}

class _JobsViewState extends State<JobsView> {
  final JobApplicationRepository _applicationRepository = JobApplicationRepository();
  final JobRepository _jobRepository = JobRepository();

  List<_JobApplicationItem> _applications = const [];
  bool _loading = true;
  _ApplicationFilter _activeFilter = _ApplicationFilter.all;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    try {
      setState(() => _loading = true);
      final data = await _applicationRepository.getMyApplications(page: 1, limit: 50);
      final mapped = data.map(_mapApplication).toList()
        ..sort((a, b) {
          final aDate = a.appliedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bDate = b.appliedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });

      if (!mounted) return;
      setState(() {
        _applications = mapped;
      });
    } catch (e) {
      if (!mounted) return;
      CustomToast.error(context, 'Chargement des candidatures impossible: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  _JobApplicationItem _mapApplication(Map<String, dynamic> raw) {
    final status = _stringValue(raw['status'], fallback: 'pending').toLowerCase();
    return _JobApplicationItem(
      applicationId: _stringValue(raw['_id'], fallback: ''),
      jobId: _nullableString(raw['jobId']),
      jobTitle: _stringValue(raw['jobTitle'] ?? raw['title'], fallback: 'Offre d\'emploi'),
      companyName: _stringValue(raw['companyName'], fallback: 'Entreprise'),
      location: _stringValue(raw['location'], fallback: 'Non specifie'),
      contractType: _stringValue(raw['contractType'], fallback: '-'),
      appliedAt: _parseDate(raw['appliedAt'] ?? raw['createdAt']),
      interviewAt: _parseInterviewDate(raw['response']) ?? _parseDate(raw['respondedAt']),
      status: status,
    );
  }

  String _stringValue(dynamic value, {required String fallback}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  String? _nullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim());
    }
    if (value is Map && value[r'$date'] is String) {
      return DateTime.tryParse((value[r'$date'] as String).trim());
    }
    return null;
  }

  DateTime? _parseInterviewDate(dynamic responseValue) {
    if (responseValue == null) return null;
    final raw = responseValue.toString().trim();
    if (raw.isEmpty) return null;

    const prefix = 'INTERVIEW_AT:';
    if (raw.startsWith(prefix)) {
      final iso = raw.substring(prefix.length).trim();
      return DateTime.tryParse(iso);
    }

    return DateTime.tryParse(raw);
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    final d = value.day.toString().padLeft(2, '0');
    final m = value.month.toString().padLeft(2, '0');
    final y = value.year;
    return '$d/$m/$y';
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return '-';
    final dd = _formatDate(value);
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$dd a $hh:$mm';
  }

  _ApplicationFilter _statusToFilter(String status) {
    switch (status) {
      case 'accepted':
        return _ApplicationFilter.accepted;
      case 'rejected':
        return _ApplicationFilter.rejected;
      case 'viewed':
      case 'shortlisted':
        return _ApplicationFilter.interview;
      default:
        return _ApplicationFilter.pending;
    }
  }

  List<_JobApplicationItem> get _filteredApplications {
    if (_activeFilter == _ApplicationFilter.all) return _applications;
    return _applications
        .where((a) => _statusToFilter(a.status) == _activeFilter)
        .toList();
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'Acceptee';
      case 'rejected':
        return 'Refusee';
      case 'viewed':
      case 'shortlisted':
        return 'Entretien';
      case 'withdrawn':
        return 'Retiree';
      default:
        return 'En attente';
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'accepted':
        return const Color(0xFFDFF5E6);
      case 'rejected':
        return const Color(0xFFFFE1E1);
      case 'viewed':
      case 'shortlisted':
        return const Color(0xFFE2ECFF);
      default:
        return const Color(0xFFFFF2CC);
    }
  }

  Color _statusFg(String status) {
    switch (status) {
      case 'accepted':
        return const Color(0xFF1B8752);
      case 'rejected':
        return const Color(0xFFC83434);
      case 'viewed':
      case 'shortlisted':
        return const Color(0xFF2F66D0);
      default:
        return const Color(0xFFB98000);
    }
  }

  Future<void> _openJobById(_JobApplicationItem application) async {
    final jobId = application.jobId;
    if (jobId == null || jobId.isEmpty) {
      if (!mounted) return;
      CustomToast.error(context, 'Job ID introuvable pour cette candidature');
      return;
    }

    try {
      final job = await _jobRepository.getById(jobId);
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: AppTheme.cardColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.title,
                style: TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                job.description,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppTheme.textColor, height: 1.4),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Tag(label: job.location),
                  _Tag(label: job.contractType.name),
                  _Tag(label: _statusLabel(job.status.name)),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      CustomToast.error(context, 'GET /jobs/:id impossible: $e');
    }
  }

  Widget _filterChip(String label, _ApplicationFilter filter) {
    final active = _activeFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryColor : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? AppColors.primaryColor : AppTheme.dividerColor,
            width: active ? 1.5 : 1,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppTheme.textColor,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationCard(_JobApplicationItem application) {
    final status = _statusLabel(application.status);
    final showInterview = application.status == 'viewed' || application.status == 'shortlisted';

    return GestureDetector(
      onTap: () => _openJobById(application),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.dividerColor.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top colored accent bar based on status
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: _statusFg(application.status),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryColor.withOpacity(0.15),
                              AppColors.primaryColor.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.work_rounded, color: AppColors.primaryColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              application.jobTitle,
                              style: TextStyle(
                                color: AppTheme.textColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.business_rounded, size: 13, color: AppTheme.textMutedColor),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    application.companyName,
                                    style: TextStyle(
                                      color: AppTheme.textMutedColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _statusBg(application.status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _statusIcon(application.status),
                              size: 12,
                              color: _statusFg(application.status),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              status,
                              style: TextStyle(
                                color: _statusFg(application.status),
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(color: AppTheme.dividerColor.withOpacity(0.5), height: 1),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.location_on_outlined,
                        label: application.location,
                      ),
                      const SizedBox(width: 12),
                      _InfoChip(
                        icon: Icons.description_outlined,
                        label: application.contractType,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 13, color: AppTheme.textMutedColor),
                      const SizedBox(width: 4),
                      Text(
                        'Postulé le ${_formatDate(application.appliedAt)}',
                        style: TextStyle(color: AppTheme.textMutedColor, fontSize: 12),
                      ),
                    ],
                  ),
                  if (showInterview && application.interviewAt != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2ECFF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.videocam_rounded, size: 14, color: Color(0xFF2F66D0)),
                          const SizedBox(width: 6),
                          Text(
                            'Entretien le ${_formatDateTime(application.interviewAt)}',
                            style: const TextStyle(
                              color: Color(0xFF2F66D0),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'viewed':
      case 'shortlisted':
        return Icons.event_rounded;
      case 'withdrawn':
        return Icons.undo_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = _filteredApplications.length;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Mes candidatures'),
        backgroundColor: AppTheme.cardColor,
        foregroundColor: AppTheme.textColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadApplications,
        color: AppColors.primaryColor,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            // ── AI Match Banner ──────────────────────────────
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const JobSwipeView(),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A6CF7), Color(0xFF7B61FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4A6CF7).withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Offres compatibles IA',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Swipez pour découvrir les offres adaptées à votre profil',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // ── End AI Match Banner ───────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('Toutes', _ApplicationFilter.all),
                  const SizedBox(width: 8),
                  _filterChip('En attente', _ApplicationFilter.pending),
                  const SizedBox(width: 8),
                  _filterChip('Entretien', _ApplicationFilter.interview),
                  const SizedBox(width: 8),
                  _filterChip('Acceptées', _ApplicationFilter.accepted),
                  const SizedBox(width: 8),
                  _filterChip('Refusées', _ApplicationFilter.rejected),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (!_loading)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '$count candidature${count > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: AppTheme.textMutedColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            if (_loading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Column(
                  children: [
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Chargement...',
                      style: TextStyle(color: AppTheme.textMutedColor, fontSize: 14),
                    ),
                  ],
                ),
              )
            else if (_filteredApplications.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 50),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppTheme.dividerColor.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.inbox_rounded, size: 32, color: AppTheme.textMutedColor),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune candidature',
                      style: TextStyle(
                        color: AppTheme.textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Aucune candidature dans cette catégorie.',
                      style: TextStyle(color: AppTheme.textMutedColor, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              ..._filteredApplications.map(_buildApplicationCard),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textMutedColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;

  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColors.primaryColor.withOpacity(0.08),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.primaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
