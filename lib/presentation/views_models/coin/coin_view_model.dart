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
  // Derived from the "earned" transactions: count consecutive days with
  // at least one earned transaction (login, posts, reactions, etc.)
  int _streakDays = 0;
  int get streakDays => _streakDays;

  List<bool> get streakWeek {
    return List.generate(7, (i) => i < _streakDays);
  }

  /// Compute streak from transaction history (consecutive days with earnings)
  void _computeStreak() {
    if (_transactions.isEmpty) {
      _streakDays = 0;
      return;
    }

    final earned = _transactions
        .where((t) => t.type == TransactionType.earned && t.createdAt != null)
        .map((t) => DateTime(t.createdAt!.year, t.createdAt!.month, t.createdAt!.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // newest first

    if (earned.isEmpty) {
      _streakDays = 0;
      return;
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    int streak = 0;
    DateTime expected = todayDate;

    for (final day in earned) {
      if (day == expected || day == expected.subtract(const Duration(days: 1))) {
        streak++;
        expected = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    _streakDays = streak.clamp(0, 7);
  }

  // ── Missions ──
  // Missions aligned with CvTech's actual feature set: social posts,
  // professional connections, profile completeness and AI CV generation.
  // NOTE: progress values are placeholders; a dedicated backend endpoint
  // will feed real counts once the /missions API is wired in.
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
      id: 'create_post',
      title: 'Publier un post',
      subtitle: 'Partagez une actualité avec votre réseau',
      reward: 20,
      current: 0,
      target: 1,
    ),
    const Mission(
      id: 'react_posts',
      title: 'Réagir à 5 publications',
      subtitle: 'Likez ou commentez 5 posts du feed',
      reward: 15,
      current: 0,
      target: 5,
    ),
    const Mission(
      id: 'send_message',
      title: 'Envoyer un message',
      subtitle: 'Discutez avec un membre de votre réseau',
      reward: 10,
      current: 0,
      target: 1,
    ),
    const Mission(
      id: 'complete_profile',
      title: 'Compléter votre profil',
      subtitle: 'Ajoutez une expérience, une formation ou une compétence',
      reward: 25,
      current: 0,
      target: 1,
    ),
  ];

  List<Mission> get lockedMissions => [
    const Mission(
      id: 'connect_friends',
      title: 'Atteindre 10 connexions',
      subtitle: 'Débloquez au niveau 2',
      reward: 80,
      current: 0,
      target: 10,
      requiredLevel: 2,
    ),
    const Mission(
      id: 'generate_ai_cv',
      title: 'Générer un CV avec l\'IA',
      subtitle: 'Débloquez au niveau 3',
      reward: 120,
      current: 0,
      target: 1,
      requiredLevel: 3,
    ),
    const Mission(
      id: 'download_cv_pdf',
      title: 'Télécharger un CV en PDF',
      subtitle: 'Débloquez au niveau 3',
      reward: 60,
      current: 0,
      target: 1,
      requiredLevel: 3,
    ),
    const Mission(
      id: 'reformulate_cv',
      title: 'Reformuler un CV avec l\'IA',
      subtitle: 'Débloquez au niveau 4',
      reward: 150,
      current: 0,
      target: 1,
      requiredLevel: 4,
    ),
  ];

  // ── Shop items ──
  // Items are tied to real features that exist in CvTech:
  //  - AI CV: generation, reformulation (ai_cv_view, chatbot)
  //  - Templates: the 4 templates available in cv_customization_screen
  //  - Boosts: post visibility, profile highlight, extra AI generations
  static const List<ShopItem> iaTools = [
    ShopItem(
      id: 'ai_cv_generation',
      name: 'Génération CV IA',
      description: 'Créez un CV complet avec l\'IA',
      price: 200,
      icon: IconLabel.sparkle,
      category: 'ia',
      isPopular: true,
    ),
    ShopItem(
      id: 'ai_cv_reformulation',
      name: 'Reformulation IA',
      description: 'Améliorez vos textes de CV',
      price: 120,
      icon: IconLabel.fileText,
      category: 'ia',
    ),
    ShopItem(
      id: 'ai_cover_letter',
      name: 'Lettre de motivation',
      description: 'Générée par IA depuis votre CV',
      price: 150,
      icon: IconLabel.zap,
      category: 'ia',
    ),
  ];

  static const List<ShopItem> templates = [
    ShopItem(
      id: 'template_modern',
      name: 'Template Moderne',
      description: 'Design épuré et professionnel',
      price: 80,
      icon: IconLabel.palette,
      category: 'templates',
      isPopular: true,
    ),
    ShopItem(
      id: 'template_latex',
      name: 'Template LaTeX',
      description: 'Style académique et précis',
      price: 100,
      icon: IconLabel.fileText,
      category: 'templates',
    ),
    ShopItem(
      id: 'template_european',
      name: 'Template Européen',
      description: 'Format CV Europass standard',
      price: 90,
      icon: IconLabel.star,
      category: 'templates',
    ),
  ];

  static const List<ShopItem> boosts = [
    ShopItem(
      id: 'boost_post',
      name: 'Boost de post',
      description: 'Mettez un post en avant 24h',
      price: 150,
      icon: IconLabel.rocket,
      category: 'boosts',
      isPopular: true,
    ),
    ShopItem(
      id: 'boost_profile',
      name: 'Profil en avant',
      description: 'Apparaissez en tête des suggestions',
      price: 200,
      icon: IconLabel.search,
      category: 'boosts',
    ),
    ShopItem(
      id: 'extra_pdf_export',
      name: 'Export PDF illimité',
      description: 'Exportez vos CV sans limite ce mois',
      price: 60,
      icon: IconLabel.clock,
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
      _computeStreak();
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

  /// Purchase an item from the boutique.
  /// Calls the backend /transactions/purchase endpoint which validates the
  /// balance server-side and records the spending transaction.
  Future<bool> purchaseItem(ShopItem item) async {
    if (!canAfford(item.price)) return false;

    try {
      await _repository.purchaseItem(
        itemId: item.id,
        itemName: item.name,
        price: item.price,
      );
      // Refresh balance and transactions from backend
      await loadData();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
