import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/customer.dart';
import '../customer_summary.dart';

/// This build's King Power member sign-up page ([EnvironmentConfig]).
String get memberSignUpUrl => EnvironmentConfig.current.memberSignUpUrl;

/// Member sign-up: a QR of [url] the customer scans to enrol on their own
/// phone. The POS has no enrol API (nor did legacy), so once they are done
/// the cashier searches again to pick up the new member. With no [url] for
/// this build it says so rather than doing nothing.
Future<void> showMemberSignUp(
  BuildContext context, {
  required String url,
  VoidCallback? onSearchAgain,
}) {
  final hasUrl = url.trim().isNotEmpty;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => TestId(
      MemberIds.signUpDialog,
      child: AlertDialog(
        title: const Text('Sign up as King Power member'),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!hasUrl)
                const Text(
                  'Member sign-up is not set up for this build yet. Ask the '
                  'customer to sign up in the King Power app, then search '
                  'again.',
                  key: Key('memberSignUpUnavailable'),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.5, color: AppColors.mutedText),
                )
              else ...[
                const Text(
                  'Ask the customer to scan this with their phone and finish '
                  'signing up. Then search again to see their membership.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.5, color: AppColors.mutedText),
                ),
                const SizedBox(height: 16),
                TestId(
                  MemberIds.signUpQr,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: QrImageView(data: url, size: 220),
                  ),
                ),
                const SizedBox(height: 10),
                SelectableText(
                  url,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedText,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
          if (onSearchAgain != null)
            TestId(
              MemberIds.signUpSearchAgain,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  onSearchAgain();
                },
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Search again'),
                // Not the theme's full-width minimum — it sits in a row.
                style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
              ),
            ),
        ],
      ),
    ),
  );
}

/// The Sign up button. Always tappable — without a sign-up page for this
/// build its dialog explains that instead of the button doing nothing.
class MemberSignUpButton extends StatelessWidget {
  final String url;
  final VoidCallback? onSearchAgain;

  const MemberSignUpButton({super.key, required this.url, this.onSearchAgain});

  @override
  Widget build(BuildContext context) {
    return TestId(
      MemberIds.signUpButton,
      child: OutlinedButton.icon(
        onPressed: () =>
            showMemberSignUp(context, url: url, onSearchAgain: onSearchAgain),
        icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
        label: const Text('Sign up as member'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.goldDark,
          minimumSize: const Size(0, 44),
          side: const BorderSide(color: AppColors.goldMuted),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
      ),
    );
  }
}

/// A found customer who is not a King Power member: why there is no Carat,
/// e-Purse or privilege, and the way to become one.
class NonMemberNotice extends StatelessWidget {
  final String signUpUrl;
  final VoidCallback? onSearchAgain;

  const NonMemberNotice({
    super.key,
    required this.signUpUrl,
    this.onSearchAgain,
  });

  @override
  Widget build(BuildContext context) {
    return TestId(
      MemberIds.nonMember,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.goldMuted),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: AppColors.goldDark),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Not a King Power member',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.only(left: 26),
              child: Text(
                'No Carat, e-Purse or privilege on this sale.',
                style: TextStyle(fontSize: 12.5, color: AppColors.mutedText),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: MemberSignUpButton(
                url: signUpUrl,
                onSearchAgain: onSearchAgain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The customer's departing flight: code and route, when it leaves (and
/// how soon), and the pickup point — what decides Collect or Take.
class TripCard extends StatelessWidget {
  final CustomerPerson person;
  final DateTime now;

  const TripCard({super.key, required this.person, required this.now});

  @override
  Widget build(BuildContext context) {
    final title = [
      person.flightCode,
      person.flightRouteDetail,
    ].where((s) => s.isNotEmpty).join(' · ');
    final when = flightWhen(person);
    final departs = departsIn(person, now);
    final departsLine = [
      if (when.isNotEmpty) 'Departs $when',
      if (departs != null) 'in $departs',
    ].join(' · ');

    return TestId(
      MemberIds.trip,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TRIP',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: AppColors.mutedText,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.flight_takeoff,
                  size: 18,
                  color: AppColors.goldDark,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (departsLine.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(departsLine, style: const TextStyle(fontSize: 13)),
            ],
            if (person.flightPickup.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Pickup: ${person.flightPickup}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedText,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Desktop Customer tab, nothing found for [query]: the form beside it is
/// already the register form (as legacy routes a miss), so this says what
/// was searched and offers the other ways on — member sign-up, or search
/// again after a typo.
class CustomerNotFoundPanel extends StatelessWidget {
  final String query;
  final String signUpUrl;
  final VoidCallback onSearchAgain;

  const CustomerNotFoundPanel({
    super.key,
    required this.query,
    required this.signUpUrl,
    required this.onSearchAgain,
  });

  @override
  Widget build(BuildContext context) {
    const muted = TextStyle(fontSize: 13, color: AppColors.mutedText);
    const step = TextStyle(fontSize: 14, fontWeight: FontWeight.w700);

    return TestId(
      MemberIds.notFound,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.person_search_outlined,
                  size: 26,
                  color: AppColors.goldDark,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'No customer found',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text('for "${query.trim()}"', style: muted),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28, color: AppColors.line),
            const Text('1  Register a shopping card', style: step),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.only(left: 18),
              child: Text(
                'Fill in the form — what you searched is filled in already.',
                style: muted,
              ),
            ),
            const SizedBox(height: 16),
            const Text('2  Sign up as King Power member', style: step),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 18),
              child: MemberSignUpButton(
                url: signUpUrl,
                onSearchAgain: onSearchAgain,
              ),
            ),
            const Divider(height: 28, color: AppColors.line),
            const Text(
              'Not right?',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text('· Check the number for typos', style: muted),
            const Text('· Try the shopping card or passport no.', style: muted),
            const SizedBox(height: 10),
            TestId(
              MemberIds.notFoundSearchAgain,
              child: TextButton.icon(
                onPressed: onSearchAgain,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Search again'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.goldDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Handheld Register, opened because nothing was found for [query]: the
/// same choices as [CustomerNotFoundPanel], above the form.
class CustomerNotFoundBanner extends StatelessWidget {
  final String query;
  final String signUpUrl;
  final VoidCallback onSearchAgain;

  const CustomerNotFoundBanner({
    super.key,
    required this.query,
    required this.signUpUrl,
    required this.onSearchAgain,
  });

  @override
  Widget build(BuildContext context) {
    return TestId(
      MemberIds.notFound,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.goldMuted),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.person_search_outlined,
                  size: 20,
                  color: AppColors.goldDark,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No customer for "${query.trim()}"',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.only(left: 28),
              child: Text(
                'Register a shopping card below, or:',
                style: TextStyle(fontSize: 12.5, color: AppColors.mutedText),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                MemberSignUpButton(
                  url: signUpUrl,
                  onSearchAgain: onSearchAgain,
                ),
                TestId(
                  MemberIds.notFoundSearchAgain,
                  child: TextButton.icon(
                    onPressed: onSearchAgain,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Search again'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.goldDark,
                      minimumSize: const Size(0, 44),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
