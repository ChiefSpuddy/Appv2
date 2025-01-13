import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';  // Add this import
import 'package:provider/provider.dart';
import '../models/card_model.dart';
import '../services/api_service.dart';
import '../services/search_history_service.dart';  // Add this import
import '../widgets/card_item.dart';
import '../services/pokemon_names_service.dart';
import '../services/collection_service.dart';
import '../services/auth_service.dart';
import '../providers/theme_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String _sortBy = 'name';
  bool _showRareOnly = false;
  final _apiService = ApiService();
  final _pokemonService = PokemonNamesService();
  final _collectionService = CollectionService();
  final _searchHistoryService = SearchHistoryService();  // Add this line
  Timer? _debounce;
  List<TcgCard>? _cards;
  List<String> _suggestions = [];
  bool _isLoading = false;
  String? _error;
  late final FocusNode _searchFocusNode;
  int _currentPage = 1;
  int _pageSize = ApiService.defaultPageSize;
  int _totalResults = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchFocusNode = FocusNode();
    _loadPokemonNames();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadPokemonNames() async {
    await _pokemonService.loadPokemonNames();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (_cards != null && _cards!.length < _totalResults) {
        _currentPage++;
        _performSearch(_searchController.text);
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _currentPage = 1; // Reset to first page for new searches
        _performSearch(query);
      }
    });

    // Update suggestions
    if (mounted) {
      setState(() {
        if (query.length >= 2) {
          _suggestions = _pokemonService.getSuggestions(query);
        } else {
          _suggestions = [];
        }
      });
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _cards = null);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _suggestions = []; // Clear suggestions when performing search
    });

    try {
      final results = await _apiService.searchCards(
        query, 
        sortBy: _sortBy,
        rareOnly: _showRareOnly,
        page: _currentPage,
        pageSize: _pageSize,
      );
      
      if (!mounted) return;

      // Save search if it produced results
      if (results['cards'].isNotEmpty) {
        await _searchHistoryService.saveSearch(
          query,
          imageUrl: results['cards'].first.imageUrl,
        );
      }

      setState(() {
        if (_currentPage == 1) {
          _cards = results['cards'];
        } else {
          _cards = [...?_cards, ...results['cards']];
        }
        _totalResults = results['totalCount'];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error searching cards: ${e.toString()}';
        _isLoading = false;
        _cards = null;
      });
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _currentPage = 1;
      _cards = null;
      _totalResults = 0;
      _suggestions = [];
      _error = null;
      _isLoading = false;
    });
  }

  Widget _buildRecentSearchItem(QueryDocumentSnapshot doc) {
    final query = doc['query'] as String;
    String? imageUrl;
    
    try {
      imageUrl = doc.get('image_url') as String?;
    } catch (e) {
      // Field doesn't exist, ignore the error
      imageUrl = null;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        visualDensity: VisualDensity.compact,
        leading: SizedBox(
          width: 40,
          height: 56,
          child: imageUrl != null && imageUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    imageUrl,
                    width: 40,
                    height: 56,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        width: 40,
                        height: 56,
                        color: Colors.grey[200],
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 40,
                      height: 56,
                      color: Colors.grey[200],
                      child: const Icon(Icons.history, color: Colors.grey),
                    ),
                  ),
                )
              : Icon(Icons.history, color: Colors.grey[400]),
        ),
        title: Text(
          query,
          maxLines: 1,
          overflow: TextOverflow.fade,
          softWrap: false,
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.search, size: 20),
              onPressed: () {
                setState(() {
                  _searchController.text = query;
                });
                _performSearch(query);
              },
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.north_west, size: 20),
              onPressed: () {
                setState(() {
                  _searchController.text = query;
                });
                Future.microtask(() {
                  _searchController.selection = TextSelection.fromPosition(
                    TextPosition(offset: query.length),
                  );
                });
              },
            ),
          ],
        ),
        onTap: () {
          setState(() {
            _searchController.text = query;
          });
          _performSearch(query);
        },
      ),
    );
  }

  Widget _buildRecentSearches() {
    return StreamBuilder<QuerySnapshot>(
      key: const ValueKey('recentSearches'),  // Add a stable key
      stream: _searchHistoryService.getRecentSearches(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading searches: ${snapshot.error}',
                  style: TextStyle(color: Colors.red[700]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No recent searches',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Searches',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _searchHistoryService.clearSearchHistory(),
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear All'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                key: const ValueKey('searchHistoryList'),  // Add a stable key
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: snapshot.data!.docs.length,
                separatorBuilder: (context, index) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  // Ensure the doc exists before building
                  if (index >= snapshot.data!.docs.length) return const SizedBox();
                  return _buildRecentSearchItem(snapshot.data!.docs[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSuggestionsList() {
    if (_suggestions.isEmpty) return const SizedBox.shrink();
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return MouseRegion(
      hitTestBehavior: HitTestBehavior.translucent,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          key: const ValueKey('suggestionsList'),
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: _suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = _suggestions[index];
              return InkWell(
                onTap: () {
                  setState(() {
                    _searchController.text = suggestion;
                    _searchController.selection = TextSelection.fromPosition(
                      TextPosition(offset: suggestion.length),
                    );
                    _suggestions = [];
                  });
                  _searchFocusNode.unfocus();
                  _performSearch(suggestion);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    suggestion,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Search cards by name...',
          filled: true,
          fillColor: isDark ? Colors.grey[900] : Colors.grey[200], // Made lighter background darker
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? Colors.grey[400] : Colors.grey[600], // Darker icon in light mode
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: isDark ? Colors.grey[400] : Colors.grey[600], // Darker icon in light mode
                  ),
                  onPressed: _clearSearch,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide( // Add subtle border in light mode
              color: isDark ? Colors.transparent : Colors.grey[300]!,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder( // Add subtle border in light mode
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? Colors.transparent : Colors.grey[300]!,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder( // Add subtle border in light mode
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
              width: 1.5,
            ),
          ),
          hintStyle: TextStyle(
            color: isDark ? Colors.grey[500] : Colors.grey[600], // Darker hint text in light mode
          ),
        ),
        style: TextStyle( // Add explicit text style
          color: isDark ? Colors.grey[200] : Colors.grey[900],
        ),
        onChanged: _onSearchChanged,
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            _currentPage = 1;
            _performSearch(value);
          }
        },
      ),
    );
  }

  Widget _buildMainContent() {
    if (_cards != null) {
      return _isLoading && _currentPage == 1
          ? const Center(child: CircularProgressIndicator())
          : _cards!.isEmpty
              ? const Center(child: Text('No cards found'))
              : _buildResults();
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Search for Pokémon cards'),
                SizedBox(height: 8),
                Text(
                  'Sign in to view your search history',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return _buildRecentSearches();
      },
    );
  }

  Widget _buildPageSizeSelector() {
    return PopupMenuButton<int>(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$_pageSize per page'),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
      itemBuilder: (context) => ApiService.pageSizes.map((size) =>  // Now this will work
        PopupMenuItem(
          value: size,
          child: Text('$size per page'),
        ),
      ).toList(),
      onSelected: (value) {
        setState(() {
          _pageSize = value;
          _currentPage = 1;
          if (_searchController.text.isNotEmpty) {
            _performSearch(_searchController.text);
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(  // Add this Material widget
      child: Focus(
        onFocusChange: (hasFocus) {
          if (!hasFocus) {
            _searchFocusNode.unfocus();
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) {
            // Check if tap is not on a text field before unfocusing
            if (!_searchFocusNode.hasFocus) {
              _searchFocusNode.unfocus();
            }
          },
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor, // Light background
            child: Column(
              children: [
                AppBar(
                  elevation: 0,
                  backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                  iconTheme: Theme.of(context).appBarTheme.iconTheme,
                  title: Text(
                    'TCG Card Search',
                    style: TextStyle(
                      color: Theme.of(context).appBarTheme.foregroundColor,
                    ),
                  ),
                  actions: [
                    // Add clear button before the menu
                    IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear Search',
                      onPressed: _clearSearch,
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.menu),
                      onSelected: (value) async {
                        switch (value) {
                          case 'sort_name':
                            setState(() => _sortBy = 'name');
                            if (_cards != null) _performSearch(_searchController.text);
                            break;
                          case 'sort_number':
                            setState(() => _sortBy = 'number');
                            if (_cards != null) _performSearch(_searchController.text);
                            break;
                          case 'sort_price':
                            setState(() => _sortBy = 'price');
                            if (_cards != null) _performSearch(_searchController.text);
                            break;
                          case 'toggle_theme':
                            Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                            break;
                          case 'toggle_rare':
                            setState(() => _showRareOnly = !_showRareOnly);
                            if (_cards != null) _performSearch(_searchController.text);
                            break;
                          case 'logout':
                            final authService = AuthService();
                            await authService.signOut();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Logged out successfully')),
                              );
                            }
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem<String>(
                          value: 'toggle_theme',
                          child: ListTile(
                            dense: true,
                            leading: Icon(
                              Provider.of<ThemeProvider>(context, listen: false).isDarkMode 
                                  ? Icons.light_mode 
                                  : Icons.dark_mode
                            ),
                            title: Text(
                              Provider.of<ThemeProvider>(context, listen: false).isDarkMode
                                  ? 'Light Mode'
                                  : 'Dark Mode'
                            ),
                          ),
                        ),
                        const PopupMenuDivider(),
                        // ...existing menu items...
                        const PopupMenuItem(
                          value: 'sort_name',
                          child: ListTile(
                            dense: true,
                            leading: Icon(Icons.sort_by_alpha),
                            title: Text('Sort by Name'),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'sort_number',
                          child: ListTile(
                            dense: true,
                            leading: Icon(Icons.format_list_numbered),
                            title: Text('Sort by Number'),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'sort_price',
                          child: ListTile(
                            dense: true,
                            leading: Icon(Icons.attach_money),
                            title: Text('Sort by Price'),
                          ),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'toggle_rare',
                          child: ListTile(
                            dense: true,
                            leading: Icon(Icons.star),
                            title: Text(_showRareOnly ? 'Show All Cards' : 'Show Rare Only'),
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Logout'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Expanded(
                  child: Column(
                    children: [
                      _buildSearchBar(),
                      if (_cards != null && _totalResults > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_totalResults} cards found',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              _buildPageSizeSelector(),
                            ],
                          ),
                        ),
                      Expanded(
                        child: _isLoading && _currentPage == 1
                            ? const Center(child: CircularProgressIndicator())
                            : _buildMainContent(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _performSearch(_searchController.text),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_cards?.isEmpty ?? false) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No cards found for "${_searchController.text}"',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,  // Add scroll controller
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 0.65,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _cards!.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _cards!.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return Stack(
          clipBehavior: Clip.none,
          children: [
            CardItem(card: _cards![index]),
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 2,
                    ),
                  ],
                ),
                child: IconButton(
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minHeight: 24,
                    minWidth: 24,
                  ),
                  icon: const Icon(Icons.add_circle, color: Colors.white),
                  tooltip: 'Add to Collection',
                  onPressed: () => _addToCollection(_cards![index]),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addToCollection(TcgCard card) async {
    try {
      await _collectionService.addCard(card);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added ${card.name} to collection')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add card')),
      );
    }
  }
}