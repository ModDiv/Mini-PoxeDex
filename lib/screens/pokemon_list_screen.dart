import 'package:flutter/material.dart';

import '../models/pokemon_summary.dart';
import '../services/favorite_service.dart';
import '../services/pokeapi_service.dart';
import '../widgets/pokedex_scaffold.dart';
import '../widgets/pokemon_card.dart';
import 'favorite_screens.dart';
import 'pokemon_detail_screen.dart';

class PokemonListScreen extends StatefulWidget {
  const PokemonListScreen({super.key});

  @override
  State<PokemonListScreen> createState() => _PokemonListScreenState();
}

class _PokemonListScreenState extends State<PokemonListScreen> {
  static const _pageSize = 20;
  static const _starColor = Color(0xFFFFC107);

  final _favorites = FavoriteService.instance;
  final _service = PokeApiService();
  final _scrollController = ScrollController();
  final List<PokemonSummary> _pokemons = [];

  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  // ---- state pencarian ----
  String _query = '';
  List<PokemonSummary>? _all; // 1025 nama, diisi saat pertama kali mencari
  bool _searchLoading = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMore();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _service.fetchPokemonList(
        limit: _pageSize,
        offset: _pokemons.length,
      );
      if (!mounted) return;
      setState(() {
        _pokemons.addAll(result);
        _hasMore = result.length == _pageSize;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load Pokemon. Check your internet connection.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _pokemons.clear();
      _hasMore = true;
      _error = null;
    });
    await _loadMore();
  }

  // ---------- Search ----------

  void _onSearchChanged(String text) {
    var q = text.trim().toLowerCase();
    if (q.startsWith('#')) q = q.substring(1);
    setState(() => _query = q);
    if (q.isNotEmpty) _ensureAllLoaded();
  }

  Future<void> _ensureAllLoaded() async {
    if (_all != null || _searchLoading) return;

    setState(() {
      _searchLoading = true;
      _searchError = null;
    });
    try {
      final all = await _service.fetchAllPokemon();
      if (!mounted) return;
      setState(() => _all = all);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searchError = 'Failed to load search data. Check your internet connection.';
      });
    } finally {
      if (mounted) setState(() => _searchLoading = false);
    }
  }

  List<PokemonSummary> get _results {
    final all = _all;
    if (all == null) return const [];
    return all
        .where((p) => p.name.contains(_query) || p.id.toString() == _query)
        .toList();
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    void soon(String feature) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('$feature is not available yet')),
        );
    }

    return PokedexScaffold(
      pageTitle: 'Pokemon List',
      onSearchChanged: _onSearchChanged,
      onSortTap: () => soon('Sort'),
      onTypesTap: () => soon('Type Filter'),
      onFavoritesTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FavoriteScreen()),
        );
      },
      body: _query.isEmpty ? _buildBody() : _buildSearchBody(),
    );
  }

  static const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    childAspectRatio: 0.85,
  );

  Widget _buildCard(PokemonSummary pokemon) {
    return Stack(
      children: [
        Positioned.fill(
          child: PokemonCard(
            pokemon: pokemon,
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
        // Bintang penanda favorit
        Positioned(
          top: 8,
          left: 8,
          child: ListenableBuilder(
            listenable: _favorites,
            builder: (context, _) {
              if (!_favorites.isFavorite(pokemon.id)) {
                return const SizedBox.shrink();
              }
              return const IgnorePointer(
                child: Icon(Icons.star, color: _starColor, size: 24),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String text,
    Widget? action,
  }) {
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
              action,
            ],
          ],
        ),
      ),
    );
  }

  // Hasil pencarian
  Widget _buildSearchBody() {
    if (_searchLoading || (_all == null && _searchError == null)) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchError != null) {
      return _buildMessage(
        icon: Icons.wifi_off,
        text: _searchError!,
        action: FilledButton.icon(
          onPressed: _ensureAllLoaded,
          icon: const Icon(Icons.refresh),
          label: const Text('Try again'),
        ),
      );
    }

    final results = _results;
    if (results.isEmpty) {
      return _buildMessage(
        icon: Icons.search_off,
        text: 'No Pokemon found for "$_query".',
      );
    }

    return GridView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      gridDelegate: _gridDelegate,
      itemCount: results.length,
      itemBuilder: (context, index) => _buildCard(results[index]),
    );
  }

  // Daftar biasa (infinite scroll)
  Widget _buildBody() {
    // Loading pertama
    if (_pokemons.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error pada load pertama
    if (_pokemons.isEmpty && _error != null) {
      return _buildMessage(
        icon: Icons.wifi_off,
        text: _error!,
        action: FilledButton.icon(
          onPressed: _loadMore,
          icon: const Icon(Icons.refresh),
          label: const Text('Try again'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: GridView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
        gridDelegate: _gridDelegate,
        // +1 slot untuk indikator loading / tombol retry di akhir list
        itemCount: _pokemons.length + ((_isLoading || _error != null) ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _pokemons.length) {
            return _buildFooter();
          }
          return _buildCard(_pokemons[index]);
        },
      ),
    );
  }

  Widget _buildFooter() {
    if (_error != null) {
      return Center(
        child: TextButton.icon(
          onPressed: _loadMore,
          icon: const Icon(Icons.refresh),
          label: const Text('Try again'),
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }
}