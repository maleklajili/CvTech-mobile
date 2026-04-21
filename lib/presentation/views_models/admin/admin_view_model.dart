import 'package:flutter/material.dart';
import 'package:cv_tech/data/repositories/admin_repository.dart';
import 'package:cv_tech/data/models/admin/admin_stats.dart';
import 'package:cv_tech/data/models/admin/report_model.dart';
import 'package:cv_tech/data/models/admin/pending_payment.dart';
import 'package:cv_tech/data/models/admin/moderation_models.dart';

enum AdminTab { dashboard, reports, payments, moderation, companies }

enum AdminState { initial, loading, loaded, error }

class AdminViewModel extends ChangeNotifier {
  final AdminRepository _repo;

  AdminViewModel({AdminRepository? repo})
      : _repo = repo ?? AdminRepository();

  // ── State ───────────────────────────────────────────────────────────
  AdminTab _currentTab = AdminTab.dashboard;
  AdminState _state = AdminState.initial;
  String? _errorMessage;

  AdminTab get currentTab => _currentTab;
  AdminState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == AdminState.loading;

  // ── Dashboard data ──────────────────────────────────────────────────
  AdminStats _stats = const AdminStats();
  List<ActivityDay> _activity = [];
  CoinsStats _coinsStats = const CoinsStats();
  TopStats _topStats = const TopStats();

  AdminStats get stats => _stats;
  List<ActivityDay> get activity => _activity;
  CoinsStats get coinsStats => _coinsStats;
  TopStats get topStats => _topStats;

  // ── Reports data ────────────────────────────────────────────────────
  ReportStats _reportStats = const ReportStats();
  List<ReportModel> _reports = [];
  String? _reportFilter;

  ReportStats get reportStats => _reportStats;
  List<ReportModel> get reports => _reports;
  String? get reportFilter => _reportFilter;

  // ── Payments data ───────────────────────────────────────────────────
  List<PendingPayment> _pendingPayments = [];
  bool _actionLoading = false;

  List<PendingPayment> get pendingPayments => _pendingPayments;
  bool get actionLoading => _actionLoading;

  // ── Moderation data ─────────────────────────────────────────────────
  ModerationStats _moderationStats = const ModerationStats();
  List<FlaggedPost> _flaggedPosts = [];
  List<FlaggedUser> _flaggedUsers = [];
  List<FlaggedUser> _bannedUsers = [];
  int _moderationView = 0; // 0=posts, 1=users, 2=banned/deactivated

  ModerationStats get moderationStats => _moderationStats;
  List<FlaggedPost> get flaggedPosts => _flaggedPosts;
  List<FlaggedUser> get flaggedUsers => _flaggedUsers;
  List<FlaggedUser> get bannedUsers => _bannedUsers;
  int get moderationView => _moderationView;

  void setModerationView(int v) {
    _moderationView = v;
    notifyListeners();
  }

  // ── Companies data ──────────────────────────────────────────────────
  List<Map<String, dynamic>> _companies = [];
  String? _companyFilter;

  List<Map<String, dynamic>> get companies => _companies;
  String? get companyFilter => _companyFilter;

  // ── Tab navigation ──────────────────────────────────────────────────
  // Tracks which tabs have been loaded at least once to avoid redundant
  // API calls when the user taps back and forth between tabs.
  final Set<AdminTab> _loadedTabs = <AdminTab>{};

  void switchTab(AdminTab tab, {bool forceReload = false}) {
    if (_currentTab == tab) return;
    _currentTab = tab;
    notifyListeners();
    // Skip refetch if the tab's data is already in memory unless the caller
    // explicitly asked for a refresh (pull-to-refresh etc.).
    if (!forceReload && _loadedTabs.contains(tab)) return;
    _loadTabData();
  }

  // Exposed for pull-to-refresh on the active tab.
  Future<void> refreshCurrentTab() async {
    _loadedTabs.remove(_currentTab);
    await _loadTabData();
  }

  // ── Initial load ────────────────────────────────────────────────────
  Future<void> init() async {
    await _loadTabData();
  }

  Future<void> _loadTabData() async {
    // Prevent overlapping loads when switchTab races with init / resume.
    if (_state == AdminState.loading) return;
    switch (_currentTab) {
      case AdminTab.dashboard:
        await loadDashboard();
        break;
      case AdminTab.reports:
        await loadReports();
        break;
      case AdminTab.payments:
        await loadPendingPayments();
        break;
      case AdminTab.moderation:
        await loadModeration();
        break;
      case AdminTab.companies:
        await loadCompanies();
        break;
    }
    if (_state == AdminState.loaded) {
      _loadedTabs.add(_currentTab);
    }
  }

  // ── Dashboard ───────────────────────────────────────────────────────
  Future<void> loadDashboard() async {
    _state = AdminState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repo.getStats(),
        _repo.getActivity(),
        _repo.getCoinsStats(),
        _repo.getTopStats(),
      ]);
      _stats = results[0] as AdminStats;
      _activity = results[1] as List<ActivityDay>;
      _coinsStats = results[2] as CoinsStats;
      _topStats = results[3] as TopStats;
      _state = AdminState.loaded;
    } catch (e) {
      _state = AdminState.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  // ── Reports ─────────────────────────────────────────────────────────
  Future<void> loadReports({String? status}) async {
    _state = AdminState.loading;
    _reportFilter = status;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repo.getReportStats(),
        _repo.getReports(status: status),
      ]);
      _reportStats = results[0] as ReportStats;
      _reports = results[1] as List<ReportModel>;
      _state = AdminState.loaded;
    } catch (e) {
      _state = AdminState.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  Future<void> updateReportStatus(
    String reportId, {
    required String status,
    String? notes,
  }) async {
    _actionLoading = true;
    notifyListeners();
    try {
      await _repo.updateReportStatus(reportId,
          status: status, resolutionNotes: notes);
      await loadReports(status: _reportFilter);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
    _actionLoading = false;
    notifyListeners();
  }

  Future<void> deleteReport(String reportId) async {
    _actionLoading = true;
    notifyListeners();
    try {
      await _repo.deleteReport(reportId);
      _reports.removeWhere((r) => r.id == reportId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    _actionLoading = false;
    notifyListeners();
  }

  // ── Payments ────────────────────────────────────────────────────────
  Future<void> loadPendingPayments() async {
    _state = AdminState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _pendingPayments = await _repo.getPendingPayments();
      _state = AdminState.loaded;
    } catch (e) {
      _state = AdminState.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  Future<void> approvePayment(String paymentId, {String? note}) async {
    _actionLoading = true;
    notifyListeners();
    try {
      await _repo.approvePayment(paymentId, note: note);
      _pendingPayments.removeWhere((p) => p.id == paymentId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    _actionLoading = false;
    notifyListeners();
  }

  Future<void> rejectPayment(String paymentId, {String? note}) async {
    _actionLoading = true;
    notifyListeners();
    try {
      await _repo.rejectPayment(paymentId, note: note);
      _pendingPayments.removeWhere((p) => p.id == paymentId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    _actionLoading = false;
    notifyListeners();
  }

  // ── Moderation ──────────────────────────────────────────────────────
  Future<void> loadModeration() async {
    _state = AdminState.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repo.getModerationStats(),
        _repo.getFlaggedPosts(),
        _repo.getFlaggedUsers(),
        _repo.getBannedUsers(),
      ]);
      _moderationStats = results[0] as ModerationStats;
      _flaggedPosts = results[1] as List<FlaggedPost>;
      _flaggedUsers = results[2] as List<FlaggedUser>;
      _bannedUsers = results[3] as List<FlaggedUser>;
      _state = AdminState.loaded;
    } catch (e) {
      _state = AdminState.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  Future<void> approvePost(String postId) async {
    _actionLoading = true;
    notifyListeners();
    try {
      await _repo.approvePost(postId);
      _flaggedPosts.removeWhere((p) => p.id == postId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    _actionLoading = false;
    notifyListeners();
  }

  Future<void> rejectPost(String postId) async {
    _actionLoading = true;
    notifyListeners();
    try {
      await _repo.rejectPost(postId);
      _flaggedPosts.removeWhere((p) => p.id == postId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    _actionLoading = false;
    notifyListeners();
  }

  Future<void> banUser(String userId, {String? reason}) async {
    _actionLoading = true;
    notifyListeners();
    try {
      await _repo.banUser(userId, reason: reason);
      final idx = _flaggedUsers.indexWhere((u) => u.id == userId);
      if (idx >= 0) {
        final bannedUser = FlaggedUser.fromJson({
          ..._flaggedUserToMap(_flaggedUsers[idx]),
          'isBanned': true,
          'banReason': reason,
        });
        _flaggedUsers[idx] = bannedUser;
        _bannedUsers.add(bannedUser);
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    _actionLoading = false;
    notifyListeners();
  }

  Future<void> unbanUser(String userId) async {
    _actionLoading = true;
    notifyListeners();
    try {
      await _repo.unbanUser(userId);
      // Remove from banned list
      _bannedUsers.removeWhere((u) => u.id == userId);
      // Update in flagged list if present
      final idx = _flaggedUsers.indexWhere((u) => u.id == userId);
      if (idx >= 0) {
        _flaggedUsers[idx] = FlaggedUser.fromJson({
          ..._flaggedUserToMap(_flaggedUsers[idx]),
          'isBanned': false,
          'isFlagged': false,
          'banReason': null,
        });
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    _actionLoading = false;
    notifyListeners();
  }

  Map<String, dynamic> _flaggedUserToMap(FlaggedUser u) => {
        '_id': u.id,
        'firstName': u.firstName,
        'lastName': u.lastName,
        'email': u.email,
        'image': u.image,
        'isFlagged': u.isFlagged,
        'isBanned': u.isBanned,
        'banReason': u.banReason,
        'fakeScore': u.fakeScore,
        'createdAt': u.createdAt?.toIso8601String(),
        'bannedAt': u.bannedAt?.toIso8601String(),
        'toxicPostCount': u.toxicPostCount,
      };

  // ── Companies ───────────────────────────────────────────────────────
  Future<void> loadCompanies({String? verificationStatus}) async {
    _state = AdminState.loading;
    _companyFilter = verificationStatus;
    _errorMessage = null;
    notifyListeners();
    try {
      _companies = await _repo.getCompanies(
        verificationStatus: verificationStatus,
      );
      _state = AdminState.loaded;
    } catch (e) {
      _state = AdminState.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  Future<void> approveCompany(String companyId, {String? notes}) async {
    _actionLoading = true;
    notifyListeners();
    try {
      await _repo.verifyCompany(companyId, status: 'verified', notes: notes);
      _companies.removeWhere((c) => c['_id'] == companyId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    _actionLoading = false;
    notifyListeners();
  }

  Future<void> rejectCompany(String companyId, {String? notes}) async {
    _actionLoading = true;
    notifyListeners();
    try {
      await _repo.verifyCompany(companyId, status: 'rejected', notes: notes);
      _companies.removeWhere((c) => c['_id'] == companyId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    _actionLoading = false;
    notifyListeners();
  }
}
