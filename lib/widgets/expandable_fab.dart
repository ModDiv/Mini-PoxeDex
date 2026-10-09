import 'package:flutter/material.dart';

class FabAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const FabAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class ExpandableFab extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onToggle;
  final List<FabAction> actions;

  const ExpandableFab({
    super.key,
    required this.isOpen,
    required this.onToggle,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < actions.length; i++)
          _ActionItem(
            action: actions[i],
            isOpen: isOpen,
            // item terdekat dengan tombol utama muncul paling dulu
            order: actions.length - 1 - i,
          ),
        FloatingActionButton(
          heroTag: null,
          tooltip: isOpen ? 'Close menu' : 'Open menu',
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.onPrimaryContainer,
          onPressed: onToggle,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) =>
                RotationTransition(turns: anim, child: child),
            child: Icon(
              isOpen ? Icons.close : Icons.catching_pokemon,
              key: ValueKey(isOpen),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  final FabAction action;
  final bool isOpen;
  final int order;

  const _ActionItem({
    required this.action,
    required this.isOpen,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final duration = Duration(milliseconds: 150 + 60 * order);

    return IgnorePointer(
      ignoring: !isOpen,
      child: AnimatedOpacity(
        opacity: isOpen ? 1 : 0,
        duration: duration,
        child: AnimatedSlide(
          offset: isOpen ? Offset.zero : const Offset(0, 0.4),
          duration: duration,
          curve: Curves.easeOut,
          child: Padding(
            // right: 8 supaya mini FAB (40) sejajar tengah dengan FAB utama (56)
            padding: const EdgeInsets.only(bottom: 12, right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  color: colors.surfaceContainerHighest,
                  elevation: 1,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: action.onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Text(
                        action.label,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton.small(
                  heroTag: null,
                  tooltip: action.label,
                  backgroundColor: colors.secondaryContainer,
                  foregroundColor: colors.onSecondaryContainer,
                  onPressed: action.onTap,
                  child: Icon(action.icon),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}