import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../widgets/test_id.dart';
import 'handheld_scaffold.dart';
import 'handheld_tokens.dart';

class HandheldNavItem {
  final String id;
  final IconData icon;
  final String label;

  const HandheldNavItem({
    required this.id,
    required this.icon,
    required this.label,
  });
}

/// The handheld's 4-item bottom navigation (Home / Sale / Enquiry / Menu):
/// the selected item sits on a cream pill in `goldDark`.
class HandheldNavBar extends StatelessWidget {
  final List<HandheldNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const HandheldNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: HandheldContentWidth(
          child: SizedBox(
            height: HandheldMetrics.navBarHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: _NavButton(
                        item: items[i],
                        selected: i == selectedIndex,
                        onTap: () => onSelected(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final HandheldNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Inactive uses mutedText rather than the mockup's #9AA2AE, which is
    // below WCAG AA for a text label.
    final color = selected ? AppColors.goldDark : AppColors.mutedText;
    return Center(
      child: TestId(
        item.id,
        child: Semantics(
          button: true,
          selected: selected,
          child: Material(
            color: selected ? AppColors.cream : Colors.transparent,
            borderRadius: BorderRadius.circular(HandheldMetrics.radiusSm),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(HandheldMetrics.radiusSm),
              child: SizedBox(
                height: HandheldMetrics.navItemHeight,
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, size: 19, color: color),
                    const SizedBox(height: 5),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: color,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
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
