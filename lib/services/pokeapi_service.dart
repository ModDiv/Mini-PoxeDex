import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/pokemon_detail.dart';
import '../models/pokemon_summary.dart';

class PokeApiService {
  static const _baseUrl = 'https://pokeapi.co/api/v2';
  static const _maxId = 1025;

  // static: dipakai bersama, jadi data yang sama tidak diminta ulang
  static final Map<int, PokemonDetail> _detailCache = {};
  static List<PokemonSummary>? _allCache;
  static List<String>? _typesCache;
  static final Map<String, Set<int>> _typeIdsCache = {};

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

  /// Daftar nama type (/type). "unknown" dan "stellar" disembunyikan.
  Future<List<String>> fetchTypes() async {
    final cached = _typesCache;
    if (cached != null) return cached;

    final uri = Uri.parse('$_baseUrl/type?limit=100');
    final response = await http.get(uri).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Failed to load types (code ${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final types = (data['results'] as List<dynamic>)
        .map((e) => (e as Map<String, dynamic>)['name'] as String)
        .where((n) => n != 'unknown' && n != 'stellar')
        .toList();
    _typesCache = types;
    return types;
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
      final url = (e as Map<String, dynamic>)['pokemon']['url'] as String;
      final segments =
      Uri.parse(url).pathSegments.where((s) => s.isNotEmpty);
      final id = int.parse(segments.last);
      if (id <= _maxId) ids.add(id); // buang varian (ID 10001+)
    }
    _typeIdsCache[type] = ids;
    return ids;
  }
}