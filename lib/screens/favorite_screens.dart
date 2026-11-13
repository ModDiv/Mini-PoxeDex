import 'package:flutter/material.dart';

import '../models/pokemon_summary.dart';
import '../services/favorite_service.dart';
import '../services/pokeapi_service.dart';
import '../widgets/confirm_remove_dialog.dart';
import '../widgets/pokedex_scaffold.dart';
import '../widgets/pokemon_card.dart';
import 'pokemon_detail_screen.dart';
import '../widgets/skeleton_grid.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  static const _starColor = Color(0xFFFFC107);

  final _service = PokeApiService();
  final _favorites = FavoriteService.instance;

  Map<int, PokemonSummary> _byId = {};
  Map<int, String> _primaryTypes = {}; // id -> tipe utama, untuk warna kartu
  bool _loading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final all = await _service.fetchAllPokemon();
      if (!mounted) return;
      setState(() => _byId = {for (final p in all) p.id: p});

      // Warna kartu: kalau gagal, kartu tetap netral
      try {
        final types = await _service.fetchPrimaryTypes();
        if (mounted) setState(() => _primaryTypes = types);
      } catch (_) {}
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load favorites. Check your internet connection.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _remove(PokemonSummary pokemon) async {
    final confirmed = await confirmRemoveFavorite(context);
    if (!confirmed || !mounted) return;
    await _favorites.remove(pokemon.id);
    _showMessage('${pokemon.displayName} removed from favorites');
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _soon(String feature) => _showMessage('$feature is not available yet');

  @override
  Widget build(BuildContext context) {
    return PokedexScaffold(
      pageTitle: 'Favorites',
      onSearchChanged: (q) => setState(() => _query = q.trim().toLowerCase()),
      onSortTap: () => _soon('Sort'),
      onTypesTap: () => _soon('Type filter'),
      // onFavoritesTap dikosongkan: tidak perlu tombol Favorites di halaman ini
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const SkeletonGrid();
    }

    if (_error != null) {
      return _Message(
        icon: Icons.wifi_off,
        text: _error!,
        action: FilledButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          label: const Text('Try again'),
        ),
      );
    }

    return ListenableBuilder(
      listenable: _favorites,
      builder: (context, _) {
        final all = _favorites.ids
            .map((id) => _byId[id])
            .whereType<PokemonSummary>()
            .toList();

        if (all.isEmpty) {
          return const _Message(
            icon: Icons.star_border,
            text: 'No favorites yet.\n'
                'Tap the star on a Pokemon\'s detail page to add it.',
          );
        }

        final items = _query.isEmpty
            ? all
            : all.where((p) => p.name.contains(_query)).toList();

        if (items.isEmpty) {
          return _Message(
            icon: Icons.search_off,
            text: 'No favorites match "$_query".',
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final pokemon = items[index];
            return Stack(
              children: [
                Positioned.fill(
                  child: PokemonCard(
                    pokemon: pokemon,
                    type: _primaryTypes[pokemon.id],
                    useHero: false,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PokemonDetailScreen(summary: pokemon),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 4,
                  left: 4,
                  child: IconButton(
                    tooltip: 'Remove from favorites',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.star, color: _starColor),
                    onPressed: () => _remove(pokemon),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? action;

  const _Message({required this.icon, required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: colors.outline),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}