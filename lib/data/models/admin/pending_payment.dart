class PendingPayment {
  final String id;
  final String userId;
  final String? userName;
  final String plan;
  final int amount;
  final String status;
  final String? transferProof;
  final String? adminNote;
  final DateTime createdAt;

  const PendingPayment({
    required this.id,
    required this.userId,
    this.userName,
    required this.plan,
    required this.amount,
    required this.status,
    this.transferProof,
    this.adminNote,
    required this.createdAt,
  });

  factory PendingPayment.fromJson(Map<String, dynamic> json) {
    return PendingPayment(
      id: json['_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userName: _extractName(json['user']),
      plan: json['plan'] ?? '',
      amount: json['amount'] ?? 0,
      status: json['status'] ?? '',
      transferProof: json['transferProof'],
      adminNote: json['adminNote'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  static String? _extractName(dynamic user) {
    if (user is Map) {
      final first = user['firstName'] ?? '';
      final last = user['lastName'] ?? '';
      final full = '$first $last'.trim();
      return full.isNotEmpty ? full : null;
    }
    return null;
  }

  String get planLabel => plan == 'gold' ? 'Gold' : 'Pro';

  String get amountTnd => '${(amount / 1000).toStringAsFixed(3)} TND';
}
