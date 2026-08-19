import 'package:flutter/material.dart';

/// Route-target stub for the device-setup route — replaced by its real
/// feature implementation in task 6.x. Login and home now have real
/// implementations (see `features/auth/presentation/`).
class DeviceSetupPlaceholderPage extends StatelessWidget {
  const DeviceSetupPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Device setup (placeholder — see task 6.x)')),
    );
  }
}
