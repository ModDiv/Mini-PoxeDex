import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/favorite_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FavoriteService.instance.load();
  runApp(const PokedexApp());
}

class PokedexApp extends StatelessWidget {
  const PokedexApp({super.key});

  static const _pokeRed = Color(0xFFE3350D);
  static const _pokeYellow = Color(0xFFFFCB05);
  static const _bodyFont = 'Poppins';
  static const _titleFont = 'Fredoka';

  ThemeData _buildTheme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2800FF),
      brightness: brightness,
    ).copyWith(tertiary: _pokeYellow);

    final base = ThemeData(
      colorScheme: scheme,
      brightness: brightness,
      useMaterial3: true,
      fontFamily: _bodyFont, // font isi untuk seluruh aplikasi
    );

    // Judul memakai Fredoka
    TextStyle? title(TextStyle? s, [FontWeight? w]) =>
        s?.copyWith(fontFamily: _titleFont, fontWeight: w);

    final t = base.textTheme;
    final textTheme = t.copyWith(
      displayLarge: title(t.displayLarge),
      displayMedium: title(t.displayMedium),
      displaySmall: title(t.displaySmall),
      headlineLarge: title(t.headlineLarge),
      headlineMedium: title(t.headlineMedium),
      headlineSmall: title(t.headlineSmall),
      titleLarge: title(t.titleLarge, FontWeight.w600),
      titleMedium: title(t.titleMedium, FontWeight.w600),
    );

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: _titleFont,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: _bodyFont,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: _bodyFont,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PoxeDex',
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}