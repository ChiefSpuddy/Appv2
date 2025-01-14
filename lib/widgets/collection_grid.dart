import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/collection_service.dart';
import '../widgets/card_item.dart';
import '../models/card_model.dart';
import '../models/custom_collection.dart';
import '../screens/custom_collections_screen.dart';  // Make sure this path is correct

class CollectionGrid extends StatefulWidget {
  const CollectionGrid({super.key});

  @override
  State<CollectionGrid> createState() => _CollectionGridState();
}

class _CollectionGridState extends State<CollectionGrid> {
  final CollectionService _service = CollectionService();
  bool _selectionMode = false;
  final Set<String> _selectedCards = {};
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) {
        _selectedCards.clear();
      }
    });
  }

  void _toggleCardSelection(String cardId) {
    setState(() {
      if (_selectedCards.contains(cardId)) {
        _selectedCards.remove(cardId);
      } else {
        _selectedCards.add(cardId);
      }
      
      if (_selectedCards.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  Future<void> _showAddToCollectionDialog({String? singleCardId}) async {
    final cardIds = singleCardId != null ? [singleCardId] : _selectedCards.toList();
    if (cardIds.isEmpty) return;

    final collections = await _service.getCustomCollections();
    
    if (!context.mounted) return;

    final result = await showDialog<CustomCollection>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add to Collection'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Create New Collection'),
                onTap: () async {
                  Navigator.pop(context);
                  await _showCreateCollectionDialog();
                },
              ),
              const Divider(),
              ...collections.map((collection) => ListTile(
                title: Text(collection.name),
                subtitle: Text('${collection.cardIds.length} cards'),
                onTap: () => Navigator.pop(context, collection),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );

    if (result != null) {
      await _service.addCardsToCollection(result.id, cardIds);
      setState(() {
        _selectionMode = false;
        _selectedCards.clear();
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${cardIds.length} cards to ${result.name}')),
        );
      }
    }
  }

  Future<void> _showCreateCollectionDialog() async {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String description = '';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Collection'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => 
                  value?.isEmpty == true ? 'Please enter a name' : null,
                onSaved: (value) => name = value ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Description'),
                onSaved: (value) => description = value ?? '',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('Create'),
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                formKey.currentState?.save();
                Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),
    );

    if (result == true) {
      final collection = await _service.createCustomCollection(name, description);
      await _service.addCardsToCollection(collection.id, _selectedCards.toList());
      
      setState(() {
        _selectionMode = false;
        _selectedCards.clear();
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Created collection "$name"')),
        );
      }
    }
  }

  Future<void> _showRemoveDialog(BuildContext context, String cardId, String cardName) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Card'),
          content: Text('Remove $cardName from your collection?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text(
                'Remove',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                _service.removeCard(cardId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCardOptionsDialog(String docId, TcgCard card) async {
    return showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.collections_bookmark),
                title: const Text('Add to Custom Collection'),
                onTap: () async {
                  Navigator.pop(context);
                  await _showAddToCollectionDialog(singleCardId: docId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove from Collection'),
                onTap: () async {
                  Navigator.pop(context);
                  await _showRemoveConfirmation(docId, card.name);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showRemoveConfirmation(String docId, String cardName) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Card'),
        content: Text('Are you sure you want to remove $cardName from your collection?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              await _service.removeCard(docId);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Removed $cardName')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Column(
        children: [
          // Remove Portfolio Value Card from here
          // ...rest of existing collection grid code...
          if (_selectionMode) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Row(
                children: [
                  Text(
                    '${_selectedCards.length} selected',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add to Collection'),
                    onPressed: _selectedCards.isEmpty ? null : _showAddToCollectionDialog,
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('Delete', style: TextStyle(color: Colors.red)),
                    onPressed: _selectedCards.isEmpty ? null : () => _showBulkDeleteConfirmation(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _toggleSelectionMode,
                  ),
                ],
              ),
            ),
          ],
          
          // Streamlined search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search collection...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                isDense: true, // Makes the search bar more compact
              ),
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
              ),
              onTapOutside: (event) => _searchFocusNode.unfocus(),
              onChanged: (value) {
                // TODO: Implement search functionality
              },
            ),
          ),

          // Rest of the collection grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _service.getCards(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('Add cards to your collection'),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final card = TcgCard(
                      id: data['id'],
                      name: data['name'],
                      imageUrl: data['imageUrl'],
                      setName: data['setName'],
                      rarity: data['rarity'],
                      price: data['price']?.toDouble(),
                    );
                    
                    return GestureDetector(
                      onLongPress: () {
                        setState(() {
                          if (!_selectionMode) {
                            _selectionMode = true;
                            _selectedCards.add(doc.id);
                          } else {
                            _toggleCardSelection(doc.id);
                          }
                        });
                      },
                      onTap: () {
                        if (_selectionMode) {
                          _toggleCardSelection(doc.id);
                        } else {
                          _showCardOptionsDialog(doc.id, card);
                        }
                      },
                      child: Stack(
                        children: [
                          CardItem(card: card),
                          if (_selectionMode)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _selectedCards.contains(doc.id)
                                      ? Theme.of(context).primaryColor.withOpacity(0.3)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: _selectedCards.contains(doc.id)
                                        ? Theme.of(context).primaryColor
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: _selectedCards.contains(doc.id)
                                    ? const Center(
                                        child: Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: !_selectionMode ? FloatingActionButton(
        onPressed: () {
          setState(() {
            _selectionMode = true;
          });
        },
        child: const Icon(Icons.select_all),
      ) : null,
    );
  }

  Future<void> _showBulkDeleteConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Cards'),
        content: Text(
          'Are you sure you want to delete ${_selectedCards.length} cards from your collection?\n'
          'This action cannot be undone.'
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Show loading indicator
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Deleting cards...'),
              duration: Duration(seconds: 1),
            ),
          );
        }

        // Delete all selected cards
        for (final cardId in _selectedCards) {
          await _service.removeCard(cardId);
        }
        
        setState(() {
          _selectionMode = false;
          _selectedCards.clear();
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted ${_selectedCards.length} cards'),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete cards'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
