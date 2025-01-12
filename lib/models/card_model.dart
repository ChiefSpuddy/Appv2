class TcgCard {
  final String id;
  final String name;
  final String imageUrl;
  final String setName;
  final String rarity;
  final double? price;
  final String setNumber;

  TcgCard({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.setName,
    required this.rarity,
    this.price,
    this.setNumber = '',
  });

  factory TcgCard.fromJson(Map<String, dynamic> json) {
    return TcgCard(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['images']?['small'] ?? '',
      setName: json['set']?['name'] ?? '',
      rarity: json['rarity'] ?? '',
      price: double.tryParse(json['cardmarket']?['prices']?['averageSellPrice']?.toString() ?? ''),
      setNumber: json['number'] ?? '',
    );
  }
}