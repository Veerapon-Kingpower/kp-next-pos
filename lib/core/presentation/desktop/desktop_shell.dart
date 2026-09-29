import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../handheld/handheld_tokens.dart';
import '../test_ids.dart';
import '../widgets/test_id.dart';
import 'desktop_tokens.dart';

class DesktopNavItem {
  final String id;
  final IconData icon;
  final String label;

  /// Footer items run this directly; main items report via
  /// [DesktopShell.onSelected] instead.
  final VoidCallback? onTap;

  const DesktopNavItem({
    required this.id,
    required this.icon,
    required this.label,
    this.onTap,
  });
}

/// One "Label **value**" pair in the top bar (Store / Machine / Shift …).
class DesktopContextItem {
  final String label;
  final String value;

  const DesktopContextItem({required this.label, required this.value});
}

class DesktopUser {
  final String name;
  final String detail;

  const DesktopUser({required this.name, required this.detail});
}

/// Desktop station frame from the POS Desktop mockup (screens 2–13): an
/// 84 dp ink rail (logo, primary destinations, footer actions such as Sign
/// out) and a 64 dp white top bar (screen title, station context, actions,
/// signed-in user) above the [body].
class DesktopShell extends StatelessWidget {
  final List<DesktopNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<DesktopNavItem> footerItems;
  final String title;
  final String? subtitle;
  final List<DesktopContextItem> contextItems;
  final List<Widget> actions;
  final DesktopUser? user;
  final Widget body;

  const DesktopShell({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.title,
    required this.body,
    this.footerItems = const [],
    this.subtitle,
    this.contextItems = const [],
    this.actions = const [],
    this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DesktopRail(
            items: items,
            selectedIndex: selectedIndex,
            onSelected: onSelected,
            footerItems: footerItems,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopBar(
                  title: title,
                  subtitle: subtitle,
                  contextItems: contextItems,
                  actions: actions,
                  user: user,
                ),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DesktopRail extends StatelessWidget {
  final List<DesktopNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<DesktopNavItem> footerItems;

  const DesktopRail({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.footerItems = const [],
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: DesktopMetrics.railWidth,
      child: ColoredBox(
        color: AppColors.ink,
        child: SafeArea(
          right: false,
          child: Column(
            children: [
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: const Image(
                  image: AssetImage('assets/images/kingpower_mobile_logo.png'),
                  width: 44,
                  height: 44,
                  semanticLabel: 'King Power',
                ),
              ),
              const SizedBox(height: 22),
              for (var i = 0; i < items.length; i++)
                _RailButton(
                  item: items[i],
                  selected: i == selectedIndex,
                  onTap: () => onSelected(i),
                ),
              const Spacer(),
              for (final item in footerItems)
                _RailButton(item: item, selected: false, onTap: item.onTap),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  final DesktopNavItem item;
  final bool selected;
  final VoidCallback? onTap;

  const _RailButton({required this.item, required this.selected, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.goldOnInk
        : Colors.white.withValues(alpha: 0.6);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: TestId(
        item.id,
        child: Semantics(
          button: true,
          selected: selected,
          child: Material(
            color: selected
                ? AppColors.gold.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 60,
                height: 58,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, size: 20, color: color),
                    const SizedBox(height: 5),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 9.5, color: color),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<DesktopContextItem> contextItems;
  final List<Widget> actions;
  final DesktopUser? user;

  const _TopBar({
    required this.title,
    required this.subtitle,
    required this.contextItems,
    required this.actions,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return TestId(
      DesktopIds.topBar,
      child: Container(
        height: DesktopMetrics.topBarHeight,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: [
            Text(title, style: DesktopText.screenTitle),
            if (subtitle != null) ...[
              const SizedBox(width: 14),
              Flexible(
                child: Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.mutedText,
                  ),
                ),
              ),
            ],
            for (final item in contextItems) ...[
              const SizedBox(width: 16),
              Container(width: 1, height: 26, color: AppColors.line),
              const SizedBox(width: 16),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${item.label} ',
                      style: const TextStyle(color: AppColors.mutedText),
                    ),
                    TextSpan(
                      text: item.value,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
            const Spacer(),
            for (final action in actions) ...[
              action,
              const SizedBox(width: 10),
            ],
            if (user != null) _UserChip(user: user!),
          ],
        ),
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  final DesktopUser user;

  const _UserChip({required this.user});

  @override
  Widget build(BuildContext context) {
    final parts = user.name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final initials = parts.isEmpty
        ? '?'
        : (parts.first[0] + (parts.length > 1 ? parts.last[0] : ''))
              .toUpperCase();
    return TestId(
      DesktopIds.userChip,
      child: Container(
        padding: const EdgeInsets.only(left: 18),
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.goldDark,
                shape: BoxShape.circle,
              ),
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  user.detail,
                  style: HandheldText.bodySmall.copyWith(fontSize: 11.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
