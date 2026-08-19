import 'package:flutter/material.dart';

/// Shared loading state — centred spinner with an optional message, used
/// while any API/hardware call is in flight.
class LoadingView extends StatelessWidget {
  final String? message;

  const LoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[const SizedBox(height: 12), Text(message!)],
        ],
      ),
    );
  }
}
