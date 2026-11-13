import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Grid kerangka kartu dengan efek kilau, ditampilkan saat data dimuat.
class SkeletonGrid extends StatelessWidget {
  final int itemCount;

  const SkeletonGrid({super.key, this.itemCount = 8});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Shimmer.fromColors(
      baseColor: colors.surfaceContainerHigh,
      highlightColor: colors.surfaceContainerLowest,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: itemCount,
        itemBuilder: (_, __) => const _SkeletonCard(),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, // warna ini ditimpa efek shimmer
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Align(alignment: Alignment.centerRight, child: bar(36, 14)),
          const Expanded(
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(width: 90, height: 90),
              ),
            ),
          ),
          const SizedBox(height: 8),
          bar(80, 16),
        ],
      ),
    );
  }
}