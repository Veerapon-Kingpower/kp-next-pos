import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_sizing.dart';
import '../../theme/app_spacing.dart';

/// One tappable tile in a [HotkeyTileGrid].
class HotkeyTile {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const HotkeyTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

/// Grid of icon+label shortcut tiles for the Home dashboard mockup screen
/// (New sale / Registration / Add / Pickup, etc. — see
/// docs/superpowers/specs/2026-08-27-pos-desktop-design.md).
class HotkeyTileGrid extends StatelessWidget {
  final List<HotkeyTile> tiles;

  const HotkeyTileGrid({super.key, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      children: [for (final tile in tiles) _HotkeyTileButton(tile: tile)],
    );
  }
}

class _HotkeyTileButton extends StatelessWidget {
  final HotkeyTile tile;

  const _HotkeyTileButton({required this.tile});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key('hotkeyTile_${tile.label}'),
      onTap: tile.onTap,
      borderRadius: BorderRadius.circular(AppSizing.cornerRadiusMd),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(AppSizing.cornerRadiusMd),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              tile.icon,
              size: AppSizing.iconSizeLarge,
              color: AppColors.goldAccent,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(tile.label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
