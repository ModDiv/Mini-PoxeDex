import 'package:flutter/material.dart';

/// Mengembalikan true jika user menekan "Yes".
Future<bool> confirmRemoveFavorite(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final colors = Theme.of(dialogContext).colorScheme;
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, size: 56, color: colors.error),
              const SizedBox(height: 16),
              const Text(
                'Remove this pokemon from favorite?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.error,
                        foregroundColor: colors.onError,
                      ),
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Yes'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  return result == true;
}