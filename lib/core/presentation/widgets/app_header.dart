import 'package:flutter/material.dart';

/// Shared page header — wraps [AppBar] so every workflow gets the same
/// title styling, back behaviour, and action placement instead of each
/// feature building its own.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget> actions;
  final Widget? leading;

  const AppHeader({
    super.key,
    required this.title,
    this.actions = const [],
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title), leading: leading, actions: actions);
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
