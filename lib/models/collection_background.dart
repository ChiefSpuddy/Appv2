class CollectionBackground {
  final String id;
  final String name;
  final String previewUrl;
  final Map<String, dynamic> style;
  final bool isPremium;
  final bool isUnlocked;
  
  CollectionBackground({
    required this.id,
    required this.name,
    required this.previewUrl,
    required this.style,
    this.isPremium = false,
    this.isUnlocked = false,
  });

  factory CollectionBackground.fromMap(Map<String, dynamic> map, {bool isUnlocked = false}) {
    return CollectionBackground(
      id: map['id'],
      name: map['name'],
      previewUrl: map['previewUrl'],
      style: Map<String, dynamic>.from(map['style']),
      isPremium: map['isPremium'] ?? false,
      isUnlocked: isUnlocked,
    );
  }
}
