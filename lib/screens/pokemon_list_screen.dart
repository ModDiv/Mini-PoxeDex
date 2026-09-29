import 'package:flutter/material.dart';

import '../models/pokemon_summary.dart';
import '../services/pokeapi_service.dart';
import '../widgets/pokemon_card.dart';

class PokemonListScreen extends StatefulWidget {
  const PokemonListScreen({super.key});

  @override
  State<PokemonListScreen> createState() => _PokemonListScreenState();
}

class _PokemonListScreenState extends State<PokemonListScreen> {
  static const _pageSize = 20;

  final _service = PokeApiService();
  final _scrollController = ScrollController();
  final List<PokemonSummary> _pokemons = [];

  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

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
      setState(() => _error = 'Gagal memuat Pokemon. Periksa koneksi internetmu.');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Pokemon'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Loading pertama
    if (_pokemons.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error pada load pertama
    if (_pokemons.isEmpty && _error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 64),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadMore,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: GridView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        // +1 slot untuk indikator loading / tombol retry di akhir list
        itemCount: _pokemons.length + ((_isLoading || _error != null) ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _pokemons.length) {
            return _buildFooter();
          }
          final pokemon = _pokemons[index];
          return PokemonCard(
            pokemon: pokemon,
            onTap: () {
              // TODO: Navigator.push ke PokemonDetailScreen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Detail ${pokemon.displayName} belum tersedia')),
              );
            },
          );
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
          label: const Text('Coba lagi'),
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }
}