import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/pokemon_detail.dart';
import '../models/pokemon_summary.dart';
import '../utils/type_icons.dart';

class PokeApiService {
  static const _baseUrl = 'https://pokeapi.co/api/v2';
  static const _maxId = 1025;

  // static: dipakai bersama, jadi data yang sama tidak diminta ulang
  static final Map<int, PokemonDetail> _detailCache = {};
  static List<PokemonSummary>? _allCache;
  static final Map<String, Set<int>> _typeIdsCache = {};
  static Map<int, String>? _primaryTypesCache;
  static Future<Map<int, String>>? _primaryTypesFuture;

  static int _idFromUrl(String url) =>
      int.parse(Uri.parse(url).pathSegments.where((s) => s.isNotEmpty).last);

  /// Daftar Pokemon per halaman (name + url saja).
  Future<List<PokemonSummary>> fetchPokemonList({
    int limit = 20,
    int offset = 0,
  }) async {
    final uri = Uri.parse('$_baseUrl/pokemon?limit=$limit&offset=$offset');
    final response = await http.get(uri).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Failed to load data (code ${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>;
    return results
        .map((e) => PokemonSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Detail satu Pokemon: type, height, weight (/pokemon/{id})
  /// dan deskripsi (/pokemon-species/{id}), diambil paralel.
  Future<PokemonDetail> fetchPokemonDetail(int id) async {
    final cached = _detailCache[id];
    if (cached != null) return cached;

    final responses = await Future.wait([
      http.get(Uri.parse('$_baseUrl/pokemon/$id')),
      http.get(Uri.parse('$_baseUrl/pokemon-species/$id')),
    ]).timeout(const Duration(seconds: 15));

    for (final r in responses) {
      if (r.statusCode != 200) {
        throw Exception('Failed to load details (code ${r.statusCode})');
      }
    }

    final detail = PokemonDetail.fromJson(
      jsonDecode(responses[0].body) as Map<String, dynamic>,
      jsonDecode(responses[1].body) as Map<String, dynamic>,
    );
    _detailCache[id] = detail;
    return detail;
  }

  /// Semua Pokemon nomor 1-1025 (name + id saja). Dicache setelah pertama kali.
  Future<List<PokemonSummary>> fetchAllPokemon() async {
    final cached = _allCache;
    if (cached != null) return cached;

    final uri = Uri.parse('$_baseUrl/pokemon?limit=$_maxId&offset=0');
    final response = await http.get(uri).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Failed to load data (code ${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final all = (data['results'] as List<dynamic>)
        .map((e) => PokemonSummary.fromJson(e as Map<String, dynamic>))
        .toList();
    _allCache = all;
    return all;
  }

  /// ID Pokemon (1-1025) yang memiliki [type] (/type/{nama}).
  Future<Set<int>> fetchPokemonIdsByType(String type) async {
    final cached = _typeIdsCache[type];
    if (cached != null) return cached;

    final uri = Uri.parse('$_baseUrl/type/$type');
    final response = await http.get(uri).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Failed to load type (code ${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final ids = <int>{};
    for (final e in data['pokemon'] as List<dynamic>) {
      // bentuk elemen: { "slot": 1, "pokemon": { "name": ..., "url": ... } }
      final id = _idFromUrl((e as Map<String, dynamic>)['pokemon']['url'] as String);
      if (id <= _maxId) ids.add(id); // buang varian (ID 10001+)
    }
    _typeIdsCache[type] = ids;
    return ids;
  }

  /// Peta ID Pokemon (1-1025) -> tipe utama. Memanggil 18 endpoint /type/{nama}
  /// sekali (paralel), lalu dicache. Di /type/{nama}, slot 1 = tipe utama.
  Future<Map<int, String>> fetchPrimaryTypes() {
    final cached = _primaryTypesCache;
    if (cached != null) return Future.value(cached);
    return _primaryTypesFuture ??= _loadPrimaryTypes().whenComplete(() {
      _primaryTypesFuture = null; // jika gagal, boleh dicoba lagi
    });
  }

  Future<Map<int, String>> _loadPrimaryTypes() async {
    final responses = await Future.wait(
      TypeIcons.all.map((t) => http.get(Uri.parse('$_baseUrl/type/$t'))),
    ).timeout(const Duration(seconds: 30));

    final result = <int, String>{};
    for (var i = 0; i < responses.length; i++) {
      final r = responses[i];
      if (r.statusCode != 200) {
        throw Exception('Failed to load types (code ${r.statusCode})');
      }
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      for (final e in data['pokemon'] as List<dynamic>) {
        final entry = e as Map<String, dynamic>;
        if (entry['slot'] != 1) continue; // hanya tipe utama
        final id = _idFromUrl(entry['pokemon']['url'] as String);
        if (id <= _maxId) result[id] = TypeIcons.all[i];
      }
    }
    _primaryTypesCache = result;
    return result;
  }
}