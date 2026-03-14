/// Types de réactions : Like / Dislike simple
enum ReactionType {
  like('like', '👍', 'J\'aime', '#0A66C2'),
  dislike('dislike', '👎', 'Je n\'aime pas', '#E53935');

  final String value;
  final String emoji;
  final String label;
  final String color;

  const ReactionType(this.value, this.emoji, this.label, this.color);

  static ReactionType? fromString(String? value) {
    if (value == null) return null;
    return ReactionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ReactionType.like,
    );
  }

  /// Convertir la couleur hex en Color Flutter
  int get colorValue {
    final hexColor = color.replaceAll('#', '');
    return int.parse('FF$hexColor', radix: 16);
  }
}

/// Modèle pour les compteurs de réactions
class ReactionCounts {
  final int like;
  final int dislike;
  final int total;

  const ReactionCounts({
    this.like = 0,
    this.dislike = 0,
    this.total = 0,
  });

  factory ReactionCounts.fromJson(Map<String, dynamic> json) {
    return ReactionCounts(
      like: json['like'] ?? 0,
      dislike: json['dislike'] ?? 0,
      total: json['total'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'like': like,
      'dislike': dislike,
      'total': total,
    };
  }

  /// Créer un objet vide
  factory ReactionCounts.empty() {
    return const ReactionCounts();
  }

  /// Copier avec de nouvelles valeurs
  ReactionCounts copyWith({
    int? like,
    int? dislike,
    int? total,
  }) {
    return ReactionCounts(
      like: like ?? this.like,
      dislike: dislike ?? this.dislike,
      total: total ?? this.total,
    );
  }

  /// Obtenir le compteur pour un type de réaction
  int getCountFor(ReactionType type) {
    switch (type) {
      case ReactionType.like:
        return like;
      case ReactionType.dislike:
        return dislike;
    }
  }

  /// Obtenir les réactions triées par popularité (top 3)
  List<ReactionType> getTopReactions() {
    final reactions = [
      (ReactionType.like, like),
      (ReactionType.dislike, dislike),
    ];

    reactions.sort((a, b) => b.$2.compareTo(a.$2));

    return reactions
        .where((r) => r.$2 > 0)
        .take(2)
        .map((r) => r.$1)
        .toList();
  }

  @override
  String toString() {
    return 'ReactionCounts(like: $like, dislike: $dislike, total: $total)';
  }
}
