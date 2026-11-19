import 'package:flutter/material.dart';

Future<void> showAboutPoxeDex(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final colors = Theme.of(dialogContext).colorScheme;
      final textTheme = Theme.of(dialogContext).textTheme;

      Widget section(IconData icon, String title, String body) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.justify,
              style: TextStyle(
                height: 1.5,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        );
      }

      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.catching_pokemon, size: 56, color: colors.primary),
                const SizedBox(height: 12),
                Text('About', style: textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  'Mini PoxeDex · v1.0.0',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        section(
                          Icons.copyright,
                          'Copyright',
                          'Pokémon and all related names, characters, artwork, '
                              'and content are the property of their respective '
                              'owners, including Nintendo, Game Freak, Creatures '
                              'Inc., and The Pokémon Company. This app is an '
                              'unofficial, non-commercial fan project and is not '
                              'affiliated with, sponsored by, or endorsed by them.',
                        ),
                        const SizedBox(height: 16),
                        section(
                          Icons.cloud_outlined,
                          'Data Source',
                          'Pokémon data is provided by PokeAPI (pokeapi.co), a '
                              'free and open RESTful API developed and maintained '
                              'by the community.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}