import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/pokemon_detail.dart';
import '../models/pokemon_summary.dart';

class PokeApiService {
  static const _baseUrl = 'https://pokeapi.co/api/v2';

  // static: dipakai bersama, jadi data yang sama tidak diminta ulang
  static final Map<int, PokemonDetail> _detailCache = {};
  static List<PokemonSummary>? _allCache;

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
  /// Dipakai halaman Favorites (dan nanti untuk pencarian).
  Future<List<PokemonSummary>> fetchAllPokemon() async {
    final cached = _allCache;
    if (cached != null) return cached;

    final uri = Uri.parse('$_baseUrl/pokemon?limit=1025&offset=0');
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
}

// JSON mentah untuk referensi:
// https://pokeapi.co/api/v2/pokemon?limit=20&offset=0
// https://pokeapi.co/api/v2/pokemon/1
// https://pokeapi.co/api/v2/pokemon-species/1
// https://pokeapi.co/api/v2/type
// https://pokeapi.co/api/v2/type/grass