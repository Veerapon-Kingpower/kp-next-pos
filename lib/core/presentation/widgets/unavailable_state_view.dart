import 'package:flutter/material.dart';

/// Shared full-screen state for "no network" or "required device
/// unavailable" — distinct from [RetryableErrorView] because these are
/// ambient conditions rather than a failed action, and per the
/// `cross-platform-hardware` spec's hardware readiness requirement, an
/// unavailable device must block only the dependent operation, not the
/// whole app; this widget is what a blocked workflow shows in its place.
class UnavailableStateView extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const UnavailableStateView({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.icon = Icons.wifi_off,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, semanticLabel: title),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
