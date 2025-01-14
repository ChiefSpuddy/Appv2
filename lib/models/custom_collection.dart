class CustomCollection {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final List<String> cardIds;
  final double? totalValue;
  final List<String> tags;  // Add this
  final String? shareCode;  // Add this
  final List<Map<String, dynamic>> notes;  // Add this
  final List<Map<String, dynamic>> priceHistory;  // Add this

  CustomCollection({
    required this.id,
    required this.name,
    this.description = '',
    required this.createdAt,
    required this.cardIds,
    this.totalValue,
    this.tags = const [],
    this.shareCode,
    this.notes = const [],
    this.priceHistory = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'createdAt': createdAt,
      'cardIds': cardIds,
      'tags': tags,
      'shareCode': shareCode,
      'notes': notes,
      'priceHistory': priceHistory,
    };
  }

  factory CustomCollection.fromMap(String id, Map<String, dynamic> map) {
    return CustomCollection(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      createdAt: (map['createdAt'] as DateTime?) ?? DateTime.now(),
      cardIds: List<String>.from(map['cardIds'] ?? []),
      totalValue: map['totalValue']?.toDouble(),
      tags: List<String>.from(map['tags'] ?? []),
      shareCode: map['shareCode'],
      notes: List<Map<String, dynamic>>.from(map['notes'] ?? []),
      priceHistory: List<Map<String, dynamic>>.from(map['priceHistory'] ?? []),
    );
  }

  CustomCollection copyWith({
    String? name,
    String? description,
    DateTime? createdAt,
    List<String>? cardIds,
    double? totalValue,
    List<String>? tags,
    String? shareCode,
    List<Map<String, dynamic>>? notes,
    List<Map<String, dynamic>>? priceHistory,
  }) {
    return CustomCollection(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      cardIds: cardIds ?? this.cardIds,
      totalValue: totalValue ?? this.totalValue,
      tags: tags ?? this.tags,
      shareCode: shareCode ?? this.shareCode,
      notes: notes ?? this.notes,
      priceHistory: priceHistory ?? this.priceHistory,
    );
  }
}
