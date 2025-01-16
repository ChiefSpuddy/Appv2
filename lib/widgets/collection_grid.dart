import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/collection_service.dart';
import '../widgets/card_item.dart';
import '../models/card_model.dart';
import '../models/custom_collection.dart';
import '../screens/custom_collections_screen.dart';  // Make sure this path is correct
import '../providers/selection_state.dart';

class CollectionGrid extends StatefulWidget {
  const CollectionGrid({super.key});

  @override
  State<CollectionGrid> createState() => _CollectionGridState();
}

class _CollectionGridState extends State<CollectionGrid> {
  final CollectionService _service = CollectionService();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SelectionState(),
      child: Builder(
        builder: (context) => Stack(
          children: [
            const CollectionGridView(),
            Consumer<SelectionState>(
              builder: (context, selectionState, _) => AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                top: selectionState.isMultiSelectMode ? 0 : -64,
                left: 0,
                right: 0,
                height: 64,
                child: const MultiSelectBar(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddToCollectionDialog({String? singleCardId}) async {
    final cardIds = singleCardId != null ? [singleCardId] : context.read<SelectionState>().selectedCards.toList();
    if (cardIds.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomCollectionsScreen(),
      ),
    ).then((result) async {
      if (result is CustomCollection) {
        await _service.addCardsToCollection(result.id, cardIds);
        context.read<SelectionState>().clearSelection();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added ${cardIds.length} cards to ${result.name}')),
          );
        }
      }
    });
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
      await _service.addCardsToCollection(collection.id, context.read<SelectionState>().selectedCards.toList());
      
      context.read<SelectionState>().clearSelection();

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

  Future<void> _showCardOptionsDialog(BuildContext context, String docId, TcgCard card) async {
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

  Future<void> _showBulkDeleteConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Cards'),
        content: Text(
          'Are you sure you want to delete ${context.read<SelectionState>().selectedCount} cards from your collection?\n'
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
        for (final cardId in context.read<SelectionState>().selectedCards) {
          await _service.removeCard(cardId);
        }
        
        context.read<SelectionState>().clearSelection();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted ${context.read<SelectionState>().selectedCount} cards'),
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

  Future<void> _addToCollection() async {
    // ...existing code...
  }

  Future<void> _deleteSelected() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Cards'),
        content: Text(
          'Are you sure you want to delete ${context.read<SelectionState>().selectedCount} cards?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      for (final docId in context.read<SelectionState>().selectedCards) {
        await CollectionService().removeCard(docId);
      }
      context.read<SelectionState>().clearSelection();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting cards: $e')),
        );
      }
    }
  }
}

class CollectionGridView extends StatefulWidget {  // Change to StatefulWidget
  const CollectionGridView({super.key});

  @override
  State<CollectionGridView> createState() => _CollectionGridViewState();
}

class _CollectionGridViewState extends State<CollectionGridView> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: CollectionService().getCards(),
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
          padding: const EdgeInsets.all(12),  // Increased from 8
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.7,
            crossAxisSpacing: 8,    // Increased from 4
            mainAxisSpacing: 8,     // Increased from 4
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            
            return CardItem(
              card: TcgCard(
                id: data['id'],
                name: data['name'],
                imageUrl: data['imageUrl'],
                setName: data['setName'],
                rarity: data['rarity'],
                price: data['price']?.toDouble(),
              ),
              docId: doc.id, // Pass the document ID
              onRemoved: () {
                setState(() {}); // This will trigger a rebuild
              },
            );
          },
        );
      },
    );
  }
}

class CardGridItem extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final Map<String, dynamic> data;

  const CardGridItem({
    super.key,
    required this.doc,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final card = TcgCard(
      id: data['id'],
      name: data['name'],
      imageUrl: data['imageUrl'],
      setName: data['setName'],
      rarity: data['rarity'],
      price: data['price']?.toDouble(),
    );

    return Consumer<SelectionState>(
      builder: (context, selectionState, _) {
        final isSelected = selectionState.isSelected(doc.id);
        
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onLongPress: () => selectionState.toggleSelection(doc.id),
            onTap: () {
              if (selectionState.isMultiSelectMode) {
                selectionState.toggleSelection(doc.id);
              } else {
                CardDialogs.showCardOptionsDialog(context, doc.id, card, selectionState);
              }
            },
            child: Stack(
              children: [
                CardItem(card: card),
                if (selectionState.isMultiSelectMode)
                  SelectionOverlay(isSelected: isSelected),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SelectionOverlay extends StatelessWidget {
  final bool isSelected;

  const SelectionOverlay({
    super.key,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).primaryColor.withOpacity(0.3)
            : Colors.transparent,
        border: Border.all(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.transparent,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: isSelected
          ? Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            )
          : null,
    );
  }
}

class MultiSelectBar extends StatelessWidget {
  const MultiSelectBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SelectionState>(
      builder: (context, selectionState, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return Container(
          color: isDark ? Colors.grey[900] : Colors.white,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '${selectionState.selectedCount} selected',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => context.read<SelectionState>().selectedCount == 0 ? null : context.read<SelectionState>().clearSelection(),
                    icon: const Icon(Icons.add_to_photos),
                    label: const Text('Add to Collection'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => context.read<SelectionState>().selectedCount == 0 ? null : context.read<SelectionState>().clearSelection(),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
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
  }
}

class CardDialogs {
  static Future<void> showCardOptionsDialog(
    BuildContext context,
    String docId,
    TcgCard card,
    SelectionState selectionState,
  ) async {
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
                onTap: () {
                  Navigator.pop(context);
                  _addToCollection(context, docId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove from Collection'),
                onTap: () {
                  Navigator.pop(context);
                  _showRemoveConfirmation(context, docId, card.name);
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

  static Future<void> _addToCollection(BuildContext context, String cardId) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomCollectionsScreen(),
      ),
    ).then((result) async {
      if (result is CustomCollection) {
        await CollectionService().addCardsToCollection(result.id, [cardId]);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added card to ${result.name}')),
          );
        }
      }
    });
  }

  static Future<void> _showRemoveConfirmation(
    BuildContext context,
    String docId,
    String cardName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Card'),
        content: Text('Are you sure you want to remove $cardName from your collection?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await CollectionService().removeCard(docId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Removed $cardName')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to remove card'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
