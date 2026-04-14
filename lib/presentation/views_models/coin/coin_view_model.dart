import 'package:flutter/foundation.dart';
import 'package:cv_tech/core/base/safe_change_notifier.dart';
import 'package:cv_tech/data/models/transaction_model.dart';
import 'package:cv_tech/data/repositories/transaction_repository.dart';

enum CoinState { initial, loading, loaded, error }

/// Shop item model
class ShopItem {
  final String id;
  final String name;
  final String description;
  final int price;
  final IconLabel icon;
  final String category; // 'ia', 'templates', 'boosts'
  final bool isPopular;

  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.icon,
    required this.category,
    this.isPopular = false,
  });
}

enum IconLabel { sparkle, fileText, palette, search, rocket, star, clock, zap }

/// Mission model
class Mission {
  final String id;
  final String title;
  final String subtitle;
  final int reward;
  final int current;
  final int target;
  final bool completed;
  final int? requiredLevel;

  const Mission({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.reward,
    required this.current,
    required this.target,
    this.completed = false,
    this.requiredLevel,
  });

  double get progress => target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
  bool get isLocked => requiredLevel != null;
}

class CoinViewModel extends SafeChangeNotifier {
  final TransactionRepository _repository;

  CoinViewModel({TransactionRepository? repository})
      : _repository = repository ?? TransactionRepository();

  // ── State ──
  CoinState _state = CoinState.initial;
  CoinState get state => _state;

  int _balance = 0;
  int get balance => _balance;

  List<TransactionModel> _transactions = [];
  List<TransactionModel> get transactions => _transactions;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _currentPage = 1;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  // ── Level system ──
  int get level {
    if (_balance >= 5000) return 5;
    if (_balance >= 2000) return 4;
    if (_balance >= 1000) return 3;
    if (_balance >= 500) return 2;
    return 1;
  }

  String get levelName {
    switch (level) {
      case 1: return 'Débutant';
      case 2: return 'Actif';
      case 3: return 'Pro';
      case 4: return 'Expert';
      case 5: return 'Légende';
      default: return 'Débutant';
    }
  }

  int get nextLevelThreshold {
    switch (level) {
      case 1: return 500;
      case 2: return 1000;
      case 3: return 2000;
      case 4: return 5000;
      default: return 5000;
    }
  }

  int get currentLevelThreshold {
    switch (level) {
      case 1: return 0;
      case 2: return 500;
      case 3: return 1000;
      case 4: return 2000;
      case 5: return 5000;
      default: return 0;
    }
  }

  double get levelProgress {
    if (level >= 5) return 1.0;
    final range = nextLevelThreshold - currentLevelThreshold;
    if (range <= 0) return 1.0;
    return ((_balance - currentLevelThreshold) / range).clamp(0.0, 1.0);
  }

  // ── Streak ──
  int _streakDays = 3; // TODO: fetch from backend
  int get streakDays => _streakDays;

  List<bool> get streakWeek {
    return List.generate(7, (i) => i < _streakDays);
  }

  // ── Missions ──
  List<Mission> get dailyMissions => [
    const Mission(
      id: 'login',
      title: 'Connexion quotidienne',
      subtitle: 'Connectez-vous aujourd\'hui',
      reward: 10,
      current: 1,
      target: 1,
      completed: true,
    ),
    const Mission(
      id: 'swipe',
      title: 'Swiper 10 offres',
      subtitle: '7/10 offres swipées',
      reward: 20,
      current: 7,
      target: 10,
    ),
    const Mission(
      id: 'apply',
      title: 'Postuler à une offre',
      subtitle: 'Envoyez une candidature',
      reward: 15,
      current: 0,
      target: 1,
    ),
    const Mission(
      id: 'cv_improve',
      title: 'Améliorer le score CV',
      subtitle: 'Augmentez votre score CV',
      reward: 20,
      current: 0,
      target: 1,
    ),
  ];

  List<Mission> get lockedMissions => [
    const Mission(
      id: 'match',
      title: 'Obtenir un match',
      subtitle: 'Débloquez au niveau 3',
      reward: 100,
      current: 0,
      target: 1,
      requiredLevel: 3,
    ),
    const Mission(
      id: 'interview',
      title: 'Premier entretien',
      subtitle: 'Débloquez au niveau 4',
      reward: 200,
      current: 0,
      target: 1,
      requiredLevel: 4,
    ),
  ];

  // ── Shop items ──
  static const List<ShopItem> iaTools = [
    ShopItem(
      id: 'cv_optimize',
      name: 'Optimisation CV IA',
      description: 'Analyse et suggestions IA',
      price: 200,
      icon: IconLabel.sparkle,
      category: 'ia',
      isPopular: true,
    ),
    ShopItem(
      id: 'cover_letter',
      name: 'Lettre de motivation',
      description: 'Générée par IA',
      price: 150,
      icon: IconLabel.fileText,
      category: 'ia',
    ),
    ShopItem(
      id: 'interview_prep',
      name: 'Préparation entretien',
      description: 'Questions personnalisées',
      price: 300,
      icon: IconLabel.search,
      category: 'ia',
    ),
  ];

  static const List<ShopItem> templates = [
    ShopItem(
      id: 'premium_template',
      name: 'Template Premium',
      description: 'Design professionnel',
      price: 100,
      icon: IconLabel.palette,
      category: 'templates',
      isPopular: true,
    ),
    ShopItem(
      id: 'creative_template',
      name: 'Template Créatif',
      description: 'Design moderne',
      price: 80,
      icon: IconLabel.star,
      category: 'templates',
    ),
  ];

  static const List<ShopItem> boosts = [
    ShopItem(
      id: 'visibility_boost',
      name: 'Boost Visibilité',
      description: '24h de mise en avant',
      price: 250,
      icon: IconLabel.rocket,
      category: 'boosts',
      isPopular: true,
    ),
    ShopItem(
      id: 'priority_review',
      name: 'Revue Prioritaire',
      description: 'Candidature en priorité',
      price: 180,
      icon: IconLabel.clock,
      category: 'boosts',
    ),
    ShopItem(
      id: 'super_like',
      name: 'Super Like',
      description: 'Mettez-vous en avant',
      price: 50,
      icon: IconLabel.zap,
      category: 'boosts',
    ),
  ];

  List<ShopItem> getShopItems(int tabIndex) {
    switch (tabIndex) {
      case 0: return iaTools;
      case 1: return templates;
      case 2: return boosts;
      default: return iaTools;
    }
  }

  // ── Data loading ──
  Future<void> loadData() async {
    _state = CoinState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getBalance(),
        _repository.getAll(page: 1, limit: 20),
      ]);

      _balance = results[0] as int;
      _transactions = results[1] as List<TransactionModel>;
      _currentPage = 1;
      _hasMore = _transactions.length >= 20;
      _state = CoinState.loaded;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _state = CoinState.error;
      if (kDebugMode) print('Coin error: $e');
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (!_hasMore || _state == CoinState.loading) return;

    try {
      _currentPage++;
      final more = await _repository.getAll(page: _currentPage, limit: 20);
      _transactions.addAll(more);
      _hasMore = more.length >= 20;
    } catch (e) {
      _currentPage--;
      if (kDebugMode) print('Load more error: $e');
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    await loadData();
  }

  /// Check if user can afford an item
  bool canAfford(int price) => _balance >= price;

  /// Purchase an item (placeholder — backend integration needed)
  Future<bool> purchaseItem(ShopItem item) async {
    if (!canAfford(item.price)) return false;

    // TODO: call backend purchase endpoint
    _balance -= item.price;
    notifyListeners();
    return true;
  }
}
