import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Add this import
import 'dart:math' show max, min;
import '../services/collection_service.dart';
import '../models/custom_collection.dart';
import '../models/card_model.dart';
import '../widgets/card_item.dart';
import '../widgets/background_picker.dart';
import '../services/background_service.dart';
import '../screens/custom_collection_detail_screen.dart'; // Fixed import path
import './custom_collection_detail_screen.dart'; // Add this import

class CustomCollectionsScreen extends StatelessWidget {
  const CustomCollectionsScreen({super.key});

  Future<void> _createNewCollection(BuildContext context, CollectionService service) async {
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
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter collection name',
                ),
                validator: (value) => 
                  value?.isEmpty == true ? 'Please enter a name' : null,
                onSaved: (value) => name = value ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Add a description for your collection',
                  helperText: 'Optional: describe what makes this collection special',
                ),
                onSaved: (value) => description = value ?? '',
                maxLines: 2,
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

    if (result == true && context.mounted) {
      try {
        await service.createCustomCollection(name, description);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Created collection "$name"')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create collection')),
          );
        }
      }
    }
  }

  Future<void> _editCollection(
    BuildContext context, 
    CustomCollection collection,
    CollectionService service,
  ) async {
    final formKey = GlobalKey<FormState>();
    String name = collection.name;
    String description = collection.description;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Collection'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: collection.name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => 
                  value?.isEmpty == true ? 'Please enter a name' : null,
                onSaved: (value) => name = value ?? '',
              ),
              TextFormField(
                initialValue: collection.description,
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
            child: const Text('Save'),
            onPressed: () async {
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
      await service.updateCollectionDetails(collection.id, name, description);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = CollectionService();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Custom Collections',
          style: TextStyle(
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: Theme.of(context).appBarTheme.foregroundColor,
            ),
            onPressed: () => _createNewCollection(context, service),
          ),
        ],
      ),
      body: StreamBuilder<List<CustomCollection>>(  // Change from FutureBuilder to StreamBuilder
        stream: service.getCustomCollectionsStream(),  // New stream method
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final collections = snapshot.data ?? [];
          if (collections.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.collections_bookmark_outlined, 
                    size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No custom collections yet\nCreate one from your collection',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: collections.length,
            itemBuilder: (context, index) {
              final collection = collections[index];
              return _buildCollectionCard(context, collection); // Pass context here
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.small(  // Changed to small
        heroTag: 'custom_collections_fab',
        tooltip: 'Create Custom Collection',  // Added tooltip
        onPressed: () => _createNewCollection(context, service),
        child: const Icon(Icons.add, size: 20),  // Reduced icon size
      ),
    );
  }

  Stream<List<TcgCard>> _getCollectionPreviewCards(List<String> cardIds) {
    if (cardIds.isEmpty) return Stream.value([]);
    
    // Get up to 5 cards for preview
    final previewCardIds = cardIds.take(5).toList();
    
    return FirebaseFirestore.instance
        .collection('cards')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .collection('userCards')
        .where(FieldPath.documentId, whereIn: previewCardIds)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return TcgCard(
                id: data['id'],
                name: data['name'],
                imageUrl: data['imageUrl'],
                setName: data['setName'],
                rarity: data['rarity'],
                price: data['price']?.toDouble(),
              );
            }).toList());
  }

  void _showCollectionMenu(BuildContext context, CustomCollection collection, CollectionService service) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Collection'),
              onTap: () {
                Navigator.pop(context);
                _editCollection(context, collection, service);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Collection'),
              onTap: () {
                Navigator.pop(context);
                _shareCollection(context, collection, service);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Collection', 
                style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, collection, service);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCollection(BuildContext context, CustomCollection collection) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomCollectionDetailScreen(collection: collection),
      ),
    );
  }

  Future<void> _shareCollection(
    BuildContext context, 
    CustomCollection collection,
    CollectionService service
  ) async {
    try {
      final shareCode = await service.shareCollection(collection.id);
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Share Collection'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Share this code with others:'),
                const SizedBox(height: 16),
                SelectableText(
                  shareCode,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Close'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate share code')),
        );
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CustomCollection collection,
    CollectionService service
  ) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Collection?'),
          content: Text(
            'Are you sure you want to delete "${collection.name}"?\n'
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
        // Show loading indicator
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Deleting collection...'),
              duration: Duration(seconds: 1),
            ),
          );
        }

        await service.deleteCollection(collection.id);
        
        if (context.mounted) {
          Navigator.pop(context); // Close the menu
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted "${collection.name}"'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete collection'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildCollectionCard(BuildContext context, CustomCollection collection) { // Add context parameter
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CustomCollectionDetailScreen(collection: collection),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add card preview
            StreamBuilder<List<TcgCard>>(
              stream: CollectionService().getCollectionCardsStream(collection.id),
              builder: (context, snapshot) {
                final cards = snapshot.data ?? [];
                if (cards.isEmpty) {
                  return const SizedBox(height: 100);
                }

                return SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(8),
                    itemCount: cards.length.clamp(0, 5), // Show up to 5 cards
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            cards[index].imageUrl,
                            width: 70,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            // Collection info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    collection.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (collection.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      collection.description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${collection.cardIds.length} cards',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      if (collection.totalValue != null)
                        Text(
                          '€${collection.totalValue!.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final CustomCollection collection;

  const _CollectionCard({required this.collection});

  Future<void> _editCollection(BuildContext context, CustomCollection collection, CollectionService service) async {
    final formKey = GlobalKey<FormState>();
    String name = collection.name;
    String description = collection.description;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Collection'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: collection.name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => 
                  value?.isEmpty == true ? 'Please enter a name' : null,
                onSaved: (value) => name = value ?? '',
              ),
              TextFormField(
                initialValue: collection.description,
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
            child: const Text('Save'),
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
      await service.updateCollectionDetails(collection.id, name, description);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = CollectionService();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _showCollectionDetail(context),
        onLongPress: () => _showOptions(context, service),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          collection.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (collection.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            collection.description,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        if (collection.totalValue != null && collection.totalValue! > 0)
                          Text(
                            '€${collection.totalValue!.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${collection.cardIds.length} cards',
                          style: TextStyle(
                            color: Colors.blue[900],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (collection.totalValue != null)
                          Text(
                            '${(collection.totalValue! / max(collection.cardIds.length, 1)).toStringAsFixed(2)} avg',
                            style: TextStyle(
                              color: Colors.blue[900],
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, CollectionService service) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(context);
                _editCollection(context, collection, service);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, service);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, CollectionService service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Collection?'),
        content: Text('Are you sure you want to delete "${collection.name}"? '
            'This action cannot be undone.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await service.deleteCollection(collection.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleted collection "${collection.name}"')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete collection')),
          );
        }
      }
    }
  }

  void _showCollectionDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _CollectionDetailScreen(collection: collection),
      ),
    );
  }
}

class _CollectionDetailScreen extends StatelessWidget {
  final CustomCollection collection;

  const _CollectionDetailScreen({required this.collection});

  // Add these color constants
  static final List<Color> _modernChartColors = [
    const Color(0xFF5C6BC0), // Indigo
    const Color(0xFF42A5F5), // Blue
    const Color(0xFF26A69A), // Teal
    const Color(0xFF66BB6A), // Green
    const Color(0xFFFFCA28), // Amber
  ];

  Widget _buildSectionHeader(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: color ?? _modernChartColors[0],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestones(BuildContext context, Map<String, dynamic> stats) {
    final nextMilestone = stats['nextMilestone'] as Map<String, dynamic>?;
    final recentMilestones = stats['recentMilestones'] as List<dynamic>? ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Collection Milestones', color: _modernChartColors[4]),
          if (nextMilestone != null)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Next Milestone',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _modernChartColors[4].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${nextMilestone['current']}/${nextMilestone['target']}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _modernChartColors[4],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${(nextMilestone['progress'] * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: nextMilestone['progress']?.toDouble() ?? 0,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(_modernChartColors[4]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    nextMilestone['description'] ?? '',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          if (recentMilestones.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 8),
              child: Text(
                'Recent Achievements',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...recentMilestones.map((milestone) => ListTile(
              leading: Icon(
                Icons.emoji_events,
                color: _modernChartColors[4],
                size: 20,
              ),
              title: Text(
                milestone['title'] ?? '',
                style: const TextStyle(fontSize: 13),
              ),
              subtitle: Text(
                milestone['date'] ?? '',
                style: const TextStyle(fontSize: 12),
              ),
              dense: true,
            )).toList(),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = CollectionService();

    return Scaffold(
      appBar: AppBar(
        title: Text(collection.name),
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.local_offer),
            onPressed: () => _showTagsDialog(context, service),
          ),
          IconButton(
            icon: const Icon(Icons.note_add),
            onPressed: () => _showAddNoteDialog(context, service),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareCollection(context, service),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'sort_name',
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.sort_by_alpha),
                  title: const Text('Sort by Name'),
                ),
              ),
              PopupMenuItem(
                value: 'sort_price',
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.attach_money),
                  title: const Text('Sort by Price'),
                ),
              ),
              PopupMenuItem(
                value: 'sort_date',
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Sort by Date Added'),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'export',
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.share),
                  title: const Text('Export Collection'),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Delete Collection', 
                    style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
            onSelected: (value) async {
              switch (value) {
                case 'sort_name':
                case 'sort_price':
                case 'sort_date':
                  // Handle sorting
                  break;
                case 'export':
                  _exportCollection(context);
                  break;
                case 'delete':
                  _confirmDelete(context, service);
                  break;
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCollectionHeader(),
          _buildPriceHistoryChart(service),
          if (collection.notes.isNotEmpty) _buildNotes(),
          if (collection.tags.isNotEmpty) _buildTags(),
          FutureBuilder<Map<String, dynamic>>(
            future: service.getCollectionStats(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return _buildMilestones(context, snapshot.data!);
              }
              return const SizedBox.shrink();
            },
          ),
          Expanded(
            child: _buildCardGrid(service),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionHeader() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (collection.description.isNotEmpty) ...[
              Text(
                collection.description,
                style: const TextStyle(fontSize: 14),
              ),
              const Divider(),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${collection.cardIds.length} Cards',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (collection.totalValue != null)
                      Text(
                        'Total Value: €${collection.totalValue!.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                if (collection.totalValue != null && collection.cardIds.isNotEmpty)
                  Text(
                    'Avg: €${(collection.totalValue! / collection.cardIds.length).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[700],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardGrid(CollectionService service) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: service.getCards(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allCards = snapshot.data!.docs;
        final collectionCards = allCards
            .where((doc) => collection.cardIds.contains(doc.id))
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return TcgCard(
                id: data['id'],
                name: data['name'],
                imageUrl: data['imageUrl'],
                setName: data['setName'],
                rarity: data['rarity'],
                price: data['price']?.toDouble(),
              );
            })
            .toList();

        if (collectionCards.isEmpty) {
          return const Center(
            child: Text('No cards in this collection'),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(8),  // Reduced padding
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,  // Keep 3 columns
            childAspectRatio: 0.7,  // Keep card proportions
            crossAxisSpacing: 4,    // Reduced spacing
            mainAxisSpacing: 4,     // Reduced spacing
          ),
          itemCount: collectionCards.length,
          itemBuilder: (context, index) {
            final card = collectionCards[index];
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),  // Added minimal padding
              child: Stack(
                children: [
                  CardItem(card: card),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: const Icon(Icons.remove_circle),
                      color: Colors.red,
                      onPressed: () => _removeCardFromCollection(
                        context, 
                        service, 
                        card,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _removeCardFromCollection(
    BuildContext context, 
    CollectionService service, 
    TcgCard card,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Card'),
        content: Text('Remove ${card.name} from this collection?'),
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

    if (confirmed == true && context.mounted) {
      try {
        await service.removeCardsFromCollection(collection.id, [card.id]);
        // Force rebuild by navigating back and forth
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => _CollectionDetailScreen(collection: collection),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to remove ${card.name}')),
          );
        }
      }
    }
  }

  Widget _buildPriceHistoryChart(CollectionService service) {
    if (collection.priceHistory.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(8),
        child: const SizedBox(
          height: 200,
          child: Center(
            child: Text('No price history available'),
          ),
        ),
      );
    }

    final data = collection.priceHistory;
    final spots = data.map((entry) {
      final timestamp = entry['timestamp'] as Timestamp;
      final value = entry['value'] as double;
      return FlSpot(
        timestamp.toDate().millisecondsSinceEpoch.toDouble(),
        value,
      );
    }).toList();

    final minY = spots.map((s) => s.y).reduce(min);
    final maxY = spots.map((s) => s.y).reduce(max);

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
              ),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                      return Text(
                        '${date.day}/${date.month}',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey.shade300),
              ),
              minX: spots.first.x,
              maxX: spots.last.x,
              minY: minY * 0.95,
              maxY: maxY * 1.05,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withOpacity(0.2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotes() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: collection.notes.length,
        itemBuilder: (context, index) {
          final note = collection.notes[index];
          return ListTile(
            title: Text(note['text'] as String),
            subtitle: Text(
              (note['timestamp'] as Timestamp).toDate().toString(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTags() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Wrap(
          spacing: 8,
          children: collection.tags.map((tag) => Chip(
            label: Text(tag),
          )).toList(),
        ),
      ),
    );
  }

  Future<void> _exportCollection(BuildContext context) async {
    // TODO: Implement collection export/sharing
    // Could export as CSV, share as link, etc.
  }

  Future<void> _confirmDelete(BuildContext context, CollectionService service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Collection?'),
        content: Text('Are you sure you want to delete "${collection.name}"? '
            'This action cannot be undone.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await service.deleteCollection(collection.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleted collection "${collection.name}"')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete collection')),
          );
        }
      }
    }
  }

  Future<void> _showTagsDialog(BuildContext context, CollectionService service) async {
    final tags = List<String>.from(collection.tags);
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manage Tags'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Add Tag',
                suffixIcon: Icon(Icons.add),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty && !tags.contains(value)) {
                  tags.add(value);
                  controller.clear();
                }
              },
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: tags.map((tag) => Chip(
                label: Text(tag),
                onDeleted: () => tags.remove(tag),
              )).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Save'),
            onPressed: () async {
              await service.updateCollectionTags(collection.id, tags);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showAddNoteDialog(BuildContext context, CollectionService service) async {
    final controller = TextEditingController();
    final selectedCards = <String>{};

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Note',
                hintText: 'Enter your note here',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Attach to selected cards'),
              value: selectedCards.isNotEmpty,
              onChanged: (value) {
                // TODO: Implement card selection
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Add'),
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await service.addNoteToCollection(
                  collection.id, 
                  controller.text,
                  cardIds: selectedCards.toList(),
                );
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _shareCollection(BuildContext context, CollectionService service) async {
    try {
      final shareCode = await service.shareCollection(collection.id);
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Share Collection'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Share this code with others:'),
                const SizedBox(height: 16),
                SelectableText(
                  shareCode,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: const Text('Copy'),
                onPressed: () {
                  // TODO: Implement copy to clipboard
                },
              ),
              TextButton(
                child: const Text('Close'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share collection')),
        );
      }
    }
  }
}

class CollectionDetailScreen extends StatelessWidget {
  // Add color constants
  static final List<Color> _colors = [
    const Color(0xFF5C6BC0), // Indigo
    const Color(0xFF42A5F5), // Blue
    const Color(0xFF26A69A), // Teal
    const Color(0xFF66BB6A), // Green
    const Color(0xFFFFCA28), // Amber
  ];

  final CustomCollection collection;
  final int level;  // Add this

  const CollectionDetailScreen({
    super.key,
    required this.collection,
    this.level = 0,  // Default to 0 if not provided
  });

  String get userId => FirebaseAuth.instance.currentUser?.uid ?? '';  // Changed to getter

  Widget _buildSectionHeader(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: color ?? _colors[0],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final service = CollectionService();
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(
          collection.name,
          style: TextStyle(
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
        ),
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        actions: [
          if (level >= 5) // Only show if user has reached level 5
            IconButton(
              icon: const Icon(Icons.wallpaper),
              tooltip: 'Change Background',
              onPressed: () => _showBackgroundPicker(context),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collection Stats Header
          Card(
            margin: EdgeInsets.zero,
            elevation: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (collection.description.isNotEmpty) ...[
                    Text(
                      collection.description,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                    const Divider(),
                  ],
                  // ...rest of existing stats header code...
                ],
              ),
            ),
          ),
          // ...rest of existing build method code...
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showBackgroundPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Select Background',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BackgroundPicker(
                userId: userId,
                collectionId: collection.id,
                backgroundService: BackgroundService(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
