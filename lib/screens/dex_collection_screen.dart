import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/pokemon_collection_service.dart';
import '../services/pokemon_names_service.dart';
import '../services/generation_service.dart';
import '../widgets/pokemon_list_item.dart';
import '../screens/pokemon_detail_screen.dart';
import '../services/pokemon_api_service.dart';

class DexCollectionScreen extends StatefulWidget {
  const DexCollectionScreen({super.key});

  @override
  State<DexCollectionScreen> createState() => _DexCollectionScreenState();
}

class _DexCollectionScreenState extends State<DexCollectionScreen> {
  final _searchController = TextEditingController();
  final _pokemonService = PokemonCollectionService();
  final _namesService = PokemonNamesService();
  final _apiService = PokemonApiService();
  List<String> _allPokemon = [];
  List<String> _filteredPokemon = [];
  bool _isLoading = true;
  String _selectedGeneration = 'All';

  @override
  void initState() {
    super.initState();
    _loadPokemon();
  }

  Future<void> _loadPokemon() async {
    setState(() => _isLoading = true);
    final allPokemon = await _namesService.loadPokemonNames();
    if (mounted) {
      setState(() {
        _allPokemon = allPokemon;
        _filterPokemon(_searchController.text);
        _isLoading = false;
      });
    }
  }

  void _filterPokemon(String query) {
    setState(() {
      var filtered = _allPokemon;
      
      // Apply generation filter
      if (_selectedGeneration != 'All') {
        filtered = GenerationService.filterByGeneration(
          filtered,
          _selectedGeneration,
        );
      }
      
      // Apply search filter
      if (query.isNotEmpty) {
        filtered = filtered
            .where((name) => name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
      
      _filteredPokemon = filtered;
    });
  }

  Widget _buildFilterButton(String label, IconData icon, {
    bool isSelected = false,
    Color? color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonColor = color ?? Theme.of(context).colorScheme.primary;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: isSelected 
            ? buttonColor.withOpacity(isDark ? 0.3 : 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? buttonColor : Colors.grey.withOpacity(0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? buttonColor : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? buttonColor : Colors.grey,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPokemonTile(BuildContext context, int index, bool isDark) {
    final dexNumber = _allPokemon.indexOf(_filteredPokemon[index]) + 1;
    final generation = GenerationService.getGeneration(dexNumber);
    final genColor = GenerationService.getGenerationColor(generation);
    
    return FutureBuilder<Map<String, dynamic>>(
      future: _apiService.getPokemonDetails(_filteredPokemon[index]),
      builder: (context, spriteSnapshot) {
        final spriteUrl = spriteSnapshot.data?['spriteUrl'];
        
        return FutureBuilder<Map<String, dynamic>>(
          future: _pokemonService.getPokemonStats(_filteredPokemon[index]),
          builder: (context, collectionSnapshot) {
            final cardCount = collectionSnapshot.data?['cardCount'] ?? 0;
            final hasCards = cardCount > 0;
            
            return Card(
              elevation: 2,
              margin: const EdgeInsets.all(2),
              child: InkWell(
                onTap: () => _showPokemonDetails(_filteredPokemon[index]),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      // Base color layer
                      Container(
                        decoration: BoxDecoration(
                          color: hasCards 
                              ? Colors.green.withOpacity(0.1)
                              : genColor.withOpacity(0.05),
                          border: hasCards ? Border.all(
                            color: Colors.green.withOpacity(0.3),
                            width: 1,
                          ) : null,
                        ),
                      ),
                      
                      // Updated sprite layer
                      if (spriteUrl != null)
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Image.network(
                              spriteUrl,
                              fit: BoxFit.contain,
                              scale: 0.5, // Make sprites larger
                              filterQuality: FilterQuality.none, // Keep pixel art sharp
                              errorBuilder: (context, error, stackTrace) {
                                print('Error loading sprite: $error');
                                return const SizedBox();
                              },
                            ),
                          ),
                        ),
                      
                      // Updated info overlay
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.0, 0.2, 1.0],
                              colors: [
                                Colors.transparent,
                                isDark ? Colors.black54 : Colors.white70,
                                isDark ? Colors.black87 : Colors.white,
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark 
                                      ? Colors.black.withOpacity(0.7)
                                      : Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '#${dexNumber.toString().padLeft(3, '0')}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                    shadows: [
                                      Shadow(
                                        offset: const Offset(0, 1),
                                        blurRadius: 2,
                                        color: Colors.black.withOpacity(0.3),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _filteredPokemon[index],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                  shadows: [
                                    Shadow(
                                      offset: const Offset(0, 1),
                                      blurRadius: 2,
                                      color: Colors.black.withOpacity(0.3),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (hasCards)
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$cardCount',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Collection indicator
                      if (hasCards)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.8),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(8),
                              ),
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _selectGeneration(String gen) {
    setState(() {
      _selectedGeneration = gen;
      _filterPokemon(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dex Collection'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  _buildFilterButton(
                    'All',
                    Icons.catching_pokemon,
                    isSelected: _selectedGeneration == 'All',
                    onTap: () => _selectGeneration('All'),
                  ),
                  ...GenerationService.generations.keys.map((gen) => 
                    _buildFilterButton(
                      gen.substring(4),
                      Icons.format_list_numbered,
                      isSelected: _selectedGeneration == gen,
                      color: GenerationService.getGenerationColor(gen),
                      onTap: () => _selectGeneration(gen),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Dex...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterPokemon('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
              ),
              onChanged: _filterPokemon,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPokemon.isEmpty
                    ? Center(
                        child: Text(
                          'No results found',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(4),  // Reduced padding
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,  // Changed from 2 to 4
                          childAspectRatio: 0.9, // Adjusted for better proportions
                          crossAxisSpacing: 4,  // Reduced spacing
                          mainAxisSpacing: 4,  // Reduced spacing
                        ),
                        itemCount: _filteredPokemon.length,
                        itemBuilder: (context, index) => _buildPokemonTile(context, index, isDark),
                      ),
          ),
        ],
      ),
    );
  }

  void _showPokemonDetails(String pokemonName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PokemonDetailScreen(pokemonName: pokemonName),
      ),
    );
  }
}
