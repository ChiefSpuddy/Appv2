import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';  // Add this import
import '../models/card_model.dart';
import '../services/pokemon_collection_service.dart';
import '../widgets/card_item.dart';
import '../services/pokemon_api_service.dart';

class PokemonDetailScreen extends StatelessWidget {
  final String pokemonName;
  late final PokemonApiService _apiService = PokemonApiService();

  PokemonDetailScreen({
    super.key,
    required this.pokemonName,
  });

  @override
  Widget build(BuildContext context) {
    final service = PokemonCollectionService();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(pokemonName),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: Future.wait([
          service.getPokemonStats(pokemonName),
          _apiService.getPokemonDetails(pokemonName),
        ]).then((results) => {
          ...results[0], // Collection stats (may be empty)
          ...results[1], // Pokemon details from PokeAPI
        }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    snapshot.error.toString().contains('not authenticated')
                        ? 'Please sign in to view collection details'
                        : 'Error loading details: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                  if (FirebaseAuth.instance.currentUser == null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Sign in to view collection'),
                      ),
                    ),
                ],
              ),
            );
          }

          final data = snapshot.data ?? {
            'cardCount': 0,
            'totalValue': 0.0,
            'variants': 0,
            'cards': <TcgCard>[],
          };

          final cards = data['cards'] as List<TcgCard>;
          final types = (data['types'] as List<String>?) ?? [];

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(pokemonName),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (data['spriteUrl'] != null)
                        Image.network(
                          data['spriteUrl'],
                          fit: BoxFit.contain,
                          color: isDark ? Colors.white10 : Colors.black12,
                          colorBlendMode: BlendMode.darken,
                        ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (types.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              children: types.map((type) => Chip(
                                label: Text(
                                  type.toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: _getTypeColor(type),
                              )).toList(),
                            ),
                          const SizedBox(height: 16),
                          if (data['flavorText'] != null) ...[
                            Text(
                              data['flavorText'],
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 16),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStat('Height', '${data['height']}m'),
                              _buildStat('Weight', '${data['weight']}kg'),
                              _buildStat('Cards', data['cardCount'].toString()),
                              _buildStat('Value', '€${data['totalValue'].toStringAsFixed(2)}'),
                            ],
                          ),
                          if (data['stats'] != null) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Base Stats',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildStatBars(data['stats']),
                          ],
                        ],
                      ),
                    ),
                    if (cards.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Collected Cards',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: cards.length,
                        itemBuilder: (context, index) => CardItem(
                          card: cards[index],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatBars(Map<String, dynamic> stats) {
    return Column(
      children: [
        _buildStatBar('HP', stats['hp'], Colors.red),
        _buildStatBar('Attack', stats['attack'], Colors.orange),
        _buildStatBar('Defense', stats['defense'], Colors.blue),
        _buildStatBar('Sp. Atk', stats['spAtk'], Colors.purple),
        _buildStatBar('Sp. Def', stats['spDef'], Colors.green),
        _buildStatBar('Speed', stats['speed'], Colors.pink),
      ],
    );
  }

  Widget _buildStatBar(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label),
          ),
          SizedBox(
            width: 40,
            child: Text(
              value.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value / 255,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    final colors = {
      'normal': const Color(0xFFA8A878),
      'fire': const Color(0xFFF08030),
      'water': const Color(0xFF6890F0),
      'electric': const Color(0xFFF8D030),
      'grass': const Color(0xFF78C850),
      'ice': const Color(0xFF98D8D8),
      'fighting': const Color(0xFFC03028),
      'poison': const Color(0xFFA040A0),
      'ground': const Color(0xFFE0C068),
      'flying': const Color(0xFFA890F0),
      'psychic': const Color(0xFFF85888),
      'bug': const Color(0xFFA8B820),
      'rock': const Color(0xFFB8A038),
      'ghost': const Color(0xFF705898),
      'dragon': const Color(0xFF7038F8),
      'dark': const Color(0xFF705848),
      'steel': const Color(0xFFB8B8D0),
      'fairy': const Color(0xFFEE99AC),
    };
    return colors[type.toLowerCase()] ?? Colors.grey;
  }

  Widget _buildStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
