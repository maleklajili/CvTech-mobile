import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cv_tech/core/base/safe_change_notifier.dart';
import 'package:cv_tech/data/repositories/payment_repository.dart';

enum PaymentState { idle, loading, processing, success, failed, error }

class PlanInfo {
  final String id; // 'free', 'pro', 'gold'
  final String name;
  final double price; // TND
  final String period;
  final String badge;
  final List<PlanFeature> features;

  const PlanInfo({
    required this.id,
    required this.name,
    required this.price,
    required this.period,
    required this.badge,
    required this.features,
  });
}

class PlanFeature {
  final String text;
  final bool included;

  const PlanFeature(this.text, {this.included = true});
}

class BankInfo {
  final String bankName;
  final String iban;
  final String rib;
  final String accountHolder;
  final String swift;

  BankInfo({
    required this.bankName,
    required this.iban,
    required this.rib,
    required this.accountHolder,
    required this.swift,
  });

  factory BankInfo.fromMap(Map<String, dynamic> map) {
    return BankInfo(
      bankName: map['bankName'] ?? '',
      iban: map['iban'] ?? '',
      rib: map['rib'] ?? '',
      accountHolder: map['accountHolder'] ?? '',
      swift: map['swift'] ?? '',
    );
  }
}

class PaymentViewModel extends SafeChangeNotifier {
  final PaymentRepository _repository;

  PaymentViewModel({PaymentRepository? repository})
      : _repository = repository ?? PaymentRepository();

  // ── State ──
  PaymentState _state = PaymentState.idle;
  PaymentState get state => _state;

  String _currentPlan = 'free';
  String get currentPlan => _currentPlan;

  DateTime? _planExpiry;
  DateTime? get planExpiry => _planExpiry;

  int _coins = 0;
  int get coins => _coins;

  String? _selectedPlan;
  String? get selectedPlan => _selectedPlan;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  File? _transferProof;
  File? get transferProof => _transferProof;

  BankInfo? _bankInfo;
  BankInfo? get bankInfo => _bankInfo;

  // ── Plans ──
  static const List<PlanInfo> plans = [
    PlanInfo(
      id: 'free',
      name: 'Gratuit',
      price: 0,
      period: 'pour toujours',
      badge: 'Actuel',
      features: [
        PlanFeature('5 swipes/jour'),
        PlanFeature('1 CV basique'),
        PlanFeature('Analyse IA limitée', included: false),
        PlanFeature('Pas de super likes', included: false),
      ],
    ),
    PlanInfo(
      id: 'pro',
      name: 'Pro',
      price: 19.90,
      period: '/mois · sans engagement',
      badge: 'Recommandé',
      features: [
        PlanFeature('Swipes illimités'),
        PlanFeature('5 CVs + templates premium'),
        PlanFeature('Analyse IA complète'),
        PlanFeature('10 super likes/mois'),
        PlanFeature('500 coins offerts'),
      ],
    ),
    PlanInfo(
      id: 'gold',
      name: 'Gold',
      price: 49.90,
      period: '/mois · tout inclus',
      badge: 'Meilleure valeur',
      features: [
        PlanFeature('Tout du plan Pro'),
        PlanFeature('Matching IA prioritaire'),
        PlanFeature('Super likes illimités'),
        PlanFeature('2 000 coins/mois'),
        PlanFeature('Support prioritaire 24/7'),
      ],
    ),
  ];

  // ── Load current plan ──
  Future<void> loadCurrentPlan() async {
    _state = PaymentState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _repository.getCurrentPlan();
      _currentPlan = data['plan'] as String? ?? 'free';
      _coins = data['coins'] as int? ?? 0;

      final expiryStr = data['planExpiry'];
      _planExpiry =
          expiryStr != null ? DateTime.tryParse(expiryStr.toString()) : null;

      _state = PaymentState.idle;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _state = PaymentState.error;
      if (kDebugMode) print('Plan load error: $e');
    }
    notifyListeners();
  }

  // ── Load bank info ──
  Future<void> loadBankInfo() async {
    try {
      final data = await _repository.getBankInfo();
      _bankInfo = BankInfo.fromMap(data);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Bank info load error: $e');
    }
  }

  // ── Select plan (show transfer form) ──
  void selectPlan(String plan) {
    _selectedPlan = plan;
    _transferProof = null;
    _errorMessage = null;
    notifyListeners();
    loadBankInfo();
  }

  void cancelSelection() {
    _selectedPlan = null;
    _transferProof = null;
    _errorMessage = null;
    notifyListeners();
  }

  // ── Pick transfer proof image ──
  Future<void> pickTransferProof() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked != null) {
      _transferProof = File(picked.path);
      notifyListeners();
    }
  }

  // ── Submit payment request ──
  Future<void> submitPayment() async {
    if (_selectedPlan == null || _transferProof == null) {
      _errorMessage = 'Veuillez sélectionner un plan et joindre la preuve de virement';
      notifyListeners();
      return;
    }

    _state = PaymentState.processing;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.initiatePayment(_selectedPlan!, _transferProof!);

      _state = PaymentState.success;
      notifyListeners();
    } catch (e) {
      _state = PaymentState.failed;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      if (kDebugMode) print('Payment error: $e');
      notifyListeners();
    }
  }

  void resetState() {
    _state = PaymentState.idle;
    _selectedPlan = null;
    _transferProof = null;
    _errorMessage = null;
    notifyListeners();
  }

  String get selectedPlanDisplayName {
    switch (_selectedPlan) {
      case 'pro':
        return 'Pro';
      case 'gold':
        return 'Gold';
      default:
        return '';
    }
  }

  double get selectedPlanPrice {
    switch (_selectedPlan) {
      case 'pro':
        return 19.90;
      case 'gold':
        return 49.90;
      default:
        return 0;
    }
  }

  int get selectedPlanCoins {
    switch (_selectedPlan) {
      case 'pro':
        return 500;
      case 'gold':
        return 2000;
      default:
        return 0;
    }
  }
}
