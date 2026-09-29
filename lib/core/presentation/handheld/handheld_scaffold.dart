import 'package:flutter/material.dart';

import '../../theme/app_breakpoints.dart';
import '../../theme/app_colors.dart';
import 'handheld_tokens.dart';

/// Page frame for every handheld screen: optional dark [header], the
/// [body], an optional persistent [actionBar] and an optional [navBar],
/// stacked top to bottom on the canvas colour.
///
/// Size classes (handheld spec decision 5): on compact widths the body
/// fills the screen as drawn; on medium widths (tablet / iPad portrait) the
/// body is centred at [HandheldMetrics.mediumContentMaxWidth] so rows and
/// fields don't stretch across a 820 dp screen, while the header, action
/// bar and nav bar keep spanning the full width.
class HandheldScaffold extends StatelessWidget {
  final Widget? header;
  final Widget body;
  final Widget? actionBar;
  final Widget? navBar;
  final Color backgroundColor;

  const HandheldScaffold({
    super.key,
    this.header,
    required this.body,
    this.actionBar,
    this.navBar,
    this.backgroundColor = AppColors.surfaceAlt,
  });

  @override
  Widget build(BuildContext context) {
    final isMedium = AppBreakpoints.sizeClass(context) != AppSizeClass.compact;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?header,
          Expanded(
            child: isMedium
                ? Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: HandheldMetrics.mediumContentMaxWidth,
                      ),
                      child: body,
                    ),
                  )
                : body,
          ),
          ?actionBar,
          ?navBar,
        ],
      ),
    );
  }
}

/// Centres [child] at the medium content width on tablet / iPad portrait,
/// and passes it through unchanged on compact widths — for header / bar
/// content that should line up with a [HandheldScaffold] body.
class HandheldContentWidth extends StatelessWidget {
  final Widget child;

  const HandheldContentWidth({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (AppBreakpoints.sizeClass(context) == AppSizeClass.compact) {
      return child;
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: HandheldMetrics.mediumContentMaxWidth,
        ),
        child: child,
      ),
    );
  }
}
