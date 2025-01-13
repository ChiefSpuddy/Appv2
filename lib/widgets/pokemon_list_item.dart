import 'package:flutter/material.dart';
import '../services/pokemon_collection_service.dart';

class PokemonListItem extends StatefulWidget {
  final String pokemonName;
  final VoidCallback onTap;

  const PokemonListItem({
    super.key,
    required this.pokemonName,
    required this.onTap,
  });

  @override
  State<PokemonListItem> createState() => _PokemonListItemState();
}

class _PokemonListItemState extends State<PokemonListItem> {
  final _service = PokemonCollectionService();
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _service.getPokemonStats(widget.pokemonName);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {
          'cardCount': 0,
          'totalValue': 0.0,
          'variants': 0,
        };

        return ListTile(
          title: Text(widget.pokemonName),
          subtitle: Text(
            '${stats['cardCount']} cards • ${stats['variants']} variants',
          ),
          trailing: Text(
            '€${stats['totalValue'].toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onTap: widget.onTap,
        );
      },
    );
  }
}
