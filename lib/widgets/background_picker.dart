import 'package:flutter/material.dart';
import '../models/collection_background.dart';
import '../services/background_service.dart';

class BackgroundPicker extends StatelessWidget {
  final String userId;
  final String collectionId;
  final BackgroundService backgroundService;

  const BackgroundPicker({
    super.key,
    required this.userId,
    required this.collectionId,
    required this.backgroundService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CollectionBackground>>(
      stream: backgroundService.getAvailableBackgrounds(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final backgrounds = snapshot.data!;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: backgrounds.length,
          itemBuilder: (context, index) {
            final background = backgrounds[index];
            return InkWell(
              onTap: background.isUnlocked
                  ? () => _applyBackground(context, background)
                  : () => _showUnlockDialog(context, background),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      background.previewUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Text(
                      background.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 3,
                            color: Colors.black45,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!background.isUnlocked)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(
                          background.isPremium ? Icons.star : Icons.lock,
                          color: Colors.white70,
                          size: 32,
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

  Future<void> _applyBackground(
    BuildContext context,
    CollectionBackground background,
  ) async {
    try {
      await backgroundService.setCollectionBackground(
        userId,
        collectionId,
        background.id,
      );
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Applied ${background.name} background')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to apply background')),
        );
      }
    }
  }

  void _showUnlockDialog(BuildContext context, CollectionBackground background) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlock Background'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
              background.previewUrl,
              height: 120,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 16),
            Text(
              background.isPremium
                  ? 'This is a premium background'
                  : 'Reach collector level 5 to unlock backgrounds',
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.pop(context),
          ),
          if (background.isPremium)
            TextButton(
              child: const Text('Unlock'),
              onPressed: () {
                // TODO: Implement premium unlock
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }
}
