import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/card_model.dart';
import '../services/pokemon_collection_service.dart';
import '../widgets/card_item.dart';
import '../services/pokemon_api_service.dart';

class PokemonDetailScreen extends StatefulWidget {
  final String pokemonName;
  final String heroTag;

  const PokemonDetailScreen({
    super.key,
    required this.pokemonName,
    required this.heroTag,
  });

  @override
  State<PokemonDetailScreen> createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen> {
  late final PokemonApiService _apiService = PokemonApiService();

  @override
  Widget build(BuildContext context) {
    final service = PokemonCollectionService();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.black : Colors.grey[100];

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true, // Allow content to flow behind AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      body: Container( // Add container to maintain background color
        color: backgroundColor,
        child: FutureBuilder<Map<String, dynamic>>(
          future: Future.wait([
            service.getPokemonStats(widget.pokemonName),
            _apiService.getPokemonDetails(widget.pokemonName),
          ]).then((results) => {
            ...results[0],
            ...results[1],
          }),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _buildErrorView(context, snapshot.error);
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
                SliverToBoxAdapter(
                  child: Container(
                    height: 200, // Reduced from 250
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          isDark ? Colors.grey[900]! : Colors.grey[200]!,
                          isDark ? Colors.black : Colors.white,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Hero(
                        tag: widget.heroTag,
                        child: Image.network(
                          data['spriteUrl'] ?? '',
                          height: 160, // Reduced from 200
                          width: 160, // Reduced from 200
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.none,
                        ),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Container( // Add container for content background
                    color: backgroundColor,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), // Reduced top padding from 16 to 8
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.pokemonName,
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/search',
                                    arguments: widget.pokemonName,
                                  ).then((_) {
                                    // Optionally refresh Pokemon details when returning from search
                                    if (mounted) {
                                      setState(() {});
                                    }
                                  });
                                },
                                icon: const Icon(Icons.search),
                                label: const Text('Search Cards'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.secondary,
                                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                                ),
                              ),
                            ],
                          ),
                          // Stats Overview
                          _buildStatsOverview(context, data),

                          // Pokemon Info
                          if (data['flavorText'] != null)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey[900] : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (types.isNotEmpty)
                                      Wrap(
                                        spacing: 8,
                                        children: types.map((type) => Chip(
                                          label: Text(
                                            type.toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          backgroundColor: _getTypeColor(type),
                                        )).toList(),
                                      ),
                                    if (types.isNotEmpty)
                                      const SizedBox(height: 16),
                                    Text(
                                      data['flavorText'],
                                      style: Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Base Stats
                          if (data['stats'] != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey[900] : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Base Stats',
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildStatBars(data['stats']),
                                  ],
                                ),
                              ),
                            ),

                          // Collection Cards
                          if (cards.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'Collection (${cards.length})',
                                style: Theme.of(context).textTheme.titleLarge,
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
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ...existing helper methods (_buildStatBars, _getTypeColor, etc.)...

  Widget _buildStatsOverview(BuildContext context, Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            context,
            'Height',
            '${data['height']}m',
            Icons.height,
          ),
          _buildStatItem(
            context,
            'Weight',
            '${data['weight']}kg',
            Icons.monitor_weight_outlined,
          ),
          _buildStatItem(
            context,
            'Cards',
            '${data['cardCount']}',
            Icons.style,
          ),
          _buildStatItem(
            context,
            'Value',
            '€${data['totalValue'].toStringAsFixed(2)}',
            Icons.euro,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildErrorView(BuildContext context, Object? error) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.pokemonName)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              error.toString().contains('not authenticated')
                  ? 'Please sign in to view collection details'
                  : 'Error loading details',
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
}
