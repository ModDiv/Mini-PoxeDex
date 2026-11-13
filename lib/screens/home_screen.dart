import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../models/pokemon_detail.dart';
import '../models/pokemon_summary.dart';
import '../services/pokeapi_service.dart';
import '../utils/type_colors.dart';
import '../widgets/pokedex_scaffold.dart';
import '../widgets/rotating_pokeball.dart';
import 'favorite_screens.dart';
import 'pokemon_detail_screen.dart';
import 'pokemon_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _maxId = 1025;

  final _service = PokeApiService();

  PokemonDetail? _detail;
  String? _error;
  bool _loading = true;

  /// ID Pokemon harian: acak, tetapi sama sepanjang hari yang sama.
  int get _dailyId {
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    return Random(seed).nextInt(_maxId) + 1;
  }

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
      final detail = await _service.fetchPokemonDetail(_dailyId);
      if (!mounted) return;
      setState(() => _detail = detail);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
        'Failed to load today\'s Pokemon. Check your internet connection.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _soon(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$feature is not available yet')));
  }

  void _openFavorites() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FavoriteScreen()),
    );
  }

  void _openList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PokemonListScreen()),
    );
  }

  void _openDetail(PokemonDetail detail) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PokemonDetailScreen(
          summary: PokemonSummary(id: detail.id, name: detail.name),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return PokedexScaffold(
      pageTitle: 'Home Screen',
      showFab: false,
      showSearch: false,
      appBarActions: [
        IconButton(
          tooltip: 'Settings',
          icon: const Icon(Icons.settings, size: 28),
          onPressed: () => _soon('Settings'),
        ),
        const SizedBox(width: 8),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wb_sunny_outlined, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  'Pokemon of the Day',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildDailyCard(colors),
            const SizedBox(height: 28),
            Text(
              'Welcome to PoxeDex',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explore the world of Pokemon, view details, and pick your favorites.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const StadiumBorder(),
                ),
                onPressed: _openList,
                icon: const Icon(Icons.grid_view_rounded),
                label: const Text('View Pokemon List'),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const StadiumBorder(),
                ),
                onPressed: _openFavorites,
                icon: const Icon(Icons.star_border),
                label: const Text('View Favorites'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyCard(ColorScheme colors) {
    if (_loading) return _buildSkeleton(colors);

    final detail = _detail;
    if (detail == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          children: [
            Icon(Icons.wifi_off, size: 48, color: colors.outline),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    final summary = PokemonSummary(id: detail.id, name: detail.name);
    final typeColor = TypeColors.of(detail.primaryType);
    final background =
    Color.alphaBlend(typeColor.withAlpha(95), colors.surface);

    return Card(
      margin: EdgeInsets.zero,
      color: background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetail(detail),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  summary.displayId,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const RotatingPokeball(size: 200),
                    SizedBox(
                      width: 170,
                      height: 170,
                      child: CachedNetworkImage(
                        imageUrl: summary.imageUrl,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (_, __, ___) => Icon(
                          Icons.catching_pokemon,
                          size: 64,
                          color: colors.outline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                summary.displayName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  for (final type in detail.displayTypes)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(170),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        type,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: Text(
                  detail.description,
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    height: 1.5,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _openDetail(detail),
                child: const Text('View details'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton(ColorScheme colors) {
    Widget block(double h, {double? w, double r = 8}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r),
      ),
    );

    return Shimmer.fromColors(
      baseColor: colors.surfaceContainerHigh,
      highlightColor: colors.surfaceContainerLowest,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          children: [
            Container(
              width: 170,
              height: 170,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 16),
            block(24, w: 140),
            const SizedBox(height: 12),
            block(30, w: 160, r: 20),
            const SizedBox(height: 16),
            block(14),
            const SizedBox(height: 10),
            block(14),
            const SizedBox(height: 10),
            block(14, w: 120),
            const SizedBox(height: 16),
            block(40, r: 16),
          ],
        ),
      ),
    );
  }
}