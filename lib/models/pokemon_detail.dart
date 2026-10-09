class PokemonDetail {
  final int id;
  final String name;
  final double heightM;
  final double weightKg;
  final List<String> types; // urut sesuai slot, types.first = tipe utama
  final String description;

  const PokemonDetail({
    required this.id,
    required this.name,
    required this.heightM,
    required this.weightKg,
    required this.types,
    required this.description,
  });

  factory PokemonDetail.fromJson(
      Map<String, dynamic> pokemon,
      Map<String, dynamic> species,
      ) {
    final rawTypes = List<Map<String, dynamic>>.from(pokemon['types'] as List)
      ..sort((a, b) => (a['slot'] as int).compareTo(b['slot'] as int));

    return PokemonDetail(
      id: pokemon['id'] as int,
      name: pokemon['name'] as String,
      heightM: (pokemon['height'] as int) / 10, // dm -> m
      weightKg: (pokemon['weight'] as int) / 10, // hg -> kg
      types: rawTypes.map((t) => t['type']['name'] as String).toList(),
      description: _extractDescription(species),
    );
  }

  static String _extractDescription(Map<String, dynamic> species) {
    final entries = species['flavor_text_entries'] as List;
    // Ambil entri bahasa Inggris paling baru (paling akhir di list)
    for (final e in entries.reversed) {
      if (e['language']['name'] == 'en') {
        return (e['flavor_text'] as String)
            .replaceAll(RegExp(r'[\n\f\u00ad]'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
      }
    }
    return 'No description available.';
  }

  String get primaryType => types.isEmpty ? 'unknown' : types.first;

  List<String> get displayTypes => types
      .map((t) => t.isEmpty ? t : t[0].toUpperCase() + t.substring(1))
      .toList();
}