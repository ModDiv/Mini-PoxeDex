import 'package:flutter/material.dart';

import '../widgets/pokedex_scaffold.dart';
import 'pokemon_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _soon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$feature is not available yet')));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return PokedexScaffold(
      pageTitle: 'Home',
      onSearchSubmitted: (q) => _soon(context, 'Search "$q"'),
      onSortTap: () => _soon(context, 'Sort'),
      onTypesTap: () => _soon(context, 'Type Filter'),
      onFavoritesTap: () => _soon(context, 'Favorites'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.catching_pokemon, size: 100, color: colors.primary),
              const SizedBox(height: 24),
              const Text(
                'Welcome to PoxeDex',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Explore the world of Pokemon, view details, and save your favorites.',
                style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.tonal(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PokemonListScreen(),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                ),
                child: const Text('View Pokemon List'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}