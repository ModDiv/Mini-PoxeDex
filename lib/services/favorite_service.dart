import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteService extends ChangeNotifier {
  FavoriteService._();
  static final FavoriteService instance = FavoriteService._();

  static const _key = 'favorites';

  // pokemon_id -> added_at
  final Map<int, DateTime> _items = {};

  /// Panggil sekali di main() sebelum runApp.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _items
          ..clear()
          ..addAll(map.map(
                (k, v) => MapEntry(int.parse(k), DateTime.parse(v as String)),
          ));
      }
    } catch (_) {
      _items.clear(); // data rusak: mulai dari kosong
    }
    notifyListeners();
  }

  bool isFavorite(int id) => _items.containsKey(id);

  /// ID favorit, yang terbaru ditambahkan berada paling depan.
  List<int> get ids {
    final entries = _items.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.map((e) => e.key).toList();
  }

  Future<void> add(int id) async {
    _items[id] = DateTime.now();
    notifyListeners();
    await _save();
  }

  Future<void> remove(int id) async {
    _items.remove(id);
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final map = _items.map((k, v) => MapEntry('$k', v.toIso8601String()));
    await prefs.setString(_key, jsonEncode(map));
  }
}