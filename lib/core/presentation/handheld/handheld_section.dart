import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../widgets/test_id.dart';
import 'handheld_tokens.dart';

/// White card with a title / count header, [children] rows, and an optional
/// cream [footer] hint strip — the list container used across the handheld
/// mockup (suspended bills, settings groups, enquiry results, …).
class HandheldSection extends StatelessWidget {
  final String? id;
  final String title;
  final String? count;
  final Widget? trailing;
  final List<Widget> children;
  final Widget? footer;

  const HandheldSection({
    super.key,
    this.id,
    required this.title,
    this.count,
    this.trailing,
    required this.children,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final section = DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(HandheldMetrics.radius),
        border: Border.all(color: AppColors.line),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(HandheldMetrics.radius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFEDEFF3))),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 13, 16, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(title, style: HandheldText.sectionTitle),
                    ),
                    if (count != null)
                      Text(
                        count!,
                        style: HandheldText.bodySmall.copyWith(fontSize: 11.5),
                      ),
                    ?trailing,
                  ],
                ),
              ),
            ),
            ...children,
            if (footer != null)
              DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.cream,
                  border: Border(top: BorderSide(color: Color(0xFFF0E8D8))),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: DefaultTextStyle.merge(
                    style: const TextStyle(
                      fontSize: 11.5,
                      height: 1.45,
                      color: AppColors.goldDark,
                    ),
                    child: footer!,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return id == null ? section : TestId(id!, child: section);
  }
}

/// One row inside a [HandheldSection]: [title] / [subtitle] on the left,
/// optional [trailing] on the right, divider underneath.
class HandheldListRow extends StatelessWidget {
  final String? id;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const HandheldListRow({
    super.key,
    this.id,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF4F6F8))),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: HandheldText.bodySmall.copyWith(fontSize: 11.5),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            ],
          ),
        ),
      ),
    );
    return id == null ? row : TestId(id!, child: row);
  }
}
