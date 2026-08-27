import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// One column heading for [DesktopDataTable].
class DesktopDataColumn {
  final String label;
  final TextAlign align;

  const DesktopDataColumn({required this.label, this.align = TextAlign.left});
}

/// Dense, header-plus-rows table used by the POS Desktop mockup's Sale,
/// Basket, and Enquiry screens — replacing the five-stacked-lines-per-item
/// mobile layout with one table row per item now that desktop width has
/// room for it (see docs/superpowers/specs/2026-08-27-pos-desktop-design.md).
/// Deliberately generic: callers supply pre-built cell widgets rather than
/// this table owning any row-formatting logic.
class DesktopDataTable extends StatelessWidget {
  final List<DesktopDataColumn> columns;
  final List<List<Widget>> rows;
  final Widget? emptyPlaceholder;

  const DesktopDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.emptyPlaceholder,
  });

  @override
  Widget build(BuildContext context) {
    assert(
      rows.every((row) => row.length == columns.length),
      'Each row must have exactly one cell per column',
    );

    if (rows.isEmpty && emptyPlaceholder != null) {
      return emptyPlaceholder!;
    }

    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TableRow(
          columns.map(
            (c) => Text(
              c.label,
              textAlign: c.align,
              style: textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        const Divider(height: 1, color: AppColors.divider),
        for (var i = 0; i < rows.length; i++) ...[
          _TableRow(rows[i]),
          if (i != rows.length - 1)
            const Divider(height: 1, color: AppColors.divider),
        ],
      ],
    );
  }
}

class _TableRow extends StatelessWidget {
  final Iterable<Widget> cells;

  const _TableRow(this.cells);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          for (final cell in cells) Expanded(child: cell),
        ],
      ),
    );
  }
}
