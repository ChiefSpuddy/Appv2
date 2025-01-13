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
  String _selectedType = 'All';
  String _collectionFilter = 'All'; // 'All', 'Collected', 'Missing'
  String _sortBy = 'Number'; // 'Number', 'Name', 'Collection'
  bool _sortAscending = true;

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

  Future<void> _filterPokemon(String query) async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      var filtered = List<String>.from(_allPokemon);
      
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

      // Apply type filter - Get Pokemon by type first if type filter is active
      if (_selectedType != 'All') {
        final typeFiltered = await _apiService.getPokemonByType(_selectedType);
        filtered = filtered.where((name) => 
          typeFiltered.any((typeName) => 
            typeName.toLowerCase() == name.toLowerCase()
          )
        ).toList();
      }

      // Apply collection filter more efficiently
      if (_collectionFilter != 'All') {
        final List<String> collectionFiltered = [];
        
        // Get all collection stats at once
        final futures = filtered.map((name) => _pokemonService.getPokemonStats(name));
        final results = await Future.wait(futures);
        
        for (var i = 0; i < filtered.length; i++) {
          final stats = results[i];
          final cardCount = (stats['cardCount'] as num?)?.toInt() ?? 0;
          final hasCards = cardCount > 0;
          
          if ((_collectionFilter == 'Collected' && hasCards) ||
              (_collectionFilter == 'Missing' && !hasCards)) {
            collectionFiltered.add(filtered[i]);
          }
        }
        
        filtered = collectionFiltered;
      }

      // Apply sorting with safe index lookup
      filtered.sort((a, b) {
        if (_sortBy == 'Number') {
          final numA = _getDexNumber(a);
          final numB = _getDexNumber(b);
          return _sortAscending ? numA.compareTo(numB) : numB.compareTo(numA);
        } else if (_sortBy == 'Name') {
          return _sortAscending ? a.compareTo(b) : b.compareTo(a);
        } else { // Collection
          return 0; // Will be implemented with actual collection count
        }
      });
      
      if (mounted) {
        setState(() {
          _filteredPokemon = filtered;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error filtering pokemon: $e');
      if (mounted) {
        setState(() {
          _filteredPokemon = _allPokemon; // Fallback to showing all Pokemon
          _isLoading = false;
        });
      }
    }
  }

  // Helper method to safely get dex number
  int _getDexNumber(String pokemonName) {
    final index = _allPokemon.indexOf(pokemonName);
    return index >= 0 ? index + 1 : 999999; // Put unknown Pokemon at the end
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
    final dexNumber = _getDexNumber(_filteredPokemon[index]);
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

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'fire':
        return Icons.local_fire_department;
      case 'water':
        return Icons.water_drop;
      case 'grass':
        return Icons.grass;
      case 'electric':
        return Icons.electric_bolt;
      case 'psychic':
        return Icons.psychology;
      case 'fighting':
        return Icons.sports_mma;
      case 'ground':
        return Icons.landscape;
      case 'rock':
        return Icons.terrain;
      case 'flying':
        return Icons.air;
      case 'bug':
        return Icons.bug_report;
      case 'poison':
        return Icons.science;
      case 'normal':
        return Icons.circle_outlined;
      case 'ghost':
        return Icons.nights_stay;
      case 'ice':
        return Icons.ac_unit;
      case 'dragon':
        return Icons.auto_awesome;
      case 'dark':
        return Icons.dark_mode;
      case 'steel':
        return Icons.shield;
      case 'fairy':
        return Icons.auto_fix_high;
      default:
        return Icons.catching_pokemon;
    }
  }

  Widget _buildActiveFilters() {
    if (_selectedType == 'All' && _collectionFilter == 'All' && _sortBy == 'Number') {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          if (_selectedType != 'All')
            Chip(
              avatar: Icon(_getTypeIcon(_selectedType), size: 16),
              label: Text(_selectedType),
              onDeleted: () => setState(() {
                _selectedType = 'All';
                _filterPokemon(_searchController.text);
              }),
            ),
          if (_collectionFilter != 'All')
            Chip(
              avatar: const Icon(Icons.folder, size: 16),
              label: Text(_collectionFilter),
              onDeleted: () => setState(() {
                _collectionFilter = 'All';
                _filterPokemon(_searchController.text);
              }),
            ),
          if (_sortBy != 'Number' || !_sortAscending)
            Chip(
              avatar: Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
              ),
              label: Text('Sort: $_sortBy'),
              onDeleted: () => setState(() {
                _sortBy = 'Number';
                _sortAscending = true;
                _filterPokemon(_searchController.text);
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterMenu() {
    return PopupMenuButton<String>(
      tooltip: 'Sort and Filter',
      icon: Stack(
        children: [
          const Icon(Icons.tune),
          if (_selectedType != 'All' || _collectionFilter != 'All' || _sortBy != 'Number')
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 12,
                  minHeight: 12,
                ),
              ),
            ),
        ],
      ),
      onSelected: (value) {
        // Handle filter selection
        final parts = value.split(':');
        final category = parts[0];
        final option = parts[1];

        setState(() {
          switch (category) {
            case 'type':
              _selectedType = option;
              break;
            case 'collection':
              _collectionFilter = option;
              break;
            case 'sort':
              if (_sortBy == option) {
                _sortAscending = !_sortAscending;
              } else {
                _sortBy = option;
                _sortAscending = true;
              }
              break;
          }
          _filterPokemon(_searchController.text);
        });
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.catching_pokemon),
            title: const Text('Pokémon Types'),
            trailing: const Icon(Icons.arrow_right),
            contentPadding: EdgeInsets.zero,
            onTap: () {
              Navigator.pop(context);
              _showTypeSelector(context);
            },
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          enabled: false,
          child: Text(
            'Collection Status',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ...['All', 'Collected', 'Missing'].map((status) => PopupMenuItem(
          value: 'collection:$status',
          child: Row(
            children: [
              Icon(
                status == 'Collected' ? Icons.check_circle
                : status == 'Missing' ? Icons.remove_circle
                : Icons.all_inclusive,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(status),
              if (_collectionFilter == status)
                const Spacer(),
              if (_collectionFilter == status)
                const Icon(Icons.check, size: 20),
            ],
          ),
        )),
        const PopupMenuDivider(),
        const PopupMenuItem(
          enabled: false,
          child: Text(
            'Sort By',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ...['Number', 'Name', 'Collection'].map((sort) => PopupMenuItem(
          value: 'sort:$sort',
          child: Row(
            children: [
              Icon(
                sort == 'Number' ? Icons.tag
                : sort == 'Name' ? Icons.sort_by_alpha
                : Icons.style,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(sort),
              if (_sortBy == sort)
                const Spacer(),
              if (_sortBy == sort)
                Icon(
                  _sortAscending
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  size: 20,
                ),
            ],
          ),
        )),
      ],
    );
  }

  void _showTypeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text(
              'Select Type',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              padding: const EdgeInsets.all(16),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                _buildTypeButton('All'),
                ...[
                  'Fire', 'Water', 'Grass', 'Electric', 'Psychic',
                  'Fighting', 'Ground', 'Rock', 'Flying', 'Bug',
                  'Poison', 'Normal', 'Ghost', 'Ice', 'Dragon',
                  'Dark', 'Steel', 'Fairy'
                ].map((type) => _buildTypeButton(type)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String type) {
    final isSelected = _selectedType == type;
    final typeColor = type == 'All' ? Colors.grey : _getTypeColor(type);
    final gradientColors = _getTypeGradient(type);
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedType = type;
            _filterPokemon(_searchController.text);
          });
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: typeColor.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                type == 'All' ? Icons.all_inclusive : _getTypeIcon(type),
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                type,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: isSelected ? FontWeight.bold : null,
                  shadows: [
                    Shadow(
                      offset: const Offset(1, 1),
                      blurRadius: 2,
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getTypeGradient(String type) {
    final baseColor = type == 'All' ? Colors.grey : _getTypeColor(type);
    final gradients = {
      'fire': [const Color(0xFFF08030), const Color(0xFFDD6610)],
      'water': [const Color(0xFF6890F0), const Color(0xFF386CEB)],
      'grass': [const Color(0xFF78C850), const Color(0xFF5CA935)],
      'electric': [const Color(0xFFF8D030), const Color(0xFFF0C000)],
      'psychic': [const Color(0xFFF85888), const Color(0xFFEB386E)],
      'fighting': [const Color(0xFFC03028), const Color(0xFFA52A2A)],
      'ground': [const Color(0xFFE0C068), const Color(0xFFC6A048)],
      'rock': [const Color(0xFFB8A038), const Color(0xFF8B7355)],
      'flying': [const Color(0xFFA890F0), const Color(0xFF9180C4)],
      'bug': [const Color(0xFFA8B820), const Color(0xFF8B9A1B)],
      'poison': [const Color(0xFFA040A0), const Color(0xFF682A68)],
      'normal': [const Color(0xFFA8A878), const Color(0xFF6D6D4E)],
      'ghost': [const Color(0xFF705898), const Color(0xFF493963)],
      'ice': [const Color(0xFF98D8D8), const Color(0xFF69C6C6)],
      'dragon': [const Color(0xFF7038F8), const Color(0xFF4C08EF)],
      'dark': [const Color(0xFF705848), const Color(0xFF49392F)],
      'steel': [const Color(0xFFB8B8D0), const Color(0xFF787887)],
      'fairy': [const Color(0xFFEE99AC), const Color(0xFFF4BDC9)],
    };

    return gradients[type.toLowerCase()] ?? [
      baseColor,
      baseColor.withOpacity(0.7),
    ];
  }

  Color _getTypeColor(String type) {
    final colors = {
      'normal': const Color(0xFFA8A878),
      'fire': const Color(0xFFF08030),
      'water': const Color(0xFF6890F0),
      // ...existing type colors...
    };
    return colors[type.toLowerCase()] ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dex Collection'),
        actions: [
          _buildFilterMenu(),
        ],
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
          _buildActiveFilters(),
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
        builder: (context) => PokemonDetailScreen(
          pokemonName: pokemonName,
          heroTag: 'pokemon_sprite_$pokemonName',
        ),
      ),
    );
  }
}
