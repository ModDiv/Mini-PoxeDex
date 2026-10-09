import 'package:flutter/material.dart';

import 'expandable_fab.dart';

class PokedexScaffold extends StatefulWidget {
  /// Teks pada row abu-abu di bawah AppBar (mis. "Home", "Daftar Pokemon").
  final String pageTitle;
  final Widget body;

  /// Set false kalau suatu halaman tidak butuh FAB.
  final bool showFab;

  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<String>? onSearchSubmitted;

  /// Aksi yang bernilai null tidak akan ditampilkan di menu FAB.
  final VoidCallback? onSortTap;
  final VoidCallback? onTypesTap;
  final VoidCallback? onFavoritesTap;

  const PokedexScaffold({
    super.key,
    required this.pageTitle,
    required this.body,
    this.showFab = true,
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.onSortTap,
    this.onTypesTap,
    this.onFavoritesTap,
  });

  @override
  State<PokedexScaffold> createState() => _PokedexScaffoldState();
}

class _PokedexScaffoldState extends State<PokedexScaffold> {
  final _searchController = TextEditingController();
  bool _searching = false;
  bool _fabOpen = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSearch() => setState(() {
    _searching = true;
    _fabOpen = false;
  });

  void _closeSearch() {
    _searchController.clear();
    widget.onSearchChanged?.call('');
    FocusScope.of(context).unfocus();
    setState(() => _searching = false);
  }

  void _closeFab() => setState(() => _fabOpen = false);

  /// Tutup menu FAB dulu, baru jalankan aksinya.
  VoidCallback _wrap(VoidCallback callback) => () {
    setState(() => _fabOpen = false);
    callback();
  };

  List<FabAction> _buildActions() => [
    if (widget.onSortTap != null)
      FabAction(
        icon: Icons.swap_vert,
        label: 'Sort by...',
        onTap: _wrap(widget.onSortTap!),
      ),
    if (widget.onTypesTap != null)
      FabAction(
        icon: Icons.category_outlined,
        label: 'Types',
        onTap: _wrap(widget.onTypesTap!),
      ),
    if (widget.onFavoritesTap != null)
      FabAction(
        icon: Icons.star_border,
        label: 'Favorites',
        onTap: _wrap(widget.onFavoritesTap!),
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final actions = _buildActions();
    final showFab = widget.showFab && actions.isNotEmpty;

    return PopScope(
      // Tombol back menutup search/menu FAB dulu sebelum keluar halaman
      canPop: !_searching && !_fabOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_fabOpen) {
          _closeFab();
        } else if (_searching) {
          _closeSearch();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: colors.surface,
          scrolledUnderElevation: 0,
          title: Row(
            children: [
              const Text(
                'PoxeDex',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _searching
                      ? _buildSearchField(colors)
                      : Align(
                    key: const ValueKey('search-icon'),
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: 'Search',
                      icon: const Icon(Icons.search),
                      onPressed: _openSearch,
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              width: double.infinity,
              height: 48,
              color: colors.surfaceContainerHigh,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              child: Text(
                widget.pageTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(child: widget.body),
            if (showFab) ...[
              // Scrim: ketuk area luar untuk menutup menu
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: !_fabOpen,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _closeFab,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      color: _fabOpen ? Colors.black38 : Colors.transparent,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                bottom: 16 + MediaQuery.of(context).padding.bottom,
                child: ExpandableFab(
                  isOpen: _fabOpen,
                  onToggle: () => setState(() => _fabOpen = !_fabOpen),
                  actions: actions,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(ColorScheme colors) {
    return SizedBox(
      key: const ValueKey('search-field'),
      height: 40,
      child: TextField(
        controller: _searchController,
        autofocus: true,
        textInputAction: TextInputAction.search,
        onChanged: widget.onSearchChanged,
        onSubmitted: widget.onSearchSubmitted,
        decoration: InputDecoration(
          hintText: 'Search....',
          isDense: true,
          filled: true,
          fillColor: colors.surfaceContainerHighest,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          suffixIcon: IconButton(
            tooltip: 'Close search',
            icon: const Icon(Icons.close, size: 20),
            onPressed: _closeSearch,
          ),
        ),
      ),
    );
  }
}