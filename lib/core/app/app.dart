import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_page.dart';
import '../theme/app_theme.dart';

class KpPosApp extends StatefulWidget {
  final GoRouter router;

  const KpPosApp({super.key, required this.router});

  @override
  State<KpPosApp> createState() => _KpPosAppState();
}

class _KpPosAppState extends State<KpPosApp> {
  bool _precached = false;

  @override
  Widget build(BuildContext context) {
    // Precache the Login background once, on the very first build, rather
    // than letting Image resolve/decode it fresh on every LoginPage mount.
    // Without this, revisiting Login after logout has shown corrupted
    // diagonal-streak rendering on Windows desktop — a decode-on-revisit
    // texture issue this sidesteps by keeping the already-decoded image
    // permanently resident instead of letting it drop out of cache when
    // LoginPage unmounts (see `login_page.dart`'s `loginBackgroundAsset`).
    if (!_precached) {
      _precached = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) precacheImage(loginBackgroundAsset, context);
      });
    }

    return MaterialApp.router(
      title: 'King Power POS',
      theme: AppTheme.light(),
      routerConfig: widget.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
