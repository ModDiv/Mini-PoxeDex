class PokemonSummary {
  final int id;
  final String name;

  const PokemonSummary({required this.id, required this.name});

  factory PokemonSummary.fromJson(Map<String, dynamic> json) {
    // url contoh: https://pokeapi.co/api/v2/pokemon/1/
    final segments = Uri.parse(json['url'] as String)
        .pathSegments
        .where((s) => s.isNotEmpty);
    return PokemonSummary(
      id: int.parse(segments.last),
      name: json['name'] as String,
    );
  }

  String get imageUrl =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';

  String get displayName =>
      name.isEmpty ? name : name[0].toUpperCase() + name.substring(1);

  String get displayId => '#${id.toString().padLeft(3, '0')}';
}