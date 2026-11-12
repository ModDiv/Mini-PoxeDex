import 'package:flutter/material.dart';

import '../utils/type_colors.dart';
import '../utils/type_icons.dart';

/// Mengembalikan type terpilih saat user menekan APPLY.
/// Mengembalikan null jika sheet ditutup tanpa APPLY.
Future<Set<String>?> showTypeFilterSheet(
    BuildContext context, {
      required Set<String> initial,
    }) {
  return showModalBottomSheet<Set<String>>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => _TypeFilterSheet(initial: initial),
  );
}

class _TypeFilterSheet extends StatefulWidget {
  final Set<String> initial;

  const _TypeFilterSheet({required this.initial});

  @override
  State<_TypeFilterSheet> createState() => _TypeFilterSheetState();
}

class _TypeFilterSheetState extends State<_TypeFilterSheet> {
  static const _maxSelected = 2; // satu Pokemon maksimal punya 2 type
  static const _perRow = 5;

  late final List<String> _selected = widget.initial.toList();

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  void _toggle(String type) {
    setState(() {
      if (_selected.contains(type)) {
        _selected.remove(type);
      } else {
        if (_selected.length >= _maxSelected) _selected.removeAt(0);
        _selected.add(type);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final rows = <List<String>>[];
    for (var i = 0; i < TypeIcons.all.length; i += _perRow) {
      final end = (i + _perRow).clamp(0, TypeIcons.all.length);
      rows.add(TypeIcons.all.sublist(i, end));
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Filter By...',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TYPES', style: TextStyle(fontSize: 16)),
                Flexible(
                  child: Text(
                    _selected.isEmpty
                        ? 'All'
                        : _selected.map(_cap).join('/'),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.black87, height: 16),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final cellWidth = constraints.maxWidth / _perRow;
                return Column(
                  children: [
                    for (final row in rows)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (final type in row)
                              SizedBox(
                                width: cellWidth,
                                child: _TypeButton(
                                  type: type,
                                  label: _cap(type),
                                  selected: _selected.contains(type),
                                  onTap: () => _toggle(type),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (_selected.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(_selected.clear),
                    child: const Text('Clear'),
                  ),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: () =>
                        Navigator.pop(context, _selected.toSet()),
                    icon: const Icon(Icons.category_outlined),
                    label: const Text(
                      'APPLY',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String type;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.type,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = TypeColors.of(type);

    // Dipilih: latar warna type, ikon kontras.
    // Belum dipilih: latar pucat dari warna type, ikon berwarna type (digelapkan).
    final background =
    selected ? typeColor : typeColor.withAlpha(60);
    final iconColor = selected
        ? TypeColors.onColor(typeColor)
        : HSLColor.fromColor(typeColor).withLightness(0.35).toColor();

    return InkResponse(
      onTap: onTap,
      radius: 32,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? Colors.black87 : typeColor,
                width: selected ? 2.5 : 1.5,
              ),
            ),
            child: Icon(TypeIcons.of(type), color: iconColor, size: 26),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}