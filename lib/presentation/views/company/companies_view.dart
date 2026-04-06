import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cv_tech/core/constants/app_colors.dart';
import 'package:cv_tech/core/utils/image_url_helper.dart';
import 'package:cv_tech/data/api/api_client.dart';
import 'package:cv_tech/data/models/company_model.dart';
import 'package:cv_tech/data/models/job_model.dart';
import 'package:cv_tech/data/repositories/company_repository.dart';
import 'package:cv_tech/data/repositories/job_application_repository.dart';
import 'package:cv_tech/data/repositories/job_repository.dart';
import 'package:cv_tech/data/repositories/user_repository.dart';
import 'package:cv_tech/theme/app_theme.dart';
import 'package:cv_tech/core/l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:cv_tech/presentation/widgets/common/custom_toast.dart';
import 'package:cv_tech/presentation/widgets/common/custom_alert_dialog.dart';

// ─────────────────────────────────────────────
// CONSTANTES CATEGORIES
// ─────────────────────────────────────────────
const List<String> _kMoreCategories = [
  'Services',
  'Commerce',
  'Startups',
  'Environnement',
  'Divertissement',
  'Automobile',
  'International',
  'Medias',
  'Alimentation',
  'Immobilier',
  'Creation',
  'Ressources Humaines',
  'Luxe',
  'Telecommunications',
  'Tourisme',
  'Construction',
  'Logistique',
];

// ─────────────────────────────────────────────
// VUE PRINCIPALE
// ─────────────────────────────────────────────
class CompaniesView extends StatefulWidget {
  const CompaniesView({super.key});

  @override
  State<CompaniesView> createState() => _CompaniesViewState();
}

class _CompaniesViewState extends State<CompaniesView> {
  final CompanyRepository _repository = CompanyRepository();
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _listScrollController = ScrollController();

  List<CompanyModel> _companies = const [];
  bool _loading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _page = 1;
  final int _limit = 8;
  String _currentUserId = '';

  String _activeSection = 'Pages entreprises';
  String _activeCategory = 'Toutes';
  String _activeMineFilter = 'Toutes';
  String _activeSort = 'Populaires';
  bool _showInlineCreateButton = true;

  static const List<String> _sections = [
    'Pages entreprises',
    'Mes entreprises',
  ];

  static const List<String> _categories = [
    'Toutes',
    'Technologie',
    'Design',
    'Finance',
    'Marketing',
    'Sante',
    'Education',
    'Industrie',
  ];

  static const List<String> _mineFilters = [
    'Toutes',
    'Actives',
    'Brouillons',
    'Verifiees',
    'En attente',
  ];

  static const List<String> _sortOptions = [
    'Populaires',
    'Plus recentes',
    'Alphabetique',
  ];

  @override
  void initState() {
    super.initState();
    _listScrollController.addListener(_handleListScroll);
    _init();
  }

  @override
  void dispose() {
    _listScrollController
      ..removeListener(_handleListScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleListScroll() {
    final shouldShowInline = !_listScrollController.hasClients ||
        _listScrollController.offset <= 8;
    if (shouldShowInline == _showInlineCreateButton) return;
    if (!mounted) return;
    setState(() {
      _showInlineCreateButton = shouldShowInline;
    });
  }

  Future<void> _init() async {
    final userId = await _apiClient.getUserId() ?? '';
    if (!mounted) return;
    setState(() => _currentUserId = userId);
    await _loadCompanies(reset: true);
  }

  Future<void> _loadCompanies({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
        _error = null;
      });
    }

    try {
      final nextPage = reset ? 1 : _page + 1;
      final data = await _repository.getAll(page: nextPage, limit: _limit);
      if (!mounted) return;
      setState(() {
        _companies = reset ? data : [..._companies, ...data];
        _page = nextPage;
        _loading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _isLoadingMore = false;
      });
    }
  }

  // ── Filtres ──────────────────────────────────

  List<CompanyModel> get _searchFilteredCompanies {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _companies;
    return _companies.where((c) {
      return c.name.toLowerCase().contains(query) ||
          c.industry.toLowerCase().contains(query) ||
          (c.location ?? '').toLowerCase().contains(query);
    }).toList();
  }

  List<CompanyModel> get _exploreCompanies {
    final source = List<CompanyModel>.from(_searchFilteredCompanies);

    final filtered = _activeCategory == 'Toutes'
        ? source
        : source.where((company) {
            final ind = company.industry.toLowerCase();
            final cat = _activeCategory.toLowerCase();
            if (cat == 'technologie') {
              return ind.contains('tech') || ind.contains('informat') || ind.contains('software');
            }
            if (cat == 'design') return ind.contains('design') || ind.contains('ui');
            if (cat == 'finance') return ind.contains('finance') || ind.contains('banque');
            if (cat == 'marketing') return ind.contains('marketing') || ind.contains('media');
            if (cat == 'sante') return ind.contains('sante') || ind.contains('health');
            if (cat == 'education') return ind.contains('education') || ind.contains('edtech');
            if (cat == 'industrie') return ind.contains('industrie') || ind.contains('manufact');
            return ind.contains(cat);
          }).toList();

    filtered.sort((a, b) {
      if (_activeSort == 'Plus recentes') {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      }
      if (_activeSort == 'Alphabetique') {
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      final aScore = (a.stats.followers * 3) + a.stats.views;
      final bScore = (b.stats.followers * 3) + b.stats.views;
      return bScore.compareTo(aScore);
    });

    return filtered;
  }

  List<CompanyModel> get _myCompanies {
    final mine = _searchFilteredCompanies
        .where((c) => _currentUserId.isNotEmpty && c.userId == _currentUserId)
        .toList();

    switch (_activeMineFilter) {
      case 'Actives':
        return mine.where((c) => c.status == CompanyStatus.active).toList();
      case 'Brouillons':
        return mine.where((c) => c.status == CompanyStatus.draft).toList();
      case 'Verifiees':
        return mine
            .where((c) =>
                c.verified || c.verificationStatus == VerificationStatus.verified)
            .toList();
      case 'En attente':
        return mine
            .where((c) =>
                c.verificationStatus == VerificationStatus.pending ||
                c.verificationStatus == VerificationStatus.notRequested)
            .toList();
      default:
        return mine;
    }
  }

  CompanyStats get _aggregatedStats {
    int views = 0, followers = 0, applications = 0, messages = 0;
    for (final c in _exploreCompanies) {
      views += c.stats.views;
      followers += c.stats.followers;
      applications += c.stats.jobApplications;
      messages += c.stats.messages;
    }
    return CompanyStats(
      views: views,
      followers: followers,
      jobApplications: applications,
      messages: messages,
    );
  }

  // ── Navigation ───────────────────────────────

  Future<void> _openCreate() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const CompanyFormView(),
        settings: const RouteSettings(name: '/companies/create'),
      ),
    );
    if (!mounted) return;
    if (created == true) await _loadCompanies(reset: true);
  }

  Future<void> _openDetails(CompanyModel company) async {
    final id = company.id;
    if (id == null || id.isEmpty) {
      if (!mounted) return;
      CustomToast.error(context, 'Entreprise invalide: identifiant manquant');
      return;
    }
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CompanyDetailView(companyId: id),
        settings: const RouteSettings(name: '/companies/detail'),
      ),
    );
    if (!mounted) return;
    if (changed == true) await _loadCompanies(reset: true);
  }

  Future<void> _openEdit(CompanyModel company) async {
    if (company.id == null || company.id!.isEmpty) {
      if (!mounted) return;
      CustomToast.error(context, 'Entreprise invalide: identifiant manquant');
      return;
    }
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CompanyFormView(initial: company),
        settings: const RouteSettings(name: '/companies/edit'),
      ),
    );
    if (!mounted) return;
    if (updated == true) await _loadCompanies(reset: true);
  }

  Future<void> _delete(CompanyModel company) async {
    final id = company.id;
    if (id == null || id.isEmpty) {
      if (!mounted) return;
      CustomToast.error(context, AppLocalizations.of(context).invalidCompany);
      return;
    }
    final confirm = await CustomAlertDialog.showConfirmation(
      context: context,
      title: AppLocalizations.of(context).deleteCompanyPage,
      message: AppLocalizations.of(context).confirmDeletion(company.name ?? ''),
      confirmText: AppLocalizations.of(context).delete,
      isDangerous: true,
    );
    if (!mounted) return;
    if (!confirm) return;
    try {
      await _repository.delete(id);
      if (!mounted) return;
      CustomToast.success(context, AppLocalizations.of(context).companyDeleted);
      await _loadCompanies(reset: true);
    } catch (e) {
      if (!mounted) return;
      CustomToast.error(context, '${AppLocalizations.of(context).deletionFailed}: $e');
    }
  }

  // ── Helpers ──────────────────────────────────

  String _verificationLabel(CompanyModel company) {
    if (company.verified ||
        company.verificationStatus == VerificationStatus.verified) {
      return 'Verifiee';
    }
    switch (company.verificationStatus) {
      case VerificationStatus.pending:
        return 'En attente';
      case VerificationStatus.rejected:
        return 'Refusee';
      case VerificationStatus.notRequested:
        return 'Non demandee';
      case VerificationStatus.verified:
        return 'Verifiee';
    }
  }

  Color _verificationColor(CompanyModel company) {
    final label = _verificationLabel(company);
    if (label == 'Verifiee') return const Color(0xFF2E7D32);
    if (label == 'En attente') return const Color(0xFFF57C00);
    if (label == 'Refusee') return const Color(0xFFC62828);
    return AppTheme.textMutedColor;
  }

  // ── Widgets communs ──────────────────────────

  Widget _buildSectionSwitcher() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _sections.map((section) {
          final selected = _activeSection == section;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(section),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _activeSection = section;
                  _showInlineCreateButton = true;
                });
                if (_listScrollController.hasClients) {
                  _listScrollController.jumpTo(0);
                }
              },
              selectedColor: AppColors.primaryColor,
              backgroundColor: AppTheme.cardColor,
              labelStyle: TextStyle(
                color: selected ? Colors.white : AppTheme.textColor,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color:
                      selected ? AppColors.primaryColor : AppTheme.dividerColor,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchField({Color? fillColor}) {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      style: TextStyle(
        color: fillColor != null ? Colors.white : AppTheme.textColor,
      ),
      decoration: InputDecoration(
        hintText: 'Rechercher une entreprise...',
        hintStyle: TextStyle(
          color: fillColor != null
              ? Colors.white.withValues(alpha: 0.7)
              : AppTheme.textMutedColor,
        ),
        filled: fillColor != null,
        fillColor: fillColor,
        prefixIcon: Icon(
          Icons.search,
          color: fillColor != null
              ? Colors.white.withValues(alpha: 0.8)
              : AppTheme.textMutedColor,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: fillColor != null
                ? Colors.transparent
                : AppTheme.dividerColor,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: fillColor != null
                ? Colors.white.withValues(alpha: 0.3)
                : AppTheme.dividerColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: fillColor != null
                ? Colors.white
                : AppColors.primaryColor,
            width: 2,
          ),
        ),
      ),
    );
  }

  // ── Vue Explore ──────────────────────────────

  Widget _buildExploreView() {
    final stats = _aggregatedStats;
    final companies = _exploreCompanies;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6A00),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Developpez votre reseau professionnel',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Suivez des entreprises pour recevoir leurs actualites, offres et evenements.',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
              const SizedBox(height: 12),
              _buildSearchField(fillColor: const Color(0xFFFF7B24)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Mini stats
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MiniStatCard(
              icon: Icons.apartment,
              title: 'Entreprises',
              value: '${companies.length}',
            ),
            _MiniStatCard(
              icon: Icons.group_outlined,
              title: 'Abonnes',
              value: '${stats.followers}',
            ),
            _MiniStatCard(
              icon: Icons.work_outline,
              title: 'Candidatures',
              value: '${stats.jobApplications}',
            ),
            _MiniStatCard(
              icon: Icons.remove_red_eye_outlined,
              title: 'Vues',
              value: '${stats.views}',
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Filtres catégories + bouton "+ Plus"
        _CategoryFilterRow(
          categories: _categories,
          activeCategory: _activeCategory,
          onSelect: (cat) => setState(() => _activeCategory = cat),
        ),
        const SizedBox(height: 10),

        // Résultats + tri
        Row(
          children: [
            Text(
              '${companies.length} entreprise${companies.length > 1 ? 's' : ''} trouvee${companies.length > 1 ? 's' : ''}',
              style: TextStyle(color: AppTheme.textMutedColor, fontSize: 13),
            ),
            const Spacer(),
            PopupMenuButton<String>(
              onSelected: (value) => setState(() => _activeSort = value),
              itemBuilder: (_) => _sortOptions
                  .map((opt) => PopupMenuItem<String>(
                        value: opt,
                        child: Text(opt),
                      ))
                  .toList(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Trier: $_activeSort',
                      style: TextStyle(fontSize: 13, color: AppTheme.textColor),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down,
                        size: 16, color: AppTheme.textMutedColor),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Cards
        if (companies.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: Text('Aucune entreprise trouvee')),
          )
        else
          ...companies.map(
            (company) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CompanyCard(
                company: company,
                onTap: () => _openDetails(company),
              ),
            ),
          ),
      ],
    );
  }

  // ── Vue Mes entreprises ───────────────────────

  Widget _buildMyCompaniesView({required bool showCreateButton}) {
    final companies = _myCompanies;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mes entreprises',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gerez vos pages entreprises et suivez leurs performances',
                    style: TextStyle(color: AppTheme.textMutedColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (showCreateButton)
              ElevatedButton.icon(
                onPressed: _openCreate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Creer une page'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSearchField(),
        const SizedBox(height: 12),

        // Filtres statut
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _mineFilters.map((filter) {
              final selected = _activeMineFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _activeMineFilter = filter),
                  selectedColor: AppColors.primaryColor,
                  backgroundColor: AppTheme.cardColor,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppTheme.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: selected
                          ? AppColors.primaryColor
                          : AppTheme.dividerColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        if (companies.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                _currentUserId.isEmpty
                    ? 'Connectez-vous pour voir vos entreprises.'
                    : 'Aucune entreprise dans cette categorie.',
              ),
            ),
          )
        else
          ...companies.map(
            (company) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _MyCompanyCard(
                company: company,
                verificationLabel: _verificationLabel(company),
                verificationColor: _verificationColor(company),
                onView: () => _openDetails(company),
                onEdit: () => _openEdit(company),
                onDelete: () => _delete(company),
              ),
            ),
          ),
      ],
    );
  }

  // ── Build principal ───────────────────────────

  @override
  Widget build(BuildContext context) {
    final isMesEntreprises = _activeSection == 'Mes entreprises';
    final showInlineCreate = isMesEntreprises && _showInlineCreateButton;
    final showCreateFab = isMesEntreprises && !showInlineCreate;
    final createLabel = isMesEntreprises ? 'Creer une page' : 'Creer';

    return Scaffold(
      appBar: AppBar(
        title: Text(_activeSection),
        centerTitle: true,
        backgroundColor: AppTheme.cardColor,
        foregroundColor: AppTheme.textColor,
       
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(
                  message: _error!,
                  onRetry: () => _loadCompanies(reset: true),
                )
              : RefreshIndicator(
                  onRefresh: () => _loadCompanies(reset: true),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (!isMesEntreprises) return false;
                      final shouldShowInline = notification.metrics.pixels <= 8;
                      if (shouldShowInline != _showInlineCreateButton && mounted) {
                        setState(() {
                          _showInlineCreateButton = shouldShowInline;
                        });
                      }
                      return false;
                    },
                    child: ListView(
                      controller: _listScrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      children: [
                        _buildSectionSwitcher(),
                        const SizedBox(height: 12),
                        if (_activeSection == 'Pages entreprises')
                          _buildExploreView()
                        else
                          _buildMyCompaniesView(showCreateButton: showInlineCreate),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed:
                              _isLoadingMore ? null : () => _loadCompanies(reset: false),
                          icon: _isLoadingMore
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.expand_more),
                          label: const Text('Voir plus'),
                        ),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: !showCreateFab
          ? null
          : FloatingActionButton(
              backgroundColor: AppColors.primaryColor,
              tooltip: createLabel,
              onPressed: _openCreate,
              child: const Icon(Icons.add),
            ),
    );
  }
}

// ─────────────────────────────────────────────
// WIDGET : FILTRE CATEGORIES + PLUS
// ─────────────────────────────────────────────
class _CategoryFilterRow extends StatefulWidget {
  final List<String> categories;
  final String activeCategory;
  final ValueChanged<String> onSelect;

  const _CategoryFilterRow({
    required this.categories,
    required this.activeCategory,
    required this.onSelect,
  });

  @override
  State<_CategoryFilterRow> createState() => _CategoryFilterRowState();
}

class _CategoryFilterRowState extends State<_CategoryFilterRow> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _open = false;

  void _toggleDropdown() {
    if (_open) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    final overlay = Overlay.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final dropdownWidth = ((screenWidth - 24).clamp(220.0, 360.0)).toDouble();
    _overlayEntry = OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeDropdown,
        child: Stack(
          children: [
            CompositedTransformFollower(
              link: _layerLink,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              showWhenUnlinked: false,
              offset: const Offset(0, 8),
              child: GestureDetector(
                onTap: () {},
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(14),
                  color: AppTheme.cardColor,
                  child: Container(
                    width: dropdownWidth,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _kMoreCategories.map((cat) {
                            final selected = widget.activeCategory == cat;
                            return InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: () {
                                widget.onSelect(cat);
                                _closeDropdown();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.primaryColor
                                      : AppTheme.cardColor,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.primaryColor
                                        : AppTheme.dividerColor,
                                  ),
                                ),
                                child: Text(
                                  cat,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: selected
                                        ? Colors.white
                                        : AppTheme.textColor,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Tout afficher',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textMutedColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    overlay.insert(_overlayEntry!);
    setState(() => _open = true);
  }

  void _closeDropdown({bool notify = true}) {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _open = false;
    if (notify && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _closeDropdown(notify: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMoreSelected = _kMoreCategories.contains(widget.activeCategory);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...widget.categories.map((cat) {
            final selected = widget.activeCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(cat),
                selected: selected,
                onSelected: (_) => widget.onSelect(cat),
                selectedColor: AppColors.primaryColor,
                backgroundColor: AppTheme.cardColor,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : AppTheme.textColor,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: selected
                        ? AppColors.primaryColor
                        : AppTheme.dividerColor,
                  ),
                ),
              ),
            );
          }),
          CompositedTransformTarget(
            link: _layerLink,
            child: GestureDetector(
              onTap: _toggleDropdown,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: (_open || isMoreSelected)
                      ? AppColors.primaryColor
                      : AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: (_open || isMoreSelected)
                        ? AppColors.primaryColor
                        : AppTheme.dividerColor,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '+ Plus',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: (_open || isMoreSelected)
                            ? Colors.white
                            : AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _open
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 16,
                      color: (_open || isMoreSelected)
                          ? Colors.white
                          : AppTheme.textMutedColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WIDGET : MINI STAT CARD
// ─────────────────────────────────────────────
class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _MiniStatCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.textMutedColor),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WIDGET : CARD EXPLORE
// ─────────────────────────────────────────────
class _CompanyCard extends StatefulWidget {
  final CompanyModel company;
  final VoidCallback onTap;

  const _CompanyCard({required this.company, required this.onTap});

  @override
  State<_CompanyCard> createState() => _CompanyCardState();
}

class _CompanyCardState extends State<_CompanyCard> {
  bool _following = false;

  String? _buildCoverUrl() {
    final cover = widget.company.coverImage;
    if (cover == null || cover.isEmpty) return null;
    if (cover.startsWith('http')) return cover;
    if (widget.company.userId.isEmpty) return null;
    return '${ImageUrlHelper.getBaseUrl()}/uploads/images-${widget.company.userId}/companies/cover/$cover';
  }

  String? _buildLogoUrl() {
    final logo = widget.company.logo;
    if (logo == null || logo.isEmpty) return null;
    if (logo.startsWith('http')) return logo;
    if (widget.company.userId.isEmpty) return null;
    return '${ImageUrlHelper.getBaseUrl()}/uploads/images-${widget.company.userId}/companies/logo/$logo';
  }

  @override
  Widget build(BuildContext context) {
    final coverUrl = _buildCoverUrl();
    final logoUrl = _buildLogoUrl();
    final company = widget.company;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner + logo
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: coverUrl == null
                        ? Container(color: const Color(0xFF8C8C8C))
                        : Image.network(
                            coverUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: const Color(0xFF8C8C8C)),
                          ),
                  ),
                  // Badge industrie
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        company.industry,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  // Logo
                  Positioned(
                    left: 12,
                    bottom: -22,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.dividerColor),
                      ),
                      child: logoUrl == null
                          ? Center(
                              child: Text(
                                company.name.isEmpty
                                    ? '?'
                                    : company.name[0].toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Colors.black87,
                                ),
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                logoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    company.name.isEmpty
                                        ? '?'
                                        : company.name[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // Corps
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 36, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom
                  Text(
                    company.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Localisation
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: Color(0xFFD32F2F)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          company.location ?? 'Localisation non specifiee',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMutedColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Description courte
                  Text(
                    company.shortDescription?.isNotEmpty == true
                        ? company.shortDescription!
                        : company.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF26E22),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Statistiques
                  Row(
                    children: [
                      Expanded(
                        child: _StatItem(
                          icon: Icons.business_center_outlined,
                          label: 'offre',
                          value: '${company.stats.jobApplications}',
                        ),
                      ),
                      Expanded(
                        child: _StatItem(
                          icon: Icons.people_outline,
                          label: 'personnes',
                          value: company.size ?? '1-10',
                        ),
                      ),
                      Expanded(
                        child: _StatItem(
                          icon: Icons.favorite_outline,
                          label: 'abonne',
                          value: '${company.stats.followers}',
                        ),
                      ),
                      Expanded(
                        child: _StatItem(
                          icon: Icons.star_outline,
                          label: 'rating',
                          value: '4.8',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Boutons
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() => _following = !_following);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _following
                                      ? AppTheme.cardColor
                                      : const Color(0xFFF26E22),
                                  foregroundColor: _following
                                      ? AppTheme.textColor
                                      : Colors.white,
                                  side: _following
                                      ? BorderSide(
                                          color: AppTheme.dividerColor)
                                      : BorderSide.none,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 11),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: Icon(
                                  _following
                                      ? Icons.notifications_off_outlined
                                      : Icons.add_circle_outline,
                                  size: 18,
                                ),
                                label: Text(
                                  _following ? 'Ne plus suivre' : 'Suivre',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            if (!_following)
                              Positioned(
                                right: 8,
                                top: 2,
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '+3',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFF26E22),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onTap,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppTheme.dividerColor),
                            padding:
                                const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Icon(
                            Icons.open_in_new,
                            size: 16,
                            color: AppTheme.textMutedColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WIDGET : CARD MES ENTREPRISES
// ─────────────────────────────────────────────
class _MyCompanyCard extends StatelessWidget {
  final CompanyModel company;
  final String verificationLabel;
  final Color verificationColor;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MyCompanyCard({
    required this.company,
    required this.verificationLabel,
    required this.verificationColor,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  String? _buildCoverUrl() {
    final cover = company.coverImage;
    if (cover == null || cover.isEmpty) return null;
    if (cover.startsWith('http')) return cover;
    if (company.userId.isEmpty) return null;
    return '${ImageUrlHelper.getBaseUrl()}/uploads/images-${company.userId}/companies/cover/$cover';
  }

  String? _buildLogoUrl() {
    final logo = company.logo;
    if (logo == null || logo.isEmpty) return null;
    if (logo.startsWith('http')) return logo;
    if (company.userId.isEmpty) return null;
    return '${ImageUrlHelper.getBaseUrl()}/uploads/images-${company.userId}/companies/logo/$logo';
  }

  @override
  Widget build(BuildContext context) {
    final coverUrl = _buildCoverUrl();
    final logoUrl = _buildLogoUrl();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(14)),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  height: 110,
                  width: double.infinity,
                  child: coverUrl == null
                      ? Container(color: const Color(0xFF8C8C8C))
                      : Image.network(
                          coverUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: const Color(0xFF8C8C8C)),
                        ),
                ),
                // Menu
                Positioned(
                  top: 8,
                  right: 8,
                  child: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (ctx) => [
                      PopupMenuItem(value: 'edit', child: Text(AppLocalizations.of(ctx).edit)),
                      PopupMenuItem(
                          value: 'delete', child: Text(AppLocalizations.of(ctx).delete)),
                    ],
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.24),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.more_horiz, color: Colors.white),
                    ),
                  ),
                ),
                // Logo
                Positioned(
                  left: 12,
                  bottom: -20,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: logoUrl == null
                        ? Center(
                            child: Text(
                              company.name.isEmpty
                                  ? '?'
                                  : company.name[0].toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                                color: Colors.black87,
                              ),
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              logoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  company.name.isEmpty
                                      ? '?'
                                      : company.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          // Corps
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 28, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom + badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        company.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: verificationColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        verificationLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: verificationColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Localisation
                Text(
                  company.location ?? company.industry,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMutedColor,
                  ),
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  company.shortDescription?.isNotEmpty == true
                      ? company.shortDescription!
                      : company.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 14),

                // Stats
                Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        icon: Icons.remove_red_eye_outlined,
                        label: 'Vues',
                        value: '${company.stats.views}',
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        icon: Icons.group_outlined,
                        label: 'Abonnes',
                        value: '${company.stats.followers}',
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        icon: Icons.work_outline,
                        label: 'Candidatures',
                        value: '${company.stats.jobApplications}',
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        icon: Icons.mail_outline,
                        label: 'Messages',
                        value: '${company.stats.messages}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onView,
                        icon: const Icon(Icons.remove_red_eye_outlined,
                            size: 16),
                        label: const Text('Voir'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: Text(AppLocalizations.of(context).edit),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WIDGET : STAT ITEM
// ─────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppTheme.textMutedColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: AppTheme.textMutedColor),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// VUE DETAIL ENTREPRISE
// ─────────────────────────────────────────────
class CompanyDetailView extends StatefulWidget {
  final String companyId;

  const CompanyDetailView({super.key, required this.companyId});

  @override
  State<CompanyDetailView> createState() => _CompanyDetailViewState();
}

class _CompanyDetailViewState extends State<CompanyDetailView> {
  final CompanyRepository _repository = CompanyRepository();
  final JobRepository _jobRepository = JobRepository();
  final ApiClient _apiClient = ApiClient();

  CompanyModel? _company;
  String? _currentUserId;
  String _selectedTab = 'A propos';
  List<JobModel> _companyJobs = const [];
  bool _jobsLoading = false;
  String? _jobsError;
  bool _loading = true;
  bool _actionLoading = false;
  String? _error;

  bool get _isOwner =>
      _company != null &&
      _currentUserId != null &&
      (_currentUserId?.isNotEmpty ?? false) &&
      _company!.userId == _currentUserId;

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
      final userId = await _apiClient.getUserId();
      final company = await _repository.getById(widget.companyId);
      if (!mounted) return;
      setState(() {
        _currentUserId = userId;
        _company = company;
        _loading = false;
      });
      await _loadCompanyJobs();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadCompanyJobs() async {
    if (!mounted) return;
    setState(() {
      _jobsLoading = true;
      _jobsError = null;
    });

    try {
      final jobs = await _jobRepository.getByCompanyId(widget.companyId);
      if (!mounted) return;
      setState(() {
        _companyJobs = jobs;
        _jobsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _jobsError = e.toString();
        _jobsLoading = false;
      });
    }
  }

  Future<void> _openCreateJobSheet() async {
    final company = _company;
    final userId = _currentUserId;
    if (company == null || company.id == null || userId == null || userId.isEmpty) {
      return;
    }

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateJobSheet(
        company: company,
        currentUserId: userId,
        initial: null,
      ),
    );

    if (!mounted) return;

    if (created == true) {
      await _loadCompanyJobs();
      await _load();
      if (!mounted) return;
      setState(() {
        _selectedTab = 'Offres';
      });
    }
  }

  Future<void> _openEditJobSheet(JobModel job) async {
    final company = _company;
    final userId = _currentUserId;
    if (company == null || company.id == null || userId == null || userId.isEmpty) {
      return;
    }

    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateJobSheet(
        company: company,
        currentUserId: userId,
        initial: job,
      ),
    );

    if (!mounted) return;
    if (updated == true) {
      await _loadCompanyJobs();
      await _load();
    }
  }

  Future<void> _deleteJob(JobModel job) async {
    if (job.id == null || job.id!.isEmpty) {
      if (!mounted) return;
      CustomToast.error(context, 'Identifiant offre manquant');
      return;
    }

    final confirm = await CustomAlertDialog.showConfirmation(
      context: context,
      title: AppLocalizations.of(context).deleteOffer,
      message: AppLocalizations.of(context).confirmDeletion(job.title ?? ''),
      confirmText: AppLocalizations.of(context).delete,
      isDangerous: true,
    );
    if (!mounted) return;
    if (!confirm) return;

    try {
      await _jobRepository.delete(job.id!);
      if (!mounted) return;
      CustomToast.success(context, AppLocalizations.of(context).offerDeleted);
      await _loadCompanyJobs();
      await _load();
    } catch (e) {
      if (!mounted) return;
      CustomToast.error(context, '${AppLocalizations.of(context).deletionFailed}: $e');
    }
  }

  Future<void> _openJobDetails(JobModel job) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _JobDetailView(
          job: job,
          companyName: _company?.name ?? 'Entreprise',
          isOwner: _isOwner,
        ),
      ),
    );
    if (!mounted) return;
    if (changed == true) {
      await _loadCompanyJobs();
      await _load();
    }
  }

  Future<void> _delete() async {
    final company = _company;
    if (company == null || company.id == null) return;

    final confirm = await CustomAlertDialog.showConfirmation(
      context: context,
      title: AppLocalizations.of(context).deleteCompany,
      message: AppLocalizations.of(context).confirmDeletion(company.name ?? ''),
      confirmText: AppLocalizations.of(context).delete,
      isDangerous: true,
    );
    if (!mounted) return;
    if (!confirm) return;

    setState(() => _actionLoading = true);
    try {
      await _repository.delete(company.id!);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _actionLoading = false);
      CustomToast.error(context, '${AppLocalizations.of(context).deletionFailed}: $e');
    }
  }

  Future<void> _edit() async {
    final company = _company;
    if (company == null) return;
    if (company.id == null || company.id!.isEmpty) {
      if (!mounted) return;
      CustomToast.error(context, 'Impossible de modifier: identifiant manquant');
      return;
    }
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CompanyFormView(initial: company),
        settings: const RouteSettings(name: '/companies/edit'),
      ),
    );
    if (!mounted) return;
    if (updated == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_company?.name ?? 'Entreprise'),
        backgroundColor: AppTheme.cardColor,
        foregroundColor: AppTheme.textColor,
        actions: [
          if (_isOwner)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') _edit();
                if (value == 'delete') _delete();
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(value: 'edit', child: Text(AppLocalizations.of(ctx).edit)),
                PopupMenuItem(value: 'delete', child: Text(AppLocalizations.of(ctx).delete)),
              ],
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _load)
              : _company == null
                  ? Center(child: Text(AppLocalizations.of(context).companyNotFound))
                  : _CompanyDetailBody(
                      company: _company!,
                      isOwner: _isOwner,
                      actionLoading: _actionLoading,
                      selectedTab: _selectedTab,
                      jobs: _companyJobs,
                      jobsLoading: _jobsLoading,
                      jobsError: _jobsError,
                      onTabChange: (tab) {
                        setState(() {
                          _selectedTab = tab;
                        });
                      },
                      onCreateJob: _openCreateJobSheet,
                      onViewJob: _openJobDetails,
                      onEditJob: _openEditJobSheet,
                      onDeleteJob: _deleteJob,
                      onRefreshJobs: _loadCompanyJobs,
                      onEdit: _edit,
                      onDelete: _delete,
                    ),
    );
  }
}

// ─────────────────────────────────────────────
// DETAIL BODY
// ─────────────────────────────────────────────
class _CompanyDetailBody extends StatelessWidget {
  final CompanyModel company;
  final bool isOwner;
  final bool actionLoading;
  final String selectedTab;
  final List<JobModel> jobs;
  final bool jobsLoading;
  final String? jobsError;
  final ValueChanged<String> onTabChange;
  final Future<void> Function() onRefreshJobs;
  final VoidCallback onCreateJob;
  final ValueChanged<JobModel> onViewJob;
  final ValueChanged<JobModel> onEditJob;
  final ValueChanged<JobModel> onDeleteJob;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CompanyDetailBody({
    required this.company,
    required this.isOwner,
    required this.actionLoading,
    required this.selectedTab,
    required this.jobs,
    required this.jobsLoading,
    required this.jobsError,
    required this.onTabChange,
    required this.onRefreshJobs,
    required this.onCreateJob,
    required this.onViewJob,
    required this.onEditJob,
    required this.onDeleteJob,
    required this.onEdit,
    required this.onDelete,
  });

  String? _buildCoverUrl() {
    final cover = company.coverImage;
    if (cover == null || cover.isEmpty) return null;
    if (cover.startsWith('http')) return cover;
    if (company.userId.isEmpty) return null;
    return '${ImageUrlHelper.getBaseUrl()}/uploads/images-${company.userId}/companies/cover/$cover';
  }

  String? _buildLogoUrl() {
    final logo = company.logo;
    if (logo == null || logo.isEmpty) return null;
    if (logo.startsWith('http')) return logo;
    if (company.userId.isEmpty) return null;
    return '${ImageUrlHelper.getBaseUrl()}/uploads/images-${company.userId}/companies/logo/$logo';
  }

  int get _satisfaction {
    if (company.stats.followers <= 0 && company.stats.views <= 0) return 85;
    final s = ((company.stats.followers * 6) + company.stats.views) ~/ 12;
    return s.clamp(65, 98);
  }

  int get _growth {
    if (company.stats.views <= 0) return 27;
    return (company.stats.views % 40 + 10).clamp(0, 45);
  }

  @override
  Widget build(BuildContext context) {
    final coverUrl = _buildCoverUrl();
    final logoUrl = _buildLogoUrl();
    final isWide = MediaQuery.of(context).size.width >= 1000;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      children: [
        // Hero card
        _buildHeroCard(coverUrl, logoUrl),
        const SizedBox(height: 12),

        // Contacts
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ContactChip(
              icon: Icons.public,
              text: company.website ?? 'Site web non defini',
            ),
            _ContactChip(
              icon: Icons.email_outlined,
              text: company.email ?? 'Email non defini',
            ),
            _ContactChip(
              icon: Icons.call_outlined,
              text: company.phone ?? 'Telephone non defini',
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Onglets
        _buildTabsRow(),
        const SizedBox(height: 10),

        if (selectedTab == 'A propos')
          // Colonnes
          (isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: _buildLeftColumn()),
                    const SizedBox(width: 12),
                    Expanded(flex: 4, child: _buildRightColumn()),
                  ],
                )
              : Column(
                  children: [
                    _buildLeftColumn(),
                    const SizedBox(height: 10),
                    _buildRightColumn(),
                  ],
                ))
        else if (selectedTab == 'Offres')
          _buildJobsTab(context)
        else
          _buildComingSoonTab(),
      ],
    );
  }

  Widget _buildHeroCard(String? coverUrl, String? logoUrl) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        children: [
          // Cover
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
            child: SizedBox(
              width: double.infinity,
              height: 120,
              child: coverUrl == null
                  ? Container(color: const Color(0xFF9E9E9E))
                  : Image.network(
                      coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: const Color(0xFF9E9E9E)),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: AppTheme.dividerColor),
                      ),
                      child: logoUrl == null
                          ? Center(
                              child: Text(
                                company.name.isEmpty
                                    ? '?'
                                    : company.name[0].toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 22,
                                  color: Colors.black87,
                                ),
                              ),
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: Image.network(
                                logoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    company.name.isEmpty
                                        ? '?'
                                        : company.name[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 22,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 10),
                    // Infos
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  company.name,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textColor,
                                  ),
                                ),
                              ),
                              if (company.verified)
                                const Icon(Icons.verified_rounded,
                                    color: Colors.blue, size: 18),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 10,
                            runSpacing: 4,
                            children: [
                              _InlineMeta(
                                  icon: Icons.label_outline,
                                  text: company.industry),
                              _InlineMeta(
                                icon: Icons.location_pin,
                                text: company.location ?? 'Tunisie',
                              ),
                              _InlineMeta(
                                icon: Icons.group_outlined,
                                text: company.size ?? '1001+ employes',
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _TagPill(
                                  label:
                                      '${company.stats.followers} abonnes'),
                              const _TagPill(label: 'Active'),
                              _TagPill(
                                  label:
                                      'Depuis ${company.foundedYear ?? 2020}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Métriques
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: 'Offres emploi',
                        value: '${company.stats.jobApplications}',
                        subtitle: 'Actives',
                        icon: Icons.work_outline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricCard(
                        title: 'Employes',
                        value: company.size ?? '176',
                        subtitle: '+2% ce mois',
                        icon: Icons.group_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricCard(
                        title: 'Satisfaction',
                        value: '$_satisfaction%',
                        subtitle: 'Recommande',
                        icon: Icons.thumb_up_alt_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricCard(
                        title: 'Croissance',
                        value: '+$_growth%',
                        subtitle: 'Annuelle',
                        icon: Icons.trending_up,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          _DetailTabChip(
            label: 'A propos',
            active: selectedTab == 'A propos',
            onTap: () => onTabChange('A propos'),
          ),
          _DetailTabChip(
            label: 'Offres (${jobs.length})',
            active: selectedTab == 'Offres',
            onTap: () => onTabChange('Offres'),
          ),
          _DetailTabChip(
            label: 'Actualites',
            active: selectedTab == 'Actualites',
            onTap: () => onTabChange('Actualites'),
          ),
          _DetailTabChip(
            label: 'Avis (0)',
            active: selectedTab == 'Avis',
            onTap: () => onTabChange('Avis'),
          ),
        ],
      ),
    );
  }

  Widget _buildJobsTab(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Offres d\'emploi',
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${jobs.length} offre disponible',
                        style: TextStyle(color: AppTheme.textMutedColor),
                      ),
                    ],
                  ),
                ),
                if (isOwner)
                  ElevatedButton.icon(
                    onPressed: onCreateJob,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Publier une offre'),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.dividerColor),
          if (jobsLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (jobsError != null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    jobsError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: onRefreshJobs,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reessayer'),
                  ),
                ],
              ),
            )
          else if (jobs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.work_outline,
                      size: 36,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Aucune offre d\'emploi',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Cette entreprise n\'a pas encore publie d\'offres d\'emploi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textMutedColor),
                  ),
                  if (isOwner) ...[
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: onCreateJob,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text('Publier la premiere offre'),
                    ),
                  ],
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: jobs
                    .map(
                      (job) => _JobItemCard(
                        job: job,
                        isOwner: isOwner,
                        onView: () => onViewJob(job),
                        onEdit: isOwner ? () => onEditJob(job) : null,
                        onDelete: isOwner ? () => onDeleteJob(job) : null,
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildComingSoonTab() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Center(
        child: Text(
          'Cette section sera disponible bientot.',
          style: TextStyle(color: AppTheme.textMutedColor),
        ),
      ),
    );
  }

  Widget _buildLeftColumn() {
    return Column(
      children: [
        _CompanyInfoCard(
          title: 'Description',
          child: Text(
            company.description.isEmpty
                ? 'Aucune description disponible.'
                : company.description,
            style: TextStyle(height: 1.45, color: AppTheme.textColor),
          ),
        ),
        const SizedBox(height: 10),
        _CompanyInfoCard(
          title: 'Informations',
          child: Column(
            children: [
              _CompanyKeyValue(label: 'Secteur', value: company.industry),
              _CompanyKeyValue(label: 'Taille', value: company.size ?? '1001+'),
              _CompanyKeyValue(
                  label: 'Creation',
                  value: '${company.foundedYear ?? 2020}'),
              _CompanyKeyValue(
                  label: 'Localisation',
                  value: company.location ?? 'Non specifiee'),
              _CompanyKeyValue(
                  label: 'Adresse',
                  value: company.address ?? 'Non specifiee'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _CompanyInfoCard(
          title: 'Contact',
          child: Column(
            children: [
              _CompanyKeyValue(
                  label: 'Email', value: company.email ?? 'Non specifie'),
              _CompanyKeyValue(
                  label: 'Telephone',
                  value: company.phone ?? 'Non specifie'),
              _CompanyKeyValue(
                  label: 'Site web', value: company.website ?? 'Non specifie'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightColumn() {
    return Column(
      children: [
        _CompanyInfoCard(
          title: 'A propos',
          child: Column(
            children: [
              _CompanyKeyValue(label: 'Secteur', value: company.industry),
              _CompanyKeyValue(label: 'Taille', value: company.size ?? '1001+'),
              _CompanyKeyValue(
                  label: 'Creation',
                  value: '${company.foundedYear ?? 2020}'),
              _CompanyKeyValue(
                  label: 'Localisation',
                  value: company.location ?? 'Ariana'),
              _CompanyKeyValue(
                  label: 'Abonnes',
                  value: '${company.stats.followers}'),
              _CompanyKeyValue(
                  label: 'Offres actives',
                  value: '${company.stats.jobApplications}'),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.public, size: 16),
                  label: const Text('Visiter le site web'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _CompanyInfoCard(
          title: 'Culture d\'entreprise',
          child: Column(
            children: [
              _CultureMetricBar(
                  label: 'Equilibre vie pro/perso', value: _satisfaction),
              const _CultureMetricBar(label: 'Innovation', value: 95),
              const _CultureMetricBar(label: 'Avantages sociaux', value: 80),
              const _CultureMetricBar(label: 'Management', value: 75),
              const _CultureMetricBar(
                  label: 'Evolution de carriere', value: 85),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _CompanyInfoCard(
          title: 'Statistiques',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TagPill(label: 'Croissance +$_growth%'),
              _TagPill(
                  label:
                      'Retention ${company.stats.followers > 0 ? 88 : 76}%'),
              _TagPill(label: 'Projets ${company.stats.jobApplications}'),
              _TagPill(label: 'Satisfaction $_satisfaction%'),
            ],
          ),
        ),
        if (isOwner) const SizedBox(height: 4),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// WIDGETS DETAIL — SOUS-COMPOSANTS
// ─────────────────────────────────────────────
class _InlineMeta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InlineMeta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppTheme.textMutedColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(color: AppTheme.textMutedColor, fontSize: 12),
        ),
      ],
    );
  }
}

class _ContactChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ContactChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textMutedColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: AppTheme.textColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _DetailTabChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _DetailTabChip({required this.label, this.active = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryColor : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
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
}

class _TagPill extends StatelessWidget {
  final String label;

  const _TagPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.textColor,
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.dividerColor),
        color: AppTheme.cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: AppColors.primaryColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11, color: AppTheme.textMutedColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyInfoCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _CompanyInfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _CompanyKeyValue extends StatelessWidget {
  final String label;
  final String value;

  const _CompanyKeyValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                  color: AppTheme.textMutedColor, fontSize: 12),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CultureMetricBar extends StatelessWidget {
  final String label;
  final int value;

  const _CultureMetricBar({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0, 100);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                      color: AppTheme.textMutedColor, fontSize: 12),
                ),
              ),
              Text(
                '$clamped%',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppTheme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: clamped / 100,
              backgroundColor: const Color(0xFFFFE0CC),
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _JobItemCard extends StatelessWidget {
  final JobModel job;
  final bool isOwner;
  final VoidCallback onView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _JobItemCard({
    required this.job,
    required this.isOwner,
    required this.onView,
    this.onEdit,
    this.onDelete,
  });

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

  String _experienceLabel(ExperienceLevel level) {
    switch (level) {
      case ExperienceLevel.Debutant:
        return 'Debutant';
      case ExperienceLevel.OneToThree:
        return '1-3 ans';
      case ExperienceLevel.ThreeToFive:
        return '3-5 ans';
      case ExperienceLevel.FivePlus:
        return '5+ ans';
    }
  }

  String _remoteLabel(RemotePolicy policy) {
    switch (policy) {
      case RemotePolicy.OnSite:
        return 'Sur site';
      case RemotePolicy.Hybrid:
        return 'Hybride';
      case RemotePolicy.FullRemote:
        return 'Full Remote';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  job.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              if (isOwner)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit?.call();
                    if (value == 'delete') onDelete?.call();
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(value: 'edit', child: Text(AppLocalizations.of(ctx).edit)),
                    PopupMenuItem(value: 'delete', child: Text(AppLocalizations.of(ctx).delete)),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Actions',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down, size: 16, color: AppTheme.textMutedColor),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            job.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppTheme.textMutedColor),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _TagPill(label: job.location),
              _TagPill(label: _contractLabel(job.contractType)),
              _TagPill(label: _experienceLabel(job.experience)),
              _TagPill(label: _remoteLabel(job.remotePolicy)),
              _TagPill(label: '${job.views} vues'),
              _TagPill(label: '${job.applications} candidatures'),
            ],
          ),
          if (job.salaryMin != null || job.salaryMax != null) ...[
            const SizedBox(height: 6),
            Text(
              'Salaire: ${job.salaryMin?.toStringAsFixed(0) ?? '-'} - ${job.salaryMax?.toStringAsFixed(0) ?? '-'}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: AppTheme.textMutedColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  job.location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppTheme.textMutedColor),
                ),
              ),
              TextButton(
                onPressed: onView,
                child: const Text('Voir l\'offre'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocalJobApplication {
  final String? applicationId;
  final String? companyId;
  final String candidateName;
  final String candidateEmail;
  final String? candidatePhone;
  final String motivation;
  final String cvName;
  final String? cvPath;
  final DateTime appliedAt;
  final DateTime? interviewAt;
  final String status;
  final String? responseMessage;

  const _LocalJobApplication({
    this.applicationId,
    this.companyId,
    required this.candidateName,
    required this.candidateEmail,
    this.candidatePhone,
    required this.motivation,
    required this.cvName,
    this.cvPath,
    required this.appliedAt,
    this.interviewAt,
    required this.status,
    this.responseMessage,
  });

  _LocalJobApplication copyWith({
    String? applicationId,
    String? companyId,
    String? candidateName,
    String? candidateEmail,
    String? candidatePhone,
    String? motivation,
    String? cvName,
    String? cvPath,
    DateTime? appliedAt,
    DateTime? interviewAt,
    String? status,
    String? responseMessage,
  }) {
    return _LocalJobApplication(
      applicationId: applicationId ?? this.applicationId,
      companyId: companyId ?? this.companyId,
      candidateName: candidateName ?? this.candidateName,
      candidateEmail: candidateEmail ?? this.candidateEmail,
      candidatePhone: candidatePhone ?? this.candidatePhone,
      motivation: motivation ?? this.motivation,
      cvName: cvName ?? this.cvName,
      cvPath: cvPath ?? this.cvPath,
      appliedAt: appliedAt ?? this.appliedAt,
      interviewAt: interviewAt ?? this.interviewAt,
      status: status ?? this.status,
      responseMessage: responseMessage ?? this.responseMessage,
    );
  }
}

final Map<String, List<_LocalJobApplication>> _jobApplicationsStore = {};

class _ApplyJobResult {
  final String motivation;
  final String cvName;
  final String? cvPath;
  final Uint8List? cvBytes;
  final bool useExistingCv;

  const _ApplyJobResult({
    required this.motivation,
    required this.cvName,
    this.cvPath,
    this.cvBytes,
    required this.useExistingCv,
  });
}

class _JobDetailView extends StatefulWidget {
  final JobModel job;
  final String companyName;
  final bool isOwner;

  const _JobDetailView({
    required this.job,
    required this.companyName,
    required this.isOwner,
  });

  @override
  State<_JobDetailView> createState() => _JobDetailViewState();
}

class _JobDetailViewState extends State<_JobDetailView> {
  final JobApplicationRepository _jobApplicationRepository =
      JobApplicationRepository();
  final UserRepository _userRepository = UserRepository();
  String _activeTab = 'details';
  late final List<_LocalJobApplication> _applications;
  String _applicationStatusFilter = 'Toutes';
  OverlayEntry? _blockingLoaderEntry;
  bool _isLoadingApplications = false;
  bool _candidateInfoLoaded = false;
  String _currentCandidateName = 'Utilisateur';
  String _currentCandidateEmail = 'utilisateur@local.app';
  String? _currentCandidatePhone;

  @override
  void initState() {
    super.initState();
    _applications = List<_LocalJobApplication>.from(
      _jobApplicationsStore[_applicationStoreKey] ?? const <_LocalJobApplication>[],
    );
    _loadCurrentCandidateInfo();
    if (isOwner) {
      _loadOwnerApplications();
    }
  }

  @override
  void dispose() {
    _hideBlockingLoader();
    super.dispose();
  }

  void _showBlockingLoader(String message) {
    if (!mounted) return;
    _hideBlockingLoader();

    final overlay = Overlay.of(context, rootOverlay: true);

    _blockingLoaderEntry = OverlayEntry(
      builder: (_) => Material(
        color: const Color(0x59000000),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(
                  message,
                  style: TextStyle(
                    color: AppTheme.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(_blockingLoaderEntry!);
  }

  void _hideBlockingLoader() {
    _blockingLoaderEntry?.remove();
    _blockingLoaderEntry = null;
  }

  Future<void> _loadCurrentCandidateInfo() async {
    try {
      final user = await _userRepository.getCurrentUser();
      if (!mounted) return;
      setState(() {
        final fullName = user.fullName.trim();
        _currentCandidateName = fullName.isEmpty ? user.userName : fullName;
        _currentCandidateEmail = user.email.trim().isEmpty
            ? _currentCandidateEmail
            : user.email.trim();
        _currentCandidatePhone = user.phone?.trim().isEmpty == true
            ? null
            : user.phone?.trim();
        _candidateInfoLoaded = true;
      });
    } catch (_) {
      // Keep fallback values if current user profile cannot be loaded.
      _candidateInfoLoaded = true;
    }
  }

  Future<void> _ensureCandidateInfoLoaded() async {
    if (_candidateInfoLoaded) return;
    await _loadCurrentCandidateInfo();
  }

  String? _asObjectIdString(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (value is Map) {
      return _asObjectIdString(value[r'$oid'] ?? value['_id'] ?? value['id']);
    }
    return value.toString();
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'en attente':
        return 'En attente';
      case 'shortlisted':
      case 'entretien':
        return 'Entretien';
      case 'viewed':
      case 'in_review':
      case 'en cours':
        return 'En cours';
      case 'accepted':
      case 'acceptee':
        return 'Acceptee';
      case 'rejected':
      case 'refusee':
        return 'Refusee';
      case 'withdrawn':
        return 'Retiree';
      default:
        return status;
    }
  }

  String _stringOrDefault(dynamic value, String fallback) {
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return fallback;
  }

  DateTime _parseDateOrNow(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
    if (value is Map && value[r'$date'] is String) {
      final parsed = DateTime.tryParse((value[r'$date'] as String).trim());
      if (parsed != null) return parsed;
    }
    return DateTime.now();
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

  String _feedbackForInterview(DateTime dateTime) {
    return 'INTERVIEW_AT:${dateTime.toIso8601String()}';
  }

  Future<DateTime?> _pickInterviewDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (pickedDate == null) return null;

    if (!mounted) return null;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (pickedTime == null) return null;

    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  Future<void> _loadOwnerApplications() async {
    final companyId = job.companyId?.trim();
    if (companyId == null || companyId.isEmpty) return;

    if (mounted) {
      setState(() => _isLoadingApplications = true);
    }

    try {
      final rawApplications = await _jobApplicationRepository.getCompanyApplications(
        companyId: companyId,
      );

      final currentJobId = job.id?.trim();
      final filtered = rawApplications.where((item) {
        if (currentJobId == null || currentJobId.isEmpty) return true;
        final itemJobId = _asObjectIdString(item['jobId']) ??
            _asObjectIdString(item['job']) ??
            _asObjectIdString(item['job_id']);
        return itemJobId == currentJobId;
      }).map((item) {
        final user = item['user'] is Map<String, dynamic>
            ? item['user'] as Map<String, dynamic>
            : <String, dynamic>{};

        final status = _stringOrDefault(item['status'], 'pending');
        return _LocalJobApplication(
          applicationId: _asObjectIdString(item['_id']) ?? _asObjectIdString(item['id']),
          companyId: _asObjectIdString(item['companyId']) ?? companyId,
          candidateName: _stringOrDefault(
            item['applicantName'] ??
                item['userName'] ??
                item['candidateName'] ??
                user['fullName'] ??
                user['userName'] ??
                user['name'],
            'Candidat',
          ),
          candidateEmail: _stringOrDefault(
            item['applicantEmail'] ??
                item['userEmail'] ??
                item['candidateEmail'] ??
                user['email'],
            'email-indisponible@local.app',
          ),
          candidatePhone: _stringOrDefault(
            item['applicantPhone'] ??
                item['userPhone'] ??
                item['candidatePhone'] ??
                user['phone'],
            '',
          ).isEmpty
              ? null
              : _stringOrDefault(
                  item['applicantPhone'] ??
                      item['userPhone'] ??
                      item['candidatePhone'] ??
                      user['phone'],
                  '',
                ),
          motivation: _stringOrDefault(
            item['coverLetter'] ?? item['motivation'],
            'Motivation non specifiee',
          ),
          cvName: _stringOrDefault(item['cvFileName'] ?? item['cvName'], 'CV'),
          cvPath: _stringOrDefault(item['cvFilePath'] ?? item['cvPath'], '').isEmpty
              ? null
              : _stringOrDefault(item['cvFilePath'] ?? item['cvPath'], ''),
          appliedAt: _parseDateOrNow(item['createdAt'] ?? item['appliedAt']),
          interviewAt: _parseInterviewDate(item['response']),
          status: status,
          responseMessage: _stringOrDefault(item['response'], ''),
        );
      }).toList()
        ..sort((a, b) => b.appliedAt.compareTo(a.appliedAt));

      if (!mounted) return;
      setState(() {
        _applications
          ..clear()
          ..addAll(filtered);
        _syncApplicationsStore();
      });
    } catch (e) {
      if (!mounted) return;
      CustomToast.error(context, 'Chargement des candidatures impossible: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingApplications = false);
      }
    }
  }

  JobModel get job => widget.job;

  String get companyName => widget.companyName;

  bool get isOwner => widget.isOwner;

  String get _applicationStoreKey {
    final id = job.id;
    if (id != null && id.isNotEmpty) return id;
    return '${job.companyId ?? 'company'}::${job.title}';
  }

  List<_LocalJobApplication> get _filteredApplications {
    if (_applicationStatusFilter == 'Toutes') {
      return _applications;
    }
    return _applications.where((app) {
      switch (_applicationStatusFilter) {
        case 'En attente':
          return app.status == 'pending';
        case 'Entretien':
          return app.status == 'shortlisted' || app.status == 'viewed';
        case 'Acceptée':
          return app.status == 'accepted';
        case 'Rejetée':
          return app.status == 'rejected';
        default:
          return true;
      }
    }).toList();
  }

  void _syncApplicationsStore() {
    _jobApplicationsStore[_applicationStoreKey] =
        List<_LocalJobApplication>.from(_applications);
  }

  Future<String?> _persistCvFromResult(_ApplyJobResult result) async {
    if (result.cvPath != null && result.cvPath!.isNotEmpty) {
      return result.cvPath;
    }
    final bytes = result.cvBytes;
    if (bytes == null || bytes.isEmpty) return null;

    try {
      final safeName = result.cvName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final file = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}${DateTime.now().millisecondsSinceEpoch}_$safeName',
      );
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
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

  String _experienceLabel(ExperienceLevel level) {
    switch (level) {
      case ExperienceLevel.Debutant:
        return 'Debutant';
      case ExperienceLevel.OneToThree:
        return '1-3 ans';
      case ExperienceLevel.ThreeToFive:
        return '3-5 ans';
      case ExperienceLevel.FivePlus:
        return '5+ ans';
    }
  }

  String _remoteLabel(RemotePolicy policy) {
    switch (policy) {
      case RemotePolicy.OnSite:
        return 'Sur site';
      case RemotePolicy.Hybrid:
        return 'Hybride';
      case RemotePolicy.FullRemote:
        return 'Full Remote';
    }
  }

  String _dateLabel(DateTime? date) {
    if (date == null) return '-';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year;
    return '$d/$m/$y';
  }

  Future<void> _openApplySheet() async {
    await _ensureCandidateInfoLoaded();
    if (!mounted) return;

    final sent = await showModalBottomSheet<_ApplyJobResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ApplyJobSheet(job: job, companyName: companyName),
    );
    if (!mounted || sent == null) return;

    final persistedCvPath = await _persistCvFromResult(sent);
    if (!mounted) return;

    String? createdApplicationId;
    String createdStatus = 'pending';
    DateTime createdAt = DateTime.now();

    try {
      _showBlockingLoader('Envoi de candidature...');
      final created = await _jobApplicationRepository.applyForJob(
        jobId: job.id ?? '',
        coverLetter: sent.motivation,
        cvPath: sent.cvPath,
        cvBytes: sent.cvBytes,
        cvFileName: sent.cvName,
      );
      createdApplicationId = _asObjectIdString(created['_id']) ?? _asObjectIdString(created['id']);
      createdStatus = _stringOrDefault(created['status'], 'pending');
      createdAt = _parseDateOrNow(created['createdAt'] ?? created['appliedAt']);
    } catch (e) {
      _hideBlockingLoader();
      if (!mounted) return;
      CustomToast.error(context, 'Envoi de candidature impossible: $e');
      return;
    } finally {
      _hideBlockingLoader();
    }

    if (!mounted) return;

    setState(() {
      _applications.insert(
        0,
        _LocalJobApplication(
          applicationId: createdApplicationId,
          companyId: job.companyId,
          candidateName: _currentCandidateName,
          candidateEmail: _currentCandidateEmail,
          candidatePhone: _currentCandidatePhone,
          motivation: sent.motivation,
          cvName: sent.cvName,
          cvPath: persistedCvPath,
          appliedAt: createdAt,
          status: createdStatus,
        ),
      );
      _activeTab = 'applications';
      _syncApplicationsStore();
    });
    CustomToast.success(context, 'Candidature envoyee avec succes');

    if (isOwner) {
      await _loadOwnerApplications();
    }
  }

  Future<void> _updateApplicationStatus(
    _LocalJobApplication app,
    String status, {
    DateTime? interviewAt,
  }) async {
    try {
      final ids = await _resolveApplicationIds(app, requireCompanyId: true);
      if (ids == null) return;

      final feedback = status == 'shortlisted' && interviewAt != null
          ? _feedbackForInterview(interviewAt)
          : null;

      await _jobApplicationRepository.updateApplicationStatus(
        applicationId: ids.applicationId,
        companyId: ids.companyId!,
        status: status,
        feedback: feedback,
      );
      final index = _applications.indexOf(app);
      if (index >= 0 && mounted) {
        setState(() {
          _applications[index] = app.copyWith(
            applicationId: ids.applicationId,
            companyId: ids.companyId,
            status: status,
            interviewAt: interviewAt,
            responseMessage: feedback,
          );
          _syncApplicationsStore();
        });
      }
      if (isOwner) {
        await _loadOwnerApplications();
      }
      if (!mounted) return;
      CustomToast.success(context, 'Statut mis a jour: $status');
    } catch (e) {
      if (!mounted) return;
      CustomToast.error(context, 'Mise a jour impossible: $e');
    }
  }

  Future<void> _withdrawApplication(_LocalJobApplication app) async {
    try {
      final ids = await _resolveApplicationIds(app, requireCompanyId: false);
      if (ids == null) return;

      await _jobApplicationRepository.withdrawApplication(
        applicationId: ids.applicationId,
      );
      final index = _applications.indexOf(app);
      if (index >= 0 && mounted) {
        setState(() {
          _applications[index] = app.copyWith(
            applicationId: ids.applicationId,
            status: 'withdrawn',
          );
          _syncApplicationsStore();
        });
      }
      if (!mounted) return;
      CustomToast.success(context, 'Candidature retiree');
    } catch (e) {
      if (!mounted) return;
      CustomToast.error(context, 'Retrait impossible: $e');
    }
  }

  Future<_ApplicationIdsResult?> _resolveApplicationIds(
    _LocalJobApplication app, {
    required bool requireCompanyId,
  }) async {
    final hasApplicationId = app.applicationId != null && app.applicationId!.isNotEmpty;
    final hasCompanyId = app.companyId != null && app.companyId!.isNotEmpty;

    if (hasApplicationId && (!requireCompanyId || hasCompanyId)) {
      return _ApplicationIdsResult(
        applicationId: app.applicationId!,
        companyId: app.companyId,
      );
    }

    final ids = await showDialog<_ApplicationIdsResult>(
      context: context,
      builder: (_) => _ApplicationIdsDialog(
        initialApplicationId: app.applicationId,
        initialCompanyId: app.companyId,
        requireCompanyId: requireCompanyId,
      ),
    );
    return ids;
  }

  Future<void> _openCv(_LocalJobApplication app) async {
    final path = app.cvPath;
    try {
      String filePathToOpen = '';

      if (path != null && path.isNotEmpty && await File(path).exists()) {
        filePathToOpen = path;
      } else if (app.applicationId != null && app.applicationId!.isNotEmpty) {
        _showBlockingLoader('Telechargement du CV...');
        filePathToOpen = await _jobApplicationRepository.downloadApplicationCv(
          applicationId: app.applicationId!,
          fallbackFileName: app.cvName,
        );
        _hideBlockingLoader();
      } else {
        if (!mounted) return;
        CustomToast.warning(context, 'CV non disponible localement et identifiant de candidature manquant.');
        return;
      }

      final result = await OpenFilex.open(filePathToOpen);
      if (result.type != ResultType.done && mounted) {
        CustomToast.error(context, 'Impossible d\'ouvrir ce CV: ${result.message}');
      }
    } on MissingPluginException {
      _hideBlockingLoader();
      if (!mounted) return;
      CustomToast.error(context, 'Plugin fichier non charge. Redemarrez completement l\'application.');
    } catch (e) {
      _hideBlockingLoader();
      if (!mounted) return;
      CustomToast.error(context, 'Erreur ouverture CV: $e');
    } finally {
      _hideBlockingLoader();
    }
  }

  Widget _buildApplicationRow(_LocalJobApplication app) {
    final statusLabel = _statusLabel(app.status);
    Color statusBg = const Color(0xFFFFF3E0);
    Color statusFg = const Color(0xFFE65100);
    if (statusLabel == 'En cours') {
      statusBg = const Color(0xFFE3F2FD);
      statusFg = const Color(0xFF1565C0);
    }
    if (statusLabel == 'Entretien') {
      statusBg = const Color(0xFFE2ECFF);
      statusFg = const Color(0xFF2F66D0);
    }
    if (statusLabel == 'Acceptee') {
      statusBg = const Color(0xFFE8F5E9);
      statusFg = const Color(0xFF2E7D32);
    }
    if (statusLabel == 'Refusee') {
      statusBg = const Color(0xFFFFEBEE);
      statusFg = const Color(0xFFC62828);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  app.candidateName,
                  style: TextStyle(
                    color: AppTheme.textColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: statusFg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            app.candidateEmail,
            style: TextStyle(color: AppTheme.textMutedColor, fontSize: 12),
          ),
          if (app.candidatePhone != null && app.candidatePhone!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Tel: ${app.candidatePhone!}',
              style: TextStyle(color: AppTheme.textMutedColor, fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            app.motivation,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppTheme.textColor, height: 1.4),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _TagPill(label: 'CV: ${app.cvName}'),
              _TagPill(label: 'Postule le ${_dateLabel(app.appliedAt)}'),
            ],
          ),
          if (app.interviewAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Entretien le ${_dateLabel(app.interviewAt)}',
              style: TextStyle(color: AppTheme.textMutedColor),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (isOwner) ...[
                TextButton.icon(
                  onPressed: () => _openCv(app),
                  icon: const Icon(Icons.description_outlined, size: 16),
                  label: const Text('Voir CV'),
                ),
                if (statusLabel == 'En attente' || statusLabel == 'En cours')
                  OutlinedButton(
                    onPressed: () async {
                      final picked = await _pickInterviewDateTime();
                      if (picked == null) return;
                      await _updateApplicationStatus(
                        app,
                        'shortlisted',
                        interviewAt: picked,
                      );
                    },
                    child: const Text('Entretien'),
                  ),
                if (statusLabel == 'Entretien')
                  OutlinedButton(
                    onPressed: () => _updateApplicationStatus(app, 'accepted'),
                    child: const Text('Accepter'),
                  ),
                if (statusLabel == 'Entretien')
                  OutlinedButton(
                    onPressed: () => _updateApplicationStatus(app, 'rejected'),
                    child: const Text('Refuser'),
                  ),
              ] else if (app.candidateEmail == _currentCandidateEmail)
                TextButton(
                  onPressed: () => _withdrawApplication(app),
                  child: const Text('Retirer'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher(int applicationsCount) {
    return Row(
      children: [
        Expanded(
          child: _DetailTabChip(
            label: 'Details de l\'offre',
            active: _activeTab == 'details',
            onTap: () => setState(() => _activeTab = 'details'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _DetailTabChip(
            label: 'Candidatures ($applicationsCount)',
            active: _activeTab == 'applications',
            onTap: () => setState(() => _activeTab = 'applications'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final applicationsCount =
        _applications.length > job.applications ? _applications.length : job.applications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Details de l\'offre'),
        backgroundColor: AppTheme.cardColor,
        foregroundColor: AppTheme.textColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _TagPill(label: companyName),
                              _TagPill(label: job.location),
                              _TagPill(label: _contractLabel(job.contractType)),
                              _TagPill(label: _experienceLabel(job.experience)),
                              _TagPill(label: _remoteLabel(job.remotePolicy)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Salaire annuel', style: TextStyle(color: AppTheme.textMutedColor)),
                        const SizedBox(height: 4),
                        Text(
                          (job.salaryMin != null || job.salaryMax != null)
                              ? '${job.salaryMin?.toStringAsFixed(0) ?? '-'} - ${job.salaryMax?.toStringAsFixed(0) ?? '-'}'
                              : 'A negocier',
                          style: const TextStyle(
                            color: Color(0xFFF26E22),
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TagPill(label: '$applicationsCount candidatures'),
                    _TagPill(label: '${job.views} vues'),
                    _TagPill(label: 'Publie le ${_dateLabel(job.createdAt ?? job.publishedAt)}'),
                    _TagPill(label: 'Expiration ${_dateLabel(job.expiresAt)}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildTabSwitcher(applicationsCount),
          const SizedBox(height: 12),
          if (_activeTab == 'details')
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    job.description,
                    style: TextStyle(color: AppTheme.textColor, height: 1.5),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Competences recherchees',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (job.skills.isEmpty)
                    Text(
                      'Aucune competence specifiee.',
                      style: TextStyle(color: AppTheme.textMutedColor),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: job.skills.map((s) => _TagPill(label: s)).toList(),
                    ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Candidatures',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textColor,
                        ),
                      ),
                      const Spacer(),
                      _TagPill(label: '$applicationsCount total'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          'Toutes',
                          'En attente',
                          'Entretien',
                          'Acceptée',
                          'Rejetée',
                        ]
                            .map((status) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(status),
                                    selected: _applicationStatusFilter == status,
                                    onSelected: (selected) {
                                      if (mounted) {
                                        setState(() {
                                          _applicationStatusFilter =
                                              selected ? status : 'Toutes';
                                        });
                                      }
                                    },
                                    backgroundColor:
                                        AppTheme.backgroundColor,
                                    selectedColor: AppColors.primaryColor,
                                    labelStyle: TextStyle(
                                      color: _applicationStatusFilter == status
                                          ? Colors.white
                                          : AppTheme.textColor,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                  if (_isLoadingApplications)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_applications.isEmpty)
                    Text(
                      'Aucune candidature pour le moment.',
                      style: TextStyle(color: AppTheme.textMutedColor),
                    )
                  else if (_filteredApplications.isEmpty)
                    Text(
                      'Aucune candidature avec ce statut.',
                      style: TextStyle(color: AppTheme.textMutedColor),
                    )
                  else
                    Column(
                      children: _filteredApplications
                          .map((application) => _buildApplicationRow(application))
                          .toList(),
                    ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: isOwner
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: ElevatedButton.icon(
                  onPressed: _openApplySheet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.send_outlined),
                  label: Text(AppLocalizations.of(context).applyNow),
                ),
              ),
            ),
    );
  }
}

class _ApplyJobSheet extends StatefulWidget {
  final JobModel job;
  final String companyName;

  const _ApplyJobSheet({required this.job, required this.companyName});

  @override
  State<_ApplyJobSheet> createState() => _ApplyJobSheetState();
}

class _ApplicationIdsResult {
  final String applicationId;
  final String? companyId;

  const _ApplicationIdsResult({
    required this.applicationId,
    this.companyId,
  });
}

class _ApplicationIdsDialog extends StatefulWidget {
  final String? initialApplicationId;
  final String? initialCompanyId;
  final bool requireCompanyId;

  const _ApplicationIdsDialog({
    this.initialApplicationId,
    this.initialCompanyId,
    required this.requireCompanyId,
  });

  @override
  State<_ApplicationIdsDialog> createState() => _ApplicationIdsDialogState();
}

class _ApplicationIdsDialogState extends State<_ApplicationIdsDialog> {
  late final TextEditingController _applicationIdController;
  late final TextEditingController _companyIdController;

  @override
  void initState() {
    super.initState();
    _applicationIdController =
        TextEditingController(text: widget.initialApplicationId ?? '');
    _companyIdController = TextEditingController(text: widget.initialCompanyId ?? '');
  }

  @override
  void dispose() {
    _applicationIdController.dispose();
    _companyIdController.dispose();
    super.dispose();
  }

  void _submit() {
    final applicationId = _applicationIdController.text.trim();
    final companyId = _companyIdController.text.trim();

    if (applicationId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application ID obligatoire')),
      );
      return;
    }

    if (widget.requireCompanyId && companyId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Company ID obligatoire')),
      );
      return;
    }

    Navigator.of(context).pop(
      _ApplicationIdsResult(
        applicationId: applicationId,
        companyId: companyId.isEmpty ? null : companyId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Saisir les IDs backend'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _applicationIdController,
            decoration: const InputDecoration(
              labelText: 'Application ID *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _companyIdController,
            decoration: InputDecoration(
              labelText: widget.requireCompanyId ? 'Company ID *' : 'Company ID',
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context).cancel),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(AppLocalizations.of(context).validate),
        ),
      ],
    );
  }
}

class _ApplyJobSheetState extends State<_ApplyJobSheet> {
  final _formKey = GlobalKey<FormState>();
  final _motivationController = TextEditingController();
  PlatformFile? _cvFile;
  bool _useExistingCv = false;
  bool _submitting = false;

  @override
  void dispose() {
    _motivationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_useExistingCv && _cvFile == null) {
      CustomToast.warning(context, 'Veuillez joindre votre CV (PDF, DOC, DOCX).');
      return;
    }

    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    Navigator.of(context).pop(
      _ApplyJobResult(
        motivation: _motivationController.text.trim(),
        cvName: _useExistingCv ? 'CV enregistre' : (_cvFile?.name ?? 'CV.pdf'),
        cvPath: _useExistingCv ? null : _cvFile?.path,
        cvBytes: _useExistingCv ? null : _cvFile?.bytes,
        useExistingCv: _useExistingCv,
      ),
    );
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
      CustomToast.warning(context, 'Format non supporte. Utilisez PDF, DOC ou DOCX.');
      return;
    }
    final fileSize = file.size;
    if (fileSize > 5 * 1024 * 1024) {
      CustomToast.warning(context, 'Le fichier ne doit pas depasser 5 Mo.');
      return;
    }
    setState(() {
      _cvFile = file;
      _useExistingCv = false;
    });
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Postuler chez ${widget.companyName}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text('Poste: ${widget.job.title}', style: TextStyle(color: AppTheme.textMutedColor)),
              const SizedBox(height: 14),
              _Field(
                controller: _motivationController,
                label: 'Lettre de motivation *',
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Champ obligatoire';
                  }
                  if (value.trim().length < 30) {
                    return 'Minimum 30 caracteres recommandes';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.description_outlined, color: AppTheme.textMutedColor, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Curriculum vitae *',
                            style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _useExistingCv,
                      onChanged: _submitting
                          ? null
                          : (value) {
                              setState(() {
                                _useExistingCv = value ?? false;
                                if (_useExistingCv) {
                                  _cvFile = null;
                                }
                              });
                            },
                      title: const Text('Utiliser mon CV deja enregistre'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    if (!_useExistingCv) ...[
                      const SizedBox(height: 4),
                      OutlinedButton.icon(
                        onPressed: _submitting ? null : _pickCvFile,
                        icon: const Icon(Icons.upload_file_outlined),
                        label: Text(_cvFile == null ? 'Choisir un CV' : 'Changer le CV'),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Formats acceptes: PDF, DOC, DOCX (max 5 Mo)',
                        style: TextStyle(color: AppTheme.textMutedColor, fontSize: 12),
                      ),
                      if (_cvFile != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.dividerColor),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.insert_drive_file_outlined, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${_cvFile!.name} (${_formatBytes(_cvFile!.size)})',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: AppTheme.textColor),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: _submitting
                                    ? null
                                    : () => setState(() => _cvFile = null),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFCC80)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Conseils pour une candidature efficace',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '- Personnalisez votre lettre pour cette offre\n- Mettez en avant vos competences cle\n- Verifiez que votre CV est a jour',
                      style: TextStyle(color: AppTheme.textColor, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
                    child: Text(AppLocalizations.of(context).cancel),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Envoyer ma candidature'),
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

class _CreateJobSheet extends StatefulWidget {
  final CompanyModel company;
  final String currentUserId;
  final JobModel? initial;

  const _CreateJobSheet({
    required this.company,
    required this.currentUserId,
    required this.initial,
  });

  @override
  State<_CreateJobSheet> createState() => _CreateJobSheetState();
}

class _CreateJobSheetState extends State<_CreateJobSheet> {
  final JobRepository _jobRepository = JobRepository();
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _skillsController = TextEditingController();
  final _salaryMinController = TextEditingController();
  final _salaryMaxController = TextEditingController();

  ContractType _contractType = ContractType.CDI;
  ExperienceLevel _experience = ExperienceLevel.OneToThree;
  RemotePolicy _remotePolicy = RemotePolicy.Hybrid;
  JobStatus _status = JobStatus.active;
  bool _submitting = false;
  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    if (i != null) {
      _titleController.text = i.title;
      _descriptionController.text = i.description;
      _locationController.text = i.location;
      _skillsController.text = i.skills.join(', ');
      _salaryMinController.text = i.salaryMin?.toStringAsFixed(0) ?? '';
      _salaryMaxController.text = i.salaryMax?.toStringAsFixed(0) ?? '';
      _contractType = i.contractType;
      _experience = i.experience;
      _remotePolicy = i.remotePolicy;
      _status = i.status;
    } else {
      _locationController.text = widget.company.location ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _skillsController.dispose();
    _salaryMinController.dispose();
    _salaryMaxController.dispose();
    super.dispose();
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

  String _experienceLabel(ExperienceLevel level) {
    switch (level) {
      case ExperienceLevel.Debutant:
        return 'Debutant';
      case ExperienceLevel.OneToThree:
        return '1-3 ans';
      case ExperienceLevel.ThreeToFive:
        return '3-5 ans';
      case ExperienceLevel.FivePlus:
        return '5+ ans';
    }
  }

  String _remoteLabel(RemotePolicy policy) {
    switch (policy) {
      case RemotePolicy.OnSite:
        return 'Sur site';
      case RemotePolicy.Hybrid:
        return 'Hybride';
      case RemotePolicy.FullRemote:
        return 'Full Remote';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
    });

    try {
      final skills = _skillsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final salaryMin = double.tryParse(_salaryMinController.text.trim());
      final salaryMax = double.tryParse(_salaryMaxController.text.trim());

      final payload = JobModel(
        userId: widget.currentUserId,
        companyId: widget.company.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        contractType: _contractType,
        experience: _experience,
        salaryMin: salaryMin,
        salaryMax: salaryMax,
        remotePolicy: _remotePolicy,
        skills: skills,
        status: _status,
      );

      if (_isEditing) {
        final id = widget.initial?.id;
        if (id == null || id.isEmpty) {
          throw Exception('Identifiant offre manquant');
        }
        await _jobRepository.update(id, payload);
      } else {
        await _jobRepository.create(payload);
      }
      if (!mounted) return;
      FocusManager.instance.primaryFocus?.unfocus();
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
      });
      CustomToast.error(context, '${_isEditing ? 'Mise a jour' : 'Publication'} impossible: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing ? 'Modifier l\'offre d\'emploi' : 'Publier une offre d\'emploi',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                _isEditing
                    ? 'Modifiez cette offre pour ${widget.company.name}'
                    : 'Postez une nouvelle offre pour recruter des talents chez ${widget.company.name}',
                style: TextStyle(color: AppTheme.textMutedColor),
              ),
              const SizedBox(height: 12),
              _Field(controller: _titleController, label: 'Titre du poste *', validator: _required),
              _Field(controller: _descriptionController, label: 'Description *', maxLines: 4, validator: _required),
              _Field(controller: _locationController, label: 'Lieu *', validator: _required),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<ContractType>(
                      initialValue: _contractType,
                      decoration: const InputDecoration(labelText: 'Type de contrat'),
                      items: ContractType.values
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(_contractLabel(value)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _contractType = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<ExperienceLevel>(
                      initialValue: _experience,
                      decoration: const InputDecoration(labelText: 'Experience requise'),
                      items: ExperienceLevel.values
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(_experienceLabel(value)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _experience = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<RemotePolicy>(
                      initialValue: _remotePolicy,
                      decoration: const InputDecoration(labelText: 'Modalite de travail'),
                      items: RemotePolicy.values
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(_remoteLabel(value)),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _remotePolicy = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<JobStatus>(
                      initialValue: _status,
                      decoration: const InputDecoration(labelText: 'Statut'),
                      items: const [JobStatus.active, JobStatus.draft]
                          .map((value) => DropdownMenuItem(
                                value: value,
                                child: Text(value == JobStatus.active ? 'Active' : 'Brouillon'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _status = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _Field(controller: _skillsController, label: 'Competences (separees par des virgules)'),
              Row(
                children: [
                  Expanded(
                    child: _Field(
                      controller: _salaryMinController,
                      label: 'Salaire min (optionnel)',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Field(
                      controller: _salaryMaxController,
                      label: 'Salaire max (optionnel)',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: _submitting
                        ? null
                        : () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            Navigator.of(context).pop(false);
                          },
                    child: Text(AppLocalizations.of(context).cancel),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(_isEditing ? 'Mettre a jour l\'offre' : 'Publier l\'offre'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Champ obligatoire';
    }
    return null;
  }
}

// ─────────────────────────────────────────────
// VUE FORMULAIRE
// ─────────────────────────────────────────────
class CompanyFormView extends StatefulWidget {
  final CompanyModel? initial;

  const CompanyFormView({super.key, this.initial});

  @override
  State<CompanyFormView> createState() => _CompanyFormViewState();
}

class _CompanyFormViewState extends State<CompanyFormView> {
  final CompanyRepository _repository = CompanyRepository();
  final ApiClient _apiClient = ApiClient();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _industry;
  late final TextEditingController _description;
  late final TextEditingController _shortDescription;
  late final TextEditingController _website;
  late final TextEditingController _size;
  late final TextEditingController _location;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _keywords;
  bool _loading = false;

  bool get _editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _name = TextEditingController(text: i?.name ?? '');
    _industry = TextEditingController(text: i?.industry ?? '');
    _description = TextEditingController(text: i?.description ?? '');
    _shortDescription = TextEditingController(text: i?.shortDescription ?? '');
    _website = TextEditingController(text: i?.website ?? '');
    _size = TextEditingController(text: i?.size ?? '');
    _location = TextEditingController(text: i?.location ?? '');
    _address = TextEditingController(text: i?.address ?? '');
    _phone = TextEditingController(text: i?.phone ?? '');
    _email = TextEditingController(text: i?.email ?? '');
    _keywords =
        TextEditingController(text: i?.keywords.join(', ') ?? '');
  }

  @override
  void dispose() {
    for (final c in [
      _name, _industry, _description, _shortDescription,
      _website, _size, _location, _address, _phone, _email, _keywords,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final userId = await _apiClient.getUserId() ?? '';
      final payload = CompanyModel(
        id: widget.initial?.id,
        userId: widget.initial?.userId ?? userId,
        name: _name.text.trim(),
        industry: _industry.text.trim(),
        description: _description.text.trim(),
        shortDescription: _shortDescription.text.trim().isEmpty
            ? null
            : _shortDescription.text.trim(),
        website:
            _website.text.trim().isEmpty ? null : _website.text.trim(),
        size: _size.text.trim().isEmpty ? null : _size.text.trim(),
        location:
            _location.text.trim().isEmpty ? null : _location.text.trim(),
        address:
            _address.text.trim().isEmpty ? null : _address.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        keywords: _keywords.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
      );

      if (_editing) {
        final id = widget.initial?.id;
        if (id == null || id.isEmpty) {
          throw Exception('Identifiant entreprise manquant');
        }
        await _repository.update(id, payload);
      } else {
        await _repository.create(payload);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      CustomToast.error(context, 'Operation impossible: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Modifier entreprise' : 'Creer entreprise'),
        backgroundColor: AppTheme.cardColor,
        foregroundColor: AppTheme.textColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _Field(controller: _name, label: 'Nom *', validator: _required),
              _Field(
                  controller: _industry,
                  label: 'Industrie *',
                  validator: _required),
              _Field(
                  controller: _description,
                  label: 'Description *',
                  maxLines: 4,
                  validator: _required),
              _Field(
                  controller: _shortDescription,
                  label: 'Description courte'),
              _Field(
                  controller: _website,
                  label: 'Site web *',
                  validator: _required),
              _Field(controller: _size, label: 'Taille entreprise'),
              _Field(
                  controller: _location,
                  label: 'Localisation *',
                  validator: _required),
              _Field(controller: _address, label: 'Adresse'),
              _Field(controller: _phone, label: 'Telephone'),
              _Field(controller: _email, label: 'Email'),
              _Field(controller: _keywords, label: 'Mots-cles (virgule)'),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_editing ? 'Mettre a jour' : 'Creer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Champ obligatoire';
    return null;
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.primaryColor, width: 2),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ETAT D'ERREUR
// ─────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 44, color: Colors.redAccent),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: onRetry,
              child: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }
}