import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/pokemon_summary.dart';

class PokemonCard extends StatelessWidget {
  final PokemonSummary pokemon;
  final VoidCallback? onTap;
  final bool useHero;

  const PokemonCard({
    super.key,
    required this.pokemon,
    this.onTap,
    this.useHero = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final image = CachedNetworkImage(
      imageUrl: pokemon.imageUrl,
      fit: BoxFit.contain,
      placeholder: (_, __) => const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (_, __, ___) => Icon(
        Icons.catching_pokemon,
        size: 48,
        color: colors.outline,
      ),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      color: colors.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  pokemon.displayId,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: useHero
                    ? Hero(tag: 'pokemon-${pokemon.id}', child: image)
                    : image,
              ),
              const SizedBox(height: 8),
              Text(
                pokemon.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}