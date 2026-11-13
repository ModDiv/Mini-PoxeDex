import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../models/pokemon_detail.dart';
import '../models/pokemon_summary.dart';
import '../services/favorite_service.dart';
import '../services/pokeapi_service.dart';
import '../utils/type_colors.dart';
import '../widgets/confirm_remove_dialog.dart';
import '../widgets/rotating_pokeball.dart';

class PokemonDetailScreen extends StatefulWidget {
  final PokemonSummary summary;

  const PokemonDetailScreen({super.key, required this.summary});

  @override
  State<PokemonDetailScreen> createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen> {
  static const _starColor = Color(0xFFFFC107);

  final _service = PokeApiService();
  final _favorites = FavoriteService.instance;

  PokemonDetail? _detail;
  String? _error;
  bool _loading = true;

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
      final detail = await _service.fetchPokemonDetail(widget.summary.id);
      if (!mounted) return;
      setState(() => _detail = detail);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load details. Check your internet connection.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---------- Favorite ----------

  Future<void> _onFavoriteTap() async {
    final id = widget.summary.id;

    if (_favorites.isFavorite(id)) {
      final confirmed = await confirmRemoveFavorite(context);
      if (!confirmed) return;
      await _favorites.remove(id);
      _showMessage('Removed from favorites');
    } else {
      await _favorites.add(id);
      _showMessage('Added to favorites');
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final detail = _detail;

    final bg = detail == null
        ? colors.primaryContainer
        : TypeColors.of(detail.primaryType);
    final fg = TypeColors.onColor(bg);

    final imageSize =
    (MediaQuery.sizeOf(context).height * 0.3).clamp(170.0, 280.0);

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        color: bg,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildTopBar(fg),
              const SizedBox(height: 8),
              _buildHero(imageSize),
              const SizedBox(height: 16),
              _buildTypeChips(detail),
              const SizedBox(height: 20),
              Expanded(child: _buildSheet(colors, detail)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(Color fg) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            icon: Icon(Icons.arrow_back, color: fg, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              widget.summary.displayName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: fg,
              ),
            ),
          ),
          ListenableBuilder(
            listenable: _favorites,
            builder: (context, _) {
              final isFav = _favorites.isFavorite(widget.summary.id);
              return IconButton(
                tooltip: isFav ? 'Remove from favorites' : 'Add to favorites',
                onPressed: _onFavoriteTap,
                style: IconButton.styleFrom(
                  backgroundColor: isFav ? Colors.white.withAlpha(220) : null,
                ),
                icon: Icon(
                  isFav ? Icons.star : Icons.star_border,
                  color: isFav ? _starColor : fg,
                  size: 30,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHero(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RotatingPokeball(size: size),
          SizedBox(
            width: size * 0.85,
            height: size * 0.85,
            child: Hero(
              tag: 'pokemon-${widget.summary.id}',
              child: CachedNetworkImage(
                imageUrl: widget.summary.imageUrl,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (_, __, ___) => const Icon(
                  Icons.catching_pokemon,
                  size: 64,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChips(PokemonDetail? detail) {
    // Kerangka chip saat data masih dimuat
    if (detail == null && _loading) {
      return SizedBox(
        height: 34,
        child: Shimmer.fromColors(
          baseColor: Colors.white.withAlpha(90),
          highlightColor: Colors.white.withAlpha(190),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 2; i++)
                Container(
                  width: 96,
                  height: 34,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 34,
      child: detail == null
          ? null
          : Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final type in detail.displayTypes)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
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
    );
  }

  Widget _buildSheet(ColorScheme colors, PokemonDetail? detail) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 24, bottom: 8),
            child: Text(
              'Pokemon Details',
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: _buildSheetContent(colors, detail)),
        ],
      ),
    );
  }

  /// Kerangka kotak Height/Weight dan paragraf deskripsi.
  Widget _buildSheetSkeleton(ColorScheme colors) {
    Widget block(double height, {double? width, double radius = 8}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    return Shimmer.fromColors(
      baseColor: colors.surfaceContainerHigh,
      highlightColor: colors.surfaceContainerLowest,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      block(56, radius: 8),
                      const SizedBox(height: 10),
                      block(14, width: 50),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      block(56, radius: 8),
                      const SizedBox(height: 10),
                      block(14, width: 50),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            block(14),
            const SizedBox(height: 12),
            block(14),
            const SizedBox(height: 12),
            block(14),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.55,
                child: block(14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetContent(ColorScheme colors, PokemonDetail? detail) {
    if (_loading) {
      return _buildSheetSkeleton(colors);
    }

    if (detail == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 48),
              const SizedBox(height: 12),
              Text(
                _error ?? 'Something went wrong.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  value: '${detail.heightM.toStringAsFixed(1)} m',
                  label: 'Height',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatBox(
                  value: '${detail.weightKg.toStringAsFixed(1)} kg',
                  label: 'Weight',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: Text(
              detail.description,
              textAlign: TextAlign.justify,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;

  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          height: 56,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: colors.onSurfaceVariant)),
      ],
    );
  }
}