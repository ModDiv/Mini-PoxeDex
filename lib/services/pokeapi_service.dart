import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/pokemon_detail.dart';
import '../models/pokemon_summary.dart';

class PokeApiService {
  static const _baseUrl = 'https://pokeapi.co/api/v2';

  // static: dipakai bersama, jadi membuka Pokemon yang sama tidak request ulang
  static final Map<int, PokemonDetail> _detailCache = {};

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
}