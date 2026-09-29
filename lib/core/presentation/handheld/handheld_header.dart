import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../widgets/test_id.dart';
import 'handheld_scaffold.dart';
import 'handheld_tokens.dart';

/// Dark `ink` page header from the handheld mockup: optional [leading]
/// (e.g. an avatar or back button), [title] + [subtitle], optional
/// [trailing] (status / action), and an optional row of [stats] below.
class HandheldHeader extends StatelessWidget {
  final String title;
  final String? titleId;
  final String? subtitle;
  final String? subtitleId;
  final Widget? leading;
  final Widget? trailing;
  final List<HandheldStat> stats;

  const HandheldHeader({
    super.key,
    required this.title,
    this.titleId,
    this.subtitle,
    this.subtitleId,
    this.leading,
    this.trailing,
    this.stats = const [],
  });

  @override
  Widget build(BuildContext context) {
    Widget titleText = Text(
      title,
      style: HandheldText.title.copyWith(color: Colors.white),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    if (titleId != null) titleText = TestId(titleId!, child: titleText);

    Widget? subtitleText;
    if (subtitle != null) {
      subtitleText = Text(
        subtitle!,
        style: HandheldText.bodySmall.copyWith(
          color: Colors.white.withValues(alpha: 0.6),
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
      if (subtitleId != null) {
        subtitleText = TestId(subtitleId!, child: subtitleText);
      }
    }

    return ColoredBox(
      color: AppColors.ink,
      child: SafeArea(
        bottom: false,
        child: HandheldContentWidth(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              HandheldMetrics.pagePadding,
              8,
              HandheldMetrics.pagePadding,
              20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          titleText,
                          if (subtitleText != null) ...[
                            const SizedBox(height: 3),
                            subtitleText,
                          ],
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 12),
                      trailing!,
                    ],
                  ],
                ),
                if (stats.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      for (var i = 0; i < stats.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(flex: stats[i].flex, child: stats[i]),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A caps label over one big tabular number, on a translucent tile —
/// the "one number that matters" block inside [HandheldHeader].
class HandheldStat extends StatelessWidget {
  final String id;
  final String label;
  final String value;

  /// Relative width inside the header's stat row (mockup: 1 vs 1.5).
  final int flex;

  const HandheldStat({
    super.key,
    required this.id,
    required this.label,
    required this.value,
    this.flex = 2,
  });

  @override
  Widget build(BuildContext context) {
    return TestId(
      id,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(HandheldMetrics.radiusSm),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: HandheldText.overline.copyWith(
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: HandheldText.statValue.copyWith(color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
