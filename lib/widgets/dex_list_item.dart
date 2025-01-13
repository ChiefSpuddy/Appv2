import 'package:flutter/material.dart';
import '../services/dex_collection_service.dart';
import '../services/generation_service.dart';

class DexListItem extends StatefulWidget {
  final String dexName;
  final VoidCallback onTap;
  final int dexNumber;

  const DexListItem({
    super.key,
    required this.dexName,
    required this.onTap,
    required this.dexNumber,
  });

  @override
  State<DexListItem> createState() => _DexListItemState();
}

class _DexListItemState extends State<DexListItem> {
  final _service = DexCollectionService();
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _service.getDexStats(widget.dexName);
  }

  @override
  Widget build(BuildContext context) {
    final generation = GenerationService.getGeneration(widget.dexNumber);
    final genColor = GenerationService.getGenerationColor(generation);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                genColor.withOpacity(0.2),
                genColor.withOpacity(0.1),
              ],
            ),
          ),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _statsFuture,
            builder: (context, snapshot) {
              final stats = snapshot.data ?? {
                'cardCount': 0,
                'totalValue': 0.0,
                'variants': 0,
              };

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '#${widget.dexNumber.toString().padLeft(3, '0')}',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.dexName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: genColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      generation,
                      style: TextStyle(
                        fontSize: 12,
                        color: genColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${stats['cardCount']} cards',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  Text(
                    '€${stats['totalValue'].toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
