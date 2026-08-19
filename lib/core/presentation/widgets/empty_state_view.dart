import 'package:flutter/material.dart';

/// Shared empty-result state — used by search/list workflows (enquiry,
/// pickup, customer search, ...) when a query legitimately returns nothing,
/// distinct from [RetryableErrorView] (a failure) and
/// [UnavailableStateView] (an ambient blocker).
class EmptyStateView extends StatelessWidget {
  final String message;
  final IconData icon;
  final Widget? action;

  const EmptyStateView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
