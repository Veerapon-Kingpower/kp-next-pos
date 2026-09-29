import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../test_ids.dart';
import '../widgets/test_id.dart';
import 'desktop_tokens.dart';

/// Full-screen desktop wizard step (POS Desktop mockup screens 5 / 6): an
/// ink top bar with logo, [title] / [subtitle], "Step n of m" pills and an
/// Esc hint; Esc (key or chip) pops back a step.
class DesktopWizardFrame extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int step;
  final int totalSteps;
  final String escapeLabel;
  final Widget body;

  const DesktopWizardFrame({
    super.key,
    required this.title,
    required this.step,
    required this.totalSteps,
    required this.escapeLabel,
    required this.body,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    void back() => Navigator.of(context).maybePop();

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): back},
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: AppColors.surfaceAlt,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(
                color: AppColors.ink,
                child: SafeArea(
                  bottom: false,
                  child: SizedBox(
                    height: DesktopMetrics.topBarHeight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: const Image(
                              image: AssetImage(
                                'assets/images/kingpower_mobile_logo.png',
                              ),
                              height: 30,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Container(
                            width: 1,
                            height: 26,
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                          const SizedBox(width: 18),
                          Text(
                            title,
                            style: DesktopText.screenTitle.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: subtitle == null
                                ? const SizedBox.shrink()
                                : Text(
                                    subtitle!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      color: Colors.white.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ),
                          ),
                          TestId(
                            DesktopPaymentIds.wizardSteps,
                            child: Row(
                              children: [
                                Text(
                                  'Step $step of $totalSteps',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                for (var i = 1; i <= totalSteps; i++) ...[
                                  if (i > 1) const SizedBox(width: 4),
                                  Container(
                                    width: 34,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: i <= step
                                          ? AppColors.gold
                                          : Colors.white.withValues(
                                              alpha: 0.22,
                                            ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 18),
                          TestId(
                            DesktopPaymentIds.wizardEscape,
                            child: OutlinedButton(
                              onPressed: back,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.22),
                                ),
                              ),
                              child: Text(escapeLabel),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}
