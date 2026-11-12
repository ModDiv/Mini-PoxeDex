import 'package:flutter/material.dart';

import '../models/pokemon_summary.dart';
import '../services/favorite_service.dart';
import '../services/pokeapi_service.dart';
import '../utils/type_colors.dart';
import '../widgets/pokedex_scaffold.dart';
import '../widgets/pokemon_card.dart';
import '../widgets/type_filter_sheet.dart';
import 'favorite_screens.dart';
import 'pokemon_detail_screen.dart';

enum SortOption {
  idAsc('ID (low to high)'),
  idDesc('ID (high to low)'),
  nameAsc('Name (A-Z)'),
  nameDesc('Name (Z-A)');

  final String label;
  const SortOption(this.label);
}

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

  // ---- state search + sort + filter ----
  String _query = '';
  SortOption _sort = SortOption.idAsc;
  Set<String> _typeFilters = {}; // kosong = semua type

  List<PokemonSummary>? _all; // 1025 nama
  final Map<String, Set<int>> _typeIds = {}; // type -> ID Pokemon
  bool _dataLoading = false;
  String? _dataError;

  /// Mode "semua data": aktif jika ada search, filter type, atau sort non-bawaan.
  bool get _useAll =>
      _query.isNotEmpty ||
          _typeFilters.isNotEmpty ||
          _sort != SortOption.idAsc;

  bool get _missingTypeData =>
      _typeFilters.any((t) => !_typeIds.containsKey(t));

  bool get _needsData => _useAll && (_all == null || _missingTypeData);

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

  // ---------- Data untuk mode "semua" (search, sort, filter) ----------

  Future<void> _ensureData() async {
    if (_dataLoading || !_needsData) return;

    final types = _typeFilters.toList();
    setState(() {
      _dataLoading = true;
      _dataError = null;
    });
    try {
      final all = _all ?? await _service.fetchAllPokemon();
      final loaded = <String, Set<int>>{};
      for (final type in types) {
        if (!_typeIds.containsKey(type)) {
          loaded[type] = await _service.fetchPokemonIdsByType(type);
        }
      }
      if (!mounted) return;
      setState(() {
        _all = all;
        _typeIds.addAll(loaded);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _dataError = 'Failed to load data. Check your internet connection.';
      });
    } finally {
      if (mounted) setState(() => _dataLoading = false);
    }

    // Jika filter berubah saat loading, muat data yang masih kurang
    if (mounted && _dataError == null && _needsData) _ensureData();
  }

  // ---------- Search ----------

  void _onSearchChanged(String text) {
    var q = text.trim().toLowerCase();
    if (q.startsWith('#')) q = q.substring(1);
    setState(() => _query = q);
    _ensureData();
  }

  // ---------- Sort ----------

  int _compare(PokemonSummary a, PokemonSummary b) {
    switch (_sort) {
      case SortOption.idAsc:
        return a.id.compareTo(b.id);
      case SortOption.idDesc:
        return b.id.compareTo(a.id);
      case SortOption.nameAsc:
        return a.name.compareTo(b.name);
      case SortOption.nameDesc:
        return b.name.compareTo(a.name);
    }
  }

  Future<void> _showSortSheet() async {
    final selected = await showModalBottomSheet<SortOption>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final colors = Theme.of(sheetContext).colorScheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Sort by',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              for (final option in SortOption.values)
                ListTile(
                  title: Text(option.label),
                  trailing: option == _sort
                      ? Icon(Icons.check, color: colors.primary)
                      : null,
                  onTap: () => Navigator.pop(sheetContext, option),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selected == null || selected == _sort || !mounted) return;
    setState(() => _sort = selected);
    _ensureData();
  }

  // ---------- Filter type ----------

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Future<void> _showTypeSheet() async {
    final selected = await showTypeFilterSheet(
      context,
      initial: _typeFilters,
    );
    if (selected == null || !mounted) return;
    setState(() => _typeFilters = selected);
    _ensureData();
  }

  void _removeTypeFilter(String type) {
    setState(() => _typeFilters = {..._typeFilters}..remove(type));
  }

  // ---------- Hasil (filter -> search -> sort) ----------

  List<PokemonSummary> get _results {
    final all = _all;
    if (all == null) return const [];

    final idSets = [
      for (final t in _typeFilters)
        if (_typeIds[t] != null) _typeIds[t]!,
    ];

    final filtered = all.where((p) {
      // harus punya SEMUA type yang dipilih
      for (final ids in idSets) {
        if (!ids.contains(p.id)) return false;
      }
      if (_query.isEmpty) return true;
      return p.name.contains(_query) || p.id.toString() == _query;
    }).toList();

    filtered.sort(_compare);
    return filtered;
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return PokedexScaffold(
      pageTitle: 'Pokemon List',
      onSearchChanged: _onSearchChanged,
      onSortTap: _showSortSheet,
      onTypesTap: _showTypeSheet,
      onFavoritesTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FavoriteScreen()),
        );
      },
      body: _useAll ? _buildAllBody() : _buildBody(),
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

  /// Baris yang menunjukkan filter type dan sort yang sedang aktif.
  Widget _buildStatusBar() {
    final colors = Theme.of(context).colorScheme;
    final showSort = _sort != SortOption.idAsc;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final type in _typeFilters)
              InputChip(
                label: Text(
                  _cap(type),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: TypeColors.onColor(TypeColors.of(type)),
                  ),
                ),
                backgroundColor: TypeColors.of(type),
                deleteIconColor: TypeColors.onColor(TypeColors.of(type)),
                visualDensity: VisualDensity.compact,
                onDeleted: () => _removeTypeFilter(type),
              ),
            if (showSort)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_vert,
                      size: 18, color: colors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    _sort.label,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // Mode semua data: hasil filter, search, dan/atau sort
  Widget _buildAllBody() {
    final waiting = _dataLoading ||
        (_dataError == null && (_all == null || _missingTypeData));

    if (waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_dataError != null) {
      return _buildMessage(
        icon: Icons.wifi_off,
        text: _dataError!,
        action: FilledButton.icon(
          onPressed: _ensureData,
          icon: const Icon(Icons.refresh),
          label: const Text('Try again'),
        ),
      );
    }

    final results = _results;
    final showBar = _typeFilters.isNotEmpty || _sort != SortOption.idAsc;

    return Column(
      children: [
        if (showBar) _buildStatusBar(),
        Expanded(
          child: results.isEmpty
              ? _buildMessage(
            icon: Icons.search_off,
            text: 'No Pokemon found.',
          )
              : GridView.builder(
            keyboardDismissBehavior:
            ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            gridDelegate: _gridDelegate,
            itemCount: results.length,
            itemBuilder: (context, index) => _buildCard(results[index]),
          ),
        ),
      ],
    );
  }

  // Daftar biasa (infinite scroll, urut ID naik)
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