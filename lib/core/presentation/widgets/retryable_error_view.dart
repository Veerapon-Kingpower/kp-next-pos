import 'package:flutter/material.dart';

/// Shared retryable-error presentation. Used app-wide for any recoverable
/// failure (network, API, hardware) so error handling looks and behaves
/// consistently — see the `pos-sales-workflows` spec's requirement that
/// error states be identifiable without relying on colour alone.
class RetryableErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final IconData icon;

  const RetryableErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, semanticLabel: 'Error'),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
