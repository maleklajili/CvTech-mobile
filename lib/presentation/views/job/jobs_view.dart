import 'package:flutter/material.dart';

import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/data/models/job_model.dart';
import 'package:cv_tech/data/repositories/job_application_repository.dart';
import 'package:cv_tech/data/repositories/job_repository.dart';
import 'package:cv_tech/theme/app_theme.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chargement des candidatures impossible: $e')),
      );
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
      interviewAt: _parseDate(raw['respondedAt']),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job ID introuvable pour cette candidature')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('GET /jobs/:id impossible: $e')),
      );
    }
  }

  Widget _filterChip(String label, _ApplicationFilter filter) {
    final active = _activeFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryColor : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? AppColors.primaryColor : AppTheme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppTheme.textColor,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationCard(_JobApplicationItem application) {
    final status = _statusLabel(application.status);
    final showInterview = application.status == 'viewed' || application.status == 'shortlisted';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0xFFE7F1FF),
                ),
                child: Icon(Icons.work_outline, color: AppColors.primaryColor),
              ),
              const SizedBox(width: 10),
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
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.business, size: 13, color: AppTheme.textMutedColor),
                        const SizedBox(width: 4),
                        Text(
                          application.companyName,
                          style: TextStyle(color: AppTheme.textMutedColor, fontSize: 12),
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
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: _statusFg(application.status),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textMutedColor),
              const SizedBox(width: 4),
              Text(application.location, style: TextStyle(color: AppTheme.textColor, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textMutedColor),
              const SizedBox(width: 4),
              Text(
                'Candidature envoyee le ${_formatDate(application.appliedAt)}',
                style: TextStyle(color: AppTheme.textColor, fontSize: 12),
              ),
              const Spacer(),
              _Tag(label: application.contractType),
            ],
          ),
          if (showInterview && application.interviewAt != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: AppTheme.textMutedColor),
                const SizedBox(width: 4),
                Text(
                  'Entretien le ${_formatDateTime(application.interviewAt)}',
                  style: TextStyle(color: AppTheme.textColor, fontSize: 12),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: () => _openJobById(application),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Voir les details'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes candidatures'),
        backgroundColor: AppTheme.cardColor,
        foregroundColor: AppTheme.textColor,
      ),
      body: RefreshIndicator(
        onRefresh: _loadApplications,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Suivez l\'etat de vos candidatures aux offres d\'emploi',
              style: TextStyle(color: AppTheme.textMutedColor),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _filterChip('Toutes', _ApplicationFilter.all),
                _filterChip('En attente', _ApplicationFilter.pending),
                _filterChip('Entretien', _ApplicationFilter.interview),
                _filterChip('Acceptees', _ApplicationFilter.accepted),
                _filterChip('Refusees', _ApplicationFilter.rejected),
              ],
            ),
            const SizedBox(height: 14),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_filteredApplications.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: Text(
                  'Aucune candidature dans cette categorie.',
                  style: TextStyle(color: AppTheme.textMutedColor),
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

class _Tag extends StatelessWidget {
  final String label;

  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppTheme.textMutedColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
