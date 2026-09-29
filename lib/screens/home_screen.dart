import 'package:flutter/material.dart';

import '../widgets/pokedex_scaffold.dart';
import 'pokemon_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _soon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$feature belum aktif')));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return PokedexScaffold(
      pageTitle: 'Home',
      onSearchSubmitted: (q) => _soon(context, 'Pencarian "$q"'),
      onSortTap: () => _soon(context, 'Sort'),
      onTypesTap: () => _soon(context, 'Filter type'),
      onFavoritesTap: () => _soon(context, 'Favorit'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.catching_pokemon, size: 100, color: colors.primary),
              const SizedBox(height: 24),
              const Text(
                'Selamat datang di PoxeDex',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Jelajahi dunia Pokemon, lihat detail, dan simpan favoritmu.',
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
                child: const Text('Lihat Daftar Pokemon'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}