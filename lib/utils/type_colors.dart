import 'package:flutter/material.dart';

class TypeColors {
  static const Map<String, Color> _colors = {
    'normal': Color(0xFFB5B9C4),
    'fire': Color(0xFFFB6C6C),
    'water': Color(0xFF76BDFE),
    'electric': Color(0xFFFFD86F),
    'grass': Color(0xFF48D0B0),
    'ice': Color(0xFF7FD7D7),
    'fighting': Color(0xFFD6674F),
    'poison': Color(0xFFB167C4),
    'ground': Color(0xFFD9A860),
    'flying': Color(0xFF9BB4E8),
    'psychic': Color(0xFFFA7FA9),
    'bug': Color(0xFFA8C03A),
    'rock': Color(0xFFB8A66A),
    'ghost': Color(0xFF7B6BB5),
    'dragon': Color(0xFF6F7BE0),
    'dark': Color(0xFF6B5B55),
    'steel': Color(0xFF8FA3B5),
    'fairy': Color(0xFFF2A0C8),
    'stellar': Color(0xFF5CB3A8),
  };

  static Color of(String type) => _colors[type] ?? const Color(0xFF9E9E9E);

  /// Warna teks/ikon yang kontras di atas [background].
  static Color onColor(Color background) =>
      ThemeData.estimateBrightnessForColor(background) == Brightness.dark
          ? Colors.white
          : Colors.black87;
}