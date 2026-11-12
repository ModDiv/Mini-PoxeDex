import 'package:flutter/material.dart';

class TypeIcons {
  /// 18 type, urut seperti di PokeAPI.
  static const List<String> all = [
    'normal', 'fighting', 'flying', 'poison', 'ground', 'rock',
    'bug', 'ghost', 'steel', 'fire', 'water', 'grass',
    'electric', 'psychic', 'ice', 'dragon', 'dark', 'fairy',
  ];

  static const Map<String, IconData> _icons = {
    'normal': Icons.circle_outlined,
    'fighting': Icons.sports_mma,
    'flying': Icons.air,
    'poison': Icons.science,
    'ground': Icons.terrain,
    'rock': Icons.diamond,
    'bug': Icons.bug_report,
    'ghost': Icons.nightlight_round,
    'steel': Icons.settings,
    'fire': Icons.local_fire_department,
    'water': Icons.water_drop,
    'grass': Icons.eco,
    'electric': Icons.bolt,
    'psychic': Icons.psychology,
    'ice': Icons.ac_unit,
    'dragon': Icons.flare,
    'dark': Icons.remove_red_eye,
    'fairy': Icons.auto_awesome,
  };

  static IconData of(String type) => _icons[type] ?? Icons.help_outline;
}