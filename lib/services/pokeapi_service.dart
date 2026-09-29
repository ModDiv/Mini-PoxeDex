import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/pokemon_summary.dart';

class PokeApiService {
  static const _baseUrl = 'https://pokeapi.co/api/v2';

  Future<List<PokemonSummary>> fetchPokemonList({
    int limit = 20,
    int offset = 0,
  }) async {
    final uri = Uri.parse('$_baseUrl/pokemon?limit=$limit&offset=$offset');
    final response = await http.get(uri).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Gagal memuat data (kode ${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>;
    return results
        .map((e) => PokemonSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}