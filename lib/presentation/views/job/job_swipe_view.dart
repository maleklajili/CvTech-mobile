import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/data/models/job_match_model.dart';
import 'package:cv_tech/data/models/job_model.dart';
import 'package:cv_tech/data/repositories/job_match_repository.dart';
import 'package:cv_tech/data/repositories/job_application_repository.dart';
import 'package:cv_tech/presentation/widgets/common/custom_toast.dart';
import 'package:cv_tech/theme/app_theme.dart';

class JobSwipeView extends StatefulWidget {
  const JobSwipeView({super.key});

  @override
  State<JobSwipeView> createState() => _JobSwipeViewState();
}

class _JobSwipeViewState extends State<JobSwipeView>
    with TickerProviderStateMixin {
  final _repo = JobMatchRepository();

  List<JobMatchModel> _cards = [];
  bool _loading = true;
  String? _error;

  final List<JobMatchModel> _accepted = [];
  final List<JobMatchModel> _rejected = [];

  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;

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
      final matches = await _repo.getMatches();
      if (!mounted) return;
      setState(() {
        _cards = matches;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _onPanStart(DragStartDetails _) =>
      setState(() => _isDragging = true);

  void _onPanUpdate(DragUpdateDetails d) =>
      setState(() => _dragOffset += d.delta);

  void _onPanEnd(DragEndDetails _) {
    const threshold = 90.0;
    if (_dragOffset.dx > threshold) {
      _confirmSwipe(right: true);
    } else if (_dragOffset.dx < -threshold) {
      _confirmSwipe(right: false);
    } else {
      setState(() {
        _dragOffset = Offset.zero;
        _isDragging = false;
      });
    }
  }

  Future<void> _confirmSwipe({required bool right}) async {
    if (_cards.isEmpty) return;
    final target = right
        ? const Offset(1200, -200)
        : const Offset(-1200, -200);

    setState(() {
      _dragOffset = target;
      _isDragging = false;
    });

    await Future.delayed(const Duration(milliseconds: 320));
    if (!mounted) return;

    final job = _cards.first;
    setState(() {
      if (right) {
        _accepted.add(job);
      } else {
        _rejected.add(job);
      }
      _cards = _cards.sublist(1);
      _dragOffset = Offset.zero;
    });

    if (right && job.job.id != null) {
      _openApplySheet(job);
    }
    _showSnack(right);
  }

  void _showSnack(bool accepted) {
    if (!mounted) return;
    // Don't show snack for accepted — the apply sheet handles feedback
    if (accepted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.cancel,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            const Text(
              'Offre ignorée',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF6B7280),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ));
  }

  Future<void> _openApplySheet(JobMatchModel match) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SwipeApplySheet(job: match.job),
    );
    if (!mounted) return;
    if (result == true) {
      CustomToast.success(context, 'Candidature envoyée !');
    }
  }

  double get _rotation =>
      (_dragOffset.dx / 420.0).clamp(-0.30, 0.30);

  double get _swipeRatio =>
      (_dragOffset.dx / 130.0).clamp(-1.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.isLight
                    ? const Color(0xFFF1F5F9)
                    : AppColors.darkSurfaceColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textColor),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offres pour moi',
                  style: TextStyle(
                    color: AppTheme.textColor,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Analysé par IA · swipe pour répondre',
                      style: TextStyle(
                        color: AppTheme.textMutedColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.isLight
                  ? const Color(0xFFF1F5F9)
                  : AppColors.darkSurfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 14, color: Color(0xFF22C55E)),
                const SizedBox(width: 4),
                Text(
                  '${_accepted.length}',
                  style: TextStyle(
                    color: AppTheme.textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Container(
                  width: 1,
                  height: 14,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: AppTheme.dividerColor,
                ),
                const Icon(Icons.cancel_rounded,
                    size: 14, color: Color(0xFFEF4444)),
                const SizedBox(width: 4),
                Text(
                  '${_rejected.length}',
                  style: TextStyle(
                    color: AppTheme.textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return _buildLoading();
    if (_error != null) return _buildError();
    if (_cards.isEmpty) return _buildEmpty();
    return Column(
      children: [
        Expanded(child: _buildStack()),
        _buildActionBar(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4A6CF7), Color(0xFF7B61FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4A6CF7).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child:
                const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 38),
          ),
          const SizedBox(height: 24),
          Text(
            'L\'IA analyse votre profil…',
            style: TextStyle(
              color: AppTheme.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Calcul de compatibilité en cours',
            style: TextStyle(color: AppTheme.textMutedColor, fontSize: 14),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3.5,
              color: const Color(0xFF4A6CF7),
              strokeCap: StrokeCap.round,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off,
                  size: 40, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 20),
            Text(
              'Connexion impossible',
              style: TextStyle(
                color: AppTheme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: AppTheme.textMutedColor, fontSize: 13),
            ),
            const SizedBox(height: 24),
            _PrimaryButton(
                label: 'Réessayer', icon: Icons.refresh, onTap: _load),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF16A34A).withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.done_all_rounded,
                size: 48, color: Color(0xFF16A34A)),
          ),
          const SizedBox(height: 24),
          Text(
            'Toutes les offres traitées !',
            style: TextStyle(
              color: AppTheme.textColor,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.isLight
                  ? const Color(0xFFF1F5F9)
                  : AppColors.darkSurfaceColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF22C55E)),
                const SizedBox(width: 4),
                Text(
                  '${_accepted.length} candidatures',
                  style: TextStyle(
                    color: AppTheme.textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.cancel_rounded, size: 14, color: Color(0xFFEF4444)),
                const SizedBox(width: 4),
                Text(
                  '${_rejected.length} ignorées',
                  style: TextStyle(
                    color: AppTheme.textMutedColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _PrimaryButton(
              label: 'Recharger les offres',
              icon: Icons.refresh_rounded,
              onTap: _load),
        ],
      ),
    );
  }

  Widget _buildStack() {
    final count = min(_cards.length, 3);
    return Stack(
      alignment: Alignment.center,
      children: [
        for (int i = count - 1; i >= 1; i--) _BackCard(index: i),
        GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: AnimatedContainer(
            duration: _isDragging
                ? Duration.zero
                : const Duration(milliseconds: 320),
            curve: Curves.easeOutBack,
            transform: Matrix4.identity()
              ..translate(_dragOffset.dx, _dragOffset.dy * 0.3)
              ..rotateZ(_rotation),
            transformAlignment: Alignment.bottomCenter,
            child: Stack(
              children: [
                _JobCard(match: _cards.first),
                if (_swipeRatio > 0.06)
                  _OverlayLabel(
                    label: 'POSTULER',
                    color: const Color(0xFF22C55E),
                    opacity: _swipeRatio,
                    side: true,
                  ),
                if (_swipeRatio < -0.06)
                  _OverlayLabel(
                    label: 'IGNORER',
                    color: const Color(0xFFEF4444),
                    opacity: -_swipeRatio,
                    side: false,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Icons.close_rounded,
            color: const Color(0xFFEF4444),
            size: 56,
            onTap: () => _confirmSwipe(right: false),
            label: 'Ignorer',
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.isLight
                  ? const Color(0xFFF1F5F9)
                  : AppColors.darkSurfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '${_cards.length}',
                  style: TextStyle(
                    color: AppTheme.textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'offre${_cards.length != 1 ? 's' : ''}',
                  style: TextStyle(
                      color: AppTheme.textMutedColor, fontSize: 11),
                ),
              ],
            ),
          ),
          _ActionButton(
            icon: Icons.check_rounded,
            color: const Color(0xFF22C55E),
            size: 56,
            onTap: () => _confirmSwipe(right: true),
            label: 'Postuler',
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────

class _BackCard extends StatelessWidget {
  final int index;
  const _BackCard({required this.index});

  @override
  Widget build(BuildContext context) {
    final scale = 1.0 - index * 0.05;
    final dy = index * 14.0;
    return Transform(
      transform: Matrix4.identity()
        ..translate(0.0, dy)
        ..scale(scale),
      alignment: Alignment.topCenter,
      child: IgnorePointer(
        child: Opacity(
          opacity: 1.0 - index * 0.2,
          child: Container(
            width: MediaQuery.of(context).size.width - 40,
            height: _JobCard.cardHeight(context),
            decoration: BoxDecoration(
              color: AppTheme.isLight
                  ? Colors.white
                  : AppColors.darkSurfaceColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final JobMatchModel match;
  const _JobCard({required this.match});

  static double cardHeight(BuildContext ctx) =>
      MediaQuery.of(ctx).size.height * 0.60;

  @override
  Widget build(BuildContext context) {
    final job = match.job;
    final isDark = !AppTheme.isLight;
    final h = cardHeight(context);

    return Container(
      width: MediaQuery.of(context).size.width - 40,
      height: h,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceColor : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CardHero(score: match.matchScore, job: job),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textColor,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _MetaChip(
                            icon: Icons.location_on_outlined,
                            label: job.location),
                        _MetaChip(
                          icon: Icons.business_center_outlined,
                          label: job.contractType.toString().split('.').last,
                          primary: true,
                        ),
                        _MetaChip(
                            icon: Icons.wifi_outlined,
                            label: _remoteLabel(job.remotePolicy)),
                        if (job.salaryMin != null || job.salaryMax != null)
                          _MetaChip(
                            icon: Icons.euro,
                            label:
                                _salaryShort(job.salaryMin, job.salaryMax),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Divider(
                      color: AppTheme.isLight
                          ? AppColors.dividerColor
                          : AppColors.darkDividerColor,
                      height: 1,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      job.description,
                      style: TextStyle(
                        color: AppTheme.textColor,
                        fontSize: 13,
                        height: 1.6,
                      ),
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (job.skills.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Compétences requises',
                        style: TextStyle(
                          color: AppTheme.textMutedColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: job.skills
                            .take(8)
                            .map((s) => _SkillTag(label: s))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _remoteLabel(RemotePolicy policy) {
    const m = {
      RemotePolicy.OnSite: 'Sur site',
      RemotePolicy.Hybrid: 'Hybride',
      RemotePolicy.FullRemote: 'Full Remote',
    };
    return m[policy] ?? policy.toString();
  }

  String _salaryShort(double? min, double? max) {
    final fmt = NumberFormat.compactCurrency(
        locale: 'fr_FR', symbol: 'DZD', decimalDigits: 0);
    if (min != null && max != null) {
      return '${fmt.format(min)} – ${fmt.format(max)}';
    }
    if (min != null) return 'Dès ${fmt.format(min)}';
    if (max != null) return 'Jusqu\'à ${fmt.format(max!)}';
    return '';
  }
}

// ── Hero band at top of each card ──

class _CardHero extends StatelessWidget {
  final int score;
  final JobModel job;

  const _CardHero({required this.score, required this.job});

  Color get _scoreColor {
    if (score >= 75) return const Color(0xFF22C55E);
    if (score >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A6CF7), Color(0xFF7B61FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: const Icon(Icons.business_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _expLabel(job.experience),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 13,
                        color: Colors.white.withOpacity(0.9)),
                    const SizedBox(width: 5),
                    const Text(
                      'Compatibilité IA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _ScoreRing(score: score, color: _scoreColor),
        ],
      ),
    );
  }

  String _expLabel(ExperienceLevel level) {
    const m = {
      ExperienceLevel.Debutant: 'Débutant',
      ExperienceLevel.OneToThree: '1 – 3 ans',
      ExperienceLevel.ThreeToFive: '3 – 5 ans',
      ExperienceLevel.FivePlus: '5+ ans',
    };
    return m[level] ?? level.toString();
  }
}

class _ScoreRing extends StatelessWidget {
  final int score;
  final Color color;
  const _ScoreRing({required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 58,
            height: 58,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 5,
              backgroundColor: Colors.white.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  height: 1,
                ),
              ),
              const Text(
                '%',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── swipe overlay labels ──

class _OverlayLabel extends StatelessWidget {
  final String label;
  final Color color;
  final double opacity;
  final bool side; // true = left side (postuler), false = right side (ignorer)

  const _OverlayLabel({
    required this.label,
    required this.color,
    required this.opacity,
    required this.side,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: color.withOpacity(0.06 * opacity.clamp(0.0, 1.0)),
        ),
        child: Align(
          alignment: side ? Alignment.topLeft : Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Transform.rotate(
                angle: side ? -0.2 : 0.2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: color, width: 3.5),
                    borderRadius: BorderRadius.circular(12),
                    color: color.withOpacity(0.12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        side ? Icons.check_rounded : Icons.close_rounded,
                        color: color,
                        size: 22,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── action button ──

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;
  final String label;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.10),
              border:
                  Border.all(color: color.withOpacity(0.4), width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: size * 0.46),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── chips ──

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;

  const _MetaChip({
    required this.icon,
    required this.label,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = primary
        ? AppColors.primaryColor.withOpacity(0.10)
        : (AppTheme.isLight
            ? const Color(0xFFF1F5F9)
            : AppColors.darkDividerColor);
    final fg = primary ? AppColors.primaryColor : AppTheme.textMutedColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                color: fg, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _SkillTag extends StatelessWidget {
  final String label;
  const _SkillTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withOpacity(0.09),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: const Color(0xFF3B82F6).withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF2563EB),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── primary button ──

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4A6CF7), Color(0xFF7B61FF)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A6CF7).withOpacity(0.3),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Apply bottom sheet after swipe match ──

class _SwipeApplySheet extends StatefulWidget {
  final JobModel job;
  const _SwipeApplySheet({required this.job});

  @override
  State<_SwipeApplySheet> createState() => _SwipeApplySheetState();
}

class _SwipeApplySheetState extends State<_SwipeApplySheet> {
  final _formKey = GlobalKey<FormState>();
  final _motivationController = TextEditingController();
  final _appRepo = JobApplicationRepository();
  PlatformFile? _cvFile;
  bool _submitting = false;

  @override
  void dispose() {
    _motivationController.dispose();
    super.dispose();
  }

  Future<void> _pickCvFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx'],
      allowMultiple: false,
      withData: true,
    );
    if (!mounted || result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final ext = file.extension?.toLowerCase();
    if (ext != 'pdf' && ext != 'doc' && ext != 'docx') {
      CustomToast.warning(context, 'Format non supporté. Utilisez PDF, DOC ou DOCX.');
      return;
    }
    if (file.size > 5 * 1024 * 1024) {
      CustomToast.warning(context, 'Le fichier ne doit pas dépasser 5 Mo.');
      return;
    }
    setState(() => _cvFile = file);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cvFile == null) {
      CustomToast.warning(context, 'Veuillez joindre votre CV.');
      return;
    }

    setState(() => _submitting = true);
    try {
      await _appRepo.applyForJob(
        jobId: widget.job.id ?? '',
        coverLetter: _motivationController.text.trim(),
        cvBytes: _cvFile!.bytes,
        cvFileName: _cvFile!.name,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      CustomToast.error(context, 'Erreur : $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4A6CF7), Color(0xFF7B61FF)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Postuler',
                          style: TextStyle(
                            color: AppTheme.textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.job.title,
                          style: TextStyle(
                            color: AppTheme.textMutedColor,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _motivationController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Lettre de motivation *',
                  hintText: 'Expliquez pourquoi vous êtes le candidat idéal...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppTheme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primaryColor, width: 1.5),
                  ),
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: AppTheme.isLight
                      ? const Color(0xFFF8FAFC)
                      : AppColors.darkSurfaceColor,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Champ obligatoire';
                  if (v.trim().length < 30) return 'Minimum 30 caractères';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickCvFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _cvFile != null
                          ? const Color(0xFF22C55E)
                          : AppTheme.dividerColor,
                      width: _cvFile != null ? 1.5 : 1,
                    ),
                    color: _cvFile != null
                        ? const Color(0xFFF0FDF4)
                        : (AppTheme.isLight
                            ? const Color(0xFFF8FAFC)
                            : AppColors.darkSurfaceColor),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _cvFile != null ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                        color: _cvFile != null
                            ? const Color(0xFF22C55E)
                            : AppTheme.textMutedColor,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _cvFile != null ? _cvFile!.name : 'Joindre votre CV',
                              style: TextStyle(
                                color: _cvFile != null
                                    ? AppTheme.textColor
                                    : AppTheme.textMutedColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_cvFile == null)
                              Text(
                                'PDF, DOC ou DOCX • Max 5 Mo',
                                style: TextStyle(
                                  color: AppTheme.textMutedColor,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (_cvFile != null)
                        GestureDetector(
                          onTap: () => setState(() => _cvFile = null),
                          child: Icon(Icons.close_rounded,
                              size: 18, color: AppTheme.textMutedColor),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: AppTheme.dividerColor),
                      ),
                      child: Text(
                        'Annuler',
                        style: TextStyle(
                          color: AppTheme.textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Envoyer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

