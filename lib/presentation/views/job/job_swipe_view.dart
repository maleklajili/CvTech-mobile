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

// ── Theme colors (matching HTML mockup) ──
const _kBlue = Color(0xFFF26E22);       // orange primary
const _kBlueDark = Color(0xFFBF4F0A);   // dark orange
const _kBlueLight = Color(0xFFFFF3EE);  // light orange bg
const _kBlueSoft = Color(0xFFFFB085);   // soft orange
const _kBluePale = Color(0xFFFFD0AB);   // pale orange
const _kGreen = Color(0xFF1D9E75);
const _kGreenLight = Color(0xFF9FE1CB);
const _kGreenBg = Color(0xFFEAF3DE);
const _kRed = Color(0xFFE24B4A);
const _kPurple = Color(0xFF7F77DD);
const _kPurpleBg = Color(0xFFEEEDFE);

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
  int _tabIndex = 0;

  final List<JobMatchModel> _accepted = [];
  final List<JobMatchModel> _rejected = [];
  final List<JobMatchModel> _saved = [];

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

  void _saveJob() {
    if (_cards.isEmpty) return;
    setState(() {
      _saved.add(_cards.first);
      _cards = _cards.sublist(1);
    });
    CustomToast.success(context, 'Offre sauvegardée');
  }

  void _showSnack(bool accepted) {
    if (!mounted) return;
    if (accepted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Offre ignorée', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: const Color(0xFF6B7280),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
            _buildTabs(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.isLight ? const Color(0xFFF1F5F9) : AppColors.darkSurfaceColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textColor),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trouver un job',
                    style: TextStyle(
                      color: AppTheme.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    )),
                const SizedBox(height: 2),
                Text('${_cards.length} offres correspondent',
                    style: TextStyle(
                      color: AppTheme.textMutedColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    )),
              ],
            ),
          ),
          Stack(
            children: [
              Icon(Icons.notifications_outlined, size: 22, color: AppTheme.textMutedColor),
              if (_accepted.isNotEmpty)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: _kRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    const tabs = ['Pour vous', 'Récents', 'Sauvegardés'];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = _tabIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = i),
              child: Container(
                margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: active ? _kBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: active ? null : Border.all(color: AppTheme.dividerColor),
                ),
                alignment: Alignment.center,
                child: Text(tabs[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                      color: active ? Colors.white : AppTheme.textMutedColor,
                    )),
              ),
            ),
          );
        }),
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
        const SizedBox(height: 12),
        if (_cards.length > 1) _buildMiniCards(),
        const SizedBox(height: 16),
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
                colors: [_kBlue, _kBlueSoft],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _kBlue.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 38),
          ),
          const SizedBox(height: 24),
          Text('L\'IA analyse votre profil…',
              style: TextStyle(
                color: AppTheme.textColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 8),
          Text('Calcul de compatibilité en cours',
              style: TextStyle(color: AppTheme.textMutedColor, fontSize: 14)),
          const SizedBox(height: 28),
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3.5,
              color: _kBlue,
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
              decoration: const BoxDecoration(color: Color(0xFFFEF2F2), shape: BoxShape.circle),
              child: const Icon(Icons.wifi_off, size: 40, color: _kRed),
            ),
            const SizedBox(height: 20),
            Text('Connexion impossible',
                style: TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMutedColor, fontSize: 13)),
            const SizedBox(height: 24),
            _buildPrimaryBtn('Réessayer', Icons.refresh, _load),
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
                  color: _kGreen.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.done_all_rounded, size: 48, color: _kGreen),
          ),
          const SizedBox(height: 24),
          Text('Toutes les offres traitées !',
              style: TextStyle(
                color: AppTheme.textColor,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.isLight ? const Color(0xFFF1F5F9) : AppColors.darkSurfaceColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF22C55E)),
                const SizedBox(width: 4),
                Text('${_accepted.length} candidatures',
                    style: TextStyle(color: AppTheme.textColor, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(width: 10),
                const Icon(Icons.cancel_rounded, size: 14, color: _kRed),
                const SizedBox(width: 4),
                Text('${_rejected.length} ignorées',
                    style: TextStyle(color: AppTheme.textMutedColor, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _buildPrimaryBtn('Recharger les offres', Icons.refresh_rounded, _load),
        ],
      ),
    );
  }

  Widget _buildStack() {
    final count = min(_cards.length, 3);
    return Stack(
      alignment: Alignment.center,
      children: [
        for (int i = count - 1; i >= 1; i--) _BackCard(index: i, cards: _cards),
        GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: AnimatedContainer(
            duration: _isDragging ? Duration.zero : const Duration(milliseconds: 320),
            curve: Curves.easeOutBack,
            transform: Matrix4.identity()
              ..translate(_dragOffset.dx, _dragOffset.dy * 0.3)
              ..rotateZ(_rotation),
            transformAlignment: Alignment.bottomCenter,
            child: Stack(
              children: [
                _JobCard(match: _cards.first),
                if (_swipeRatio > 0.06)
                  _OverlayBadge(
                    label: 'POSTULER',
                    color: _kGreen,
                    opacity: _swipeRatio,
                    left: true,
                  ),
                if (_swipeRatio < -0.06)
                  _OverlayBadge(
                    label: 'IGNORER',
                    color: _kRed,
                    opacity: -_swipeRatio,
                    left: false,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CircleAction(
          icon: Icons.close_rounded,
          color: _kRed,
          bg: const Color(0xFFFCEBEB),
          size: 48,
          onTap: () => _confirmSwipe(right: false),
        ),
        const SizedBox(width: 16),
        _CircleAction(
          icon: Icons.info_outline_rounded,
          color: _kBlue,
          bg: _kBlueLight,
          size: 48,
          onTap: () {
            if (_cards.isNotEmpty) _openJobDetail(_cards.first);
          },
        ),
        const SizedBox(width: 16),
        _CircleAction(
          icon: Icons.star_rounded,
          color: _kPurple,
          bg: _kPurpleBg,
          size: 48,
          onTap: _saveJob,
        ),
        const SizedBox(width: 16),
        _CircleAction(
          icon: Icons.favorite_rounded,
          color: const Color(0xFF639922),
          bg: _kGreenBg,
          size: 48,
          onTap: () => _confirmSwipe(right: true),
        ),
      ],
    );
  }

  Widget _buildMiniCards() {
    final upcoming = _cards.skip(1).take(2).toList();
    if (upcoming.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Aussi pour vous',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMutedColor,
              )),
          const SizedBox(height: 6),
          Row(
            children: upcoming.map((m) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: m != upcoming.last ? 8 : 0),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.dividerColor, width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.job.location,
                          style: TextStyle(fontSize: 9, color: AppTheme.textMutedColor)),
                      const SizedBox(height: 2),
                      Text(m.job.title,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('${m.matchScore}% match',
                          style: const TextStyle(
                            fontSize: 10,
                            color: _kGreen,
                            fontWeight: FontWeight.w600,
                          )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryBtn(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [_kBlue, _kBlue.withOpacity(0.75)]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: _kBlue.withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 5)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  void _openJobDetail(JobMatchModel match) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _JobDetailSheet(match: match),
    );
  }
}

// ──────────────────────────────────────────────

class _BackCard extends StatelessWidget {
  final int index;
  final List<JobMatchModel> cards;
  const _BackCard({required this.index, required this.cards});

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
            width: MediaQuery.of(context).size.width - 52,
            height: _JobCard.cardHeight(context),
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: index == 1 ? _kBlueLight : _kBluePale,
              borderRadius: BorderRadius.circular(18),
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
      MediaQuery.of(ctx).size.height * 0.52;

  @override
  Widget build(BuildContext context) {
    final job = match.job;
    final h = cardHeight(context);

    return Container(
      width: MediaQuery.of(context).size.width - 52,
      height: h,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kBlue, _kBlueDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _kBlue.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company logo
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.business_rounded, color: _kBlue, size: 22),
              ),
              const SizedBox(height: 12),

              // Job title
              Text(job.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  )),
              const SizedBox(height: 4),

              // Location · Contract
              Text(
                '${job.location} · ${_contractLabel(job.contractType)}',
                style: const TextStyle(fontSize: 12, color: _kBlueSoft),
              ),
              const SizedBox(height: 12),

              // Tags
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ...job.skills.take(3).map((s) => _whiteTag(s)),
                  if (job.remotePolicy != RemotePolicy.OnSite)
                    _whiteTag(_remoteLabel(job.remotePolicy)),
                  if (job.salaryMin != null || job.salaryMax != null)
                    _whiteTag(_salaryShort(job.salaryMin, job.salaryMax)),
                ],
              ),

              const Spacer(),

              // Description
              Text(job.description,
                  style: const TextStyle(fontSize: 11, color: Colors.white70, height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),

              const SizedBox(height: 12),

              // Match bar
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: FractionallySizedBox(
                  widthFactor: match.matchScore / 100,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _kGreen,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Match label
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Compatibilité CV', style: TextStyle(fontSize: 10, color: _kBlueSoft)),
                  Text('${match.matchScore}% match',
                      style: const TextStyle(fontSize: 10, color: _kGreenLight, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _whiteTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(text, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500)),
    );
  }

  String _contractLabel(ContractType ct) {
    const m = {
      ContractType.CDI: 'CDI',
      ContractType.CDD: 'CDD',
      ContractType.Stage: 'Stage',
      ContractType.Alternance: 'Alternance',
      ContractType.Freelance: 'Freelance',
    };
    return m[ct] ?? ct.toString();
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
    final fmt = NumberFormat.compactCurrency(locale: 'fr_FR', symbol: 'TND', decimalDigits: 0);
    if (min != null && max != null) return '${fmt.format(min)} – ${fmt.format(max)}';
    if (min != null) return 'Dès ${fmt.format(min)}';
    if (max != null) return 'Jusqu\'à ${fmt.format(max)}';
    return '';
  }
}

// ── Overlay badge (POSTULER / IGNORER) ──

class _OverlayBadge extends StatelessWidget {
  final String label;
  final Color color;
  final double opacity;
  final bool left;
  const _OverlayBadge({required this.label, required this.color, required this.opacity, required this.left});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      left: left ? 30 : null,
      right: left ? null : 30,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: left ? -0.25 : 0.25,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Text(label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                )),
          ),
        ),
      ),
    );
  }
}

// ── Circle action button ──

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final double size;
  final VoidCallback onTap;
  const _CircleAction({required this.icon, required this.color, required this.bg, required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bg,
          border: Border.all(color: AppTheme.dividerColor, width: 0.5),
        ),
        child: Icon(icon, color: color, size: size * 0.42),
      ),
    );
  }
}

// ── Job detail bottom sheet ──

class _JobDetailSheet extends StatelessWidget {
  final JobMatchModel match;
  const _JobDetailSheet({required this.match});

  @override
  Widget build(BuildContext context) {
    final job = match.job;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.dividerColor, borderRadius: BorderRadius.circular(2))),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _kBlueLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.business_rounded, color: _kBlue, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(job.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textColor)),
                            const SizedBox(height: 2),
                            Text('${job.location} · ${job.contractType.toString().split('.').last}',
                                style: TextStyle(fontSize: 12, color: AppTheme.textMutedColor)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _kGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${match.matchScore}%',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _kGreen)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(job.description, style: TextStyle(fontSize: 13, height: 1.6, color: AppTheme.textColor)),
                  if (job.skills.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('Compétences requises',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMutedColor)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: job.skills.map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _kBlueLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(s, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kBlueDark)),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
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
                  decoration: BoxDecoration(color: AppTheme.dividerColor, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [_kBlue, _kBlue.withOpacity(0.75)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Postuler',
                            style: TextStyle(color: AppTheme.textColor, fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(widget.job.title,
                            style: TextStyle(color: AppTheme.textMutedColor, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
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
                    borderSide: const BorderSide(color: _kBlue, width: 1.5),
                  ),
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: AppTheme.isLight ? const Color(0xFFF8FAFC) : AppColors.darkSurfaceColor,
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
                      color: _cvFile != null ? _kGreen : AppTheme.dividerColor,
                      width: _cvFile != null ? 1.5 : 1,
                    ),
                    color: _cvFile != null
                        ? const Color(0xFFF0FDF4)
                        : (AppTheme.isLight ? const Color(0xFFF8FAFC) : AppColors.darkSurfaceColor),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _cvFile != null ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                        color: _cvFile != null ? _kGreen : AppTheme.textMutedColor,
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
                                color: _cvFile != null ? AppTheme.textColor : AppTheme.textMutedColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_cvFile == null)
                              Text('PDF, DOC ou DOCX - Max 5 Mo',
                                  style: TextStyle(color: AppTheme.textMutedColor, fontSize: 11)),
                          ],
                        ),
                      ),
                      if (_cvFile != null)
                        GestureDetector(
                          onTap: () => setState(() => _cvFile = null),
                          child: Icon(Icons.close_rounded, size: 18, color: AppTheme.textMutedColor),
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
                      child: Text('Annuler',
                          style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
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

