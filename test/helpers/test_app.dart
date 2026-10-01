import 'package:flutter/material.dart';
import 'package:kp_pos/core/theme/app_theme.dart';

/// [MaterialApp] with the app's real [AppTheme] — use it in place of a bare
/// `MaterialApp` in every widget test, so a test lays a screen out the way
/// the app does. A bare `MaterialApp` hides theme-only bugs: the theme's
/// full-width `FilledButton` minimum (`Size.fromHeight`) once broke
/// Signature's Save inside a `Row` while its test passed.
class TestApp extends MaterialApp {
  TestApp({
    super.key,
    super.navigatorKey,
    super.scaffoldMessengerKey,
    super.home,
    super.routes,
    super.initialRoute,
    super.onGenerateRoute,
    super.onUnknownRoute,
    super.navigatorObservers,
    super.builder,
    super.title,
    super.locale,
    super.localizationsDelegates,
    super.supportedLocales,
    super.shortcuts,
    super.actions,
    super.debugShowCheckedModeBanner,
  }) : super(theme: AppTheme.light());
}
