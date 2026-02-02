enum TransactionType { earned, spent, purchased }

enum TransactionItemType { experience, education, project, skill, language, technicalSkill }

class TransactionModel {
  final String? id;
  final String userId;
  final int amount;
  final TransactionType type;
  final String description;
  final TransactionItemType? itemType;
  final String? itemId;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;

  TransactionModel({
    this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.description,
    this.itemType,
    this.itemId,
    this.metadata,
    this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['_id'] ?? json['id'],
      userId: json['userId'] ?? '',
      amount: json['amount'] ?? 0,
      type: _typeFromString(json['type']),
      description: json['description'] ?? '',
      itemType: json['itemType'] != null
          ? _itemTypeFromString(json['itemType'])
          : null,
      itemId: json['itemId'],
      metadata: json['metadata'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'userId': userId,
      'amount': amount,
      'type': _typeToString(type),
      'description': description,
      if (itemType != null) 'itemType': _itemTypeToString(itemType!),
      if (itemId != null) 'itemId': itemId,
      if (metadata != null) 'metadata': metadata,
    };
  }

  static TransactionType _typeFromString(String? type) {
    switch (type) {
      case 'earned':
        return TransactionType.earned;
      case 'spent':
        return TransactionType.spent;
      case 'purchased':
        return TransactionType.purchased;
      default:
        return TransactionType.earned;
    }
  }

  static String _typeToString(TransactionType type) {
    switch (type) {
      case TransactionType.earned:
        return 'earned';
      case TransactionType.spent:
        return 'spent';
      case TransactionType.purchased:
        return 'purchased';
    }
  }

  static TransactionItemType _itemTypeFromString(String? type) {
    switch (type) {
      case 'experience':
        return TransactionItemType.experience;
      case 'education':
        return TransactionItemType.education;
      case 'project':
        return TransactionItemType.project;
      case 'skill':
        return TransactionItemType.skill;
      case 'language':
        return TransactionItemType.language;
      case 'technicalSkill':
        return TransactionItemType.technicalSkill;
      default:
        return TransactionItemType.experience;
    }
  }

  static String _itemTypeToString(TransactionItemType type) {
    switch (type) {
      case TransactionItemType.experience:
        return 'experience';
      case TransactionItemType.education:
        return 'education';
      case TransactionItemType.project:
        return 'project';
      case TransactionItemType.skill:
        return 'skill';
      case TransactionItemType.language:
        return 'language';
      case TransactionItemType.technicalSkill:
        return 'technicalSkill';
    }
  }
}
