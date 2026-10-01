import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/presentation/desktop/desktop.dart';
import '../../../core/presentation/test_ids.dart';
import '../../../core/presentation/widgets/test_id.dart';
import '../../../core/theme/app_colors.dart';

/// Where a Home customer lookup stands: Search → Register → Sale.
enum HomeLookupStep { search, register, sale }

/// Desktop Home in lookup mode ("Find customer to start a sale"): the scan
/// panel gains a Search → Register → Sale stepper and [body] (the result,
/// or its loading / error state) replaces the dashboard below it. F2 /
/// F3 / Esc act on the result.
class HomeLookup {
  final HomeLookupStep step;
  final Widget body;
  final VoidCallback onClear;

  /// F2 — only once the customer can start a sale (registered).
  final VoidCallback? onStartSale;

  /// F3 — register the found (unregistered) customer.
  final VoidCallback? onRegister;

  const HomeLookup({
    required this.step,
    required this.body,
    required this.onClear,
    this.onStartSale,
    this.onRegister,
  });
}

/// Desktop Home ("Find customer to start a sale"): the scan panel with its
/// Search → Register → Sale stepper, and below it either the idle "Who is
/// the customer?" panel or — once a lookup runs — [lookup]'s body (the
/// result, or its loading / error state). F2 starts the sale for a
/// registered result, F3 registers, F4 opens Enquiry, Esc clears.
class HomeDashboardPage extends StatelessWidget {
  final TextEditingController scanController;
  final ValueChanged<String> onScan;
  final VoidCallback onRegister;
  final VoidCallback onEnquiry;

  /// Non-null while a customer lookup is shown in place of the idle panel.
  final HomeLookup? lookup;

  const HomeDashboardPage({
    super.key,
    required this.scanController,
    required this.onScan,
    required this.onRegister,
    required this.onEnquiry,
    this.lookup,
  });

  @override
  Widget build(BuildContext context) {
    final lookup = this.lookup;
    return CallbackShortcuts(
      bindings: {
        if (lookup?.onStartSale != null)
          const SingleActivator(LogicalKeyboardKey.f2): lookup!.onStartSale!,
        const SingleActivator(LogicalKeyboardKey.f3):
            lookup?.onRegister ?? onRegister,
        const SingleActivator(LogicalKeyboardKey.f4): onEnquiry,
        const SingleActivator(LogicalKeyboardKey.escape):
            lookup?.onClear ?? scanController.clear,
      },
      // The scan field below takes focus; the shortcuts above catch keys
      // bubbling up from it.
      child: Focus(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FindCustomerPanel(
                controller: scanController,
                step: lookup?.step ?? HomeLookupStep.search,
                onScan: onScan,
                onClear: lookup?.onClear ?? scanController.clear,
              ),
              const SizedBox(height: 14),
              if (lookup != null)
                TestId(DesktopIds.homeLookup, child: lookup.body)
              else
                _IdlePanel(onEnquiry: onEnquiry),
            ],
          ),
        ),
      ),
    );
  }
}

/// Before any search: "Who is the customer?" with the identifiers the
/// lookup takes, and the result's right column in its empty state —
/// checks "shown after search", Start sale locked, Enquiry available.
class _IdlePanel extends StatelessWidget {
  final VoidCallback onEnquiry;

  const _IdlePanel({required this.onEnquiry});

  @override
  Widget build(BuildContext context) {
    return TestId(
      DesktopIds.homeIdle,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(DesktopMetrics.panelRadius),
          border: Border.all(color: AppColors.line),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 380),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(22),
                    child: _WhoIsTheCustomer(),
                  ),
                ),
                Container(
                  width: 300,
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(left: BorderSide(color: AppColors.line)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'REGISTRATION CHECKS',
                        style: DesktopText.fieldLabel,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Shown after search.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.mutedText,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: 16),
                      const DesktopButton(
                        id: ProfileIds.goToSaleButton,
                        label: 'Start sale',
                        icon: Icons.lock_outline,
                        height: 58,
                      ),
                      const SizedBox(height: 10),
                      DesktopButton(
                        id: DesktopIds.homeEnquiryButton,
                        label: 'Enquiry',
                        icon: Icons.search,
                        hotkey: 'F4',
                        secondary: true,
                        onPressed: onEnquiry,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WhoIsTheCustomer extends StatelessWidget {
  const _WhoIsTheCustomer();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: AppColors.cream,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.qr_code_scanner,
            size: 30,
            color: AppColors.goldDark,
          ),
        ),
        const SizedBox(height: 14),
        const Text('Who is the customer?', style: DesktopText.heroTitle),
        const SizedBox(height: 6),
        const Text(
          'Scan or type any one of these. The system checks registration '
          'before a sale can start.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),
        // `Register/GetCustomer` takes the value as-is: a shopping card or
        // passport (legacy's own search) or an ID card number.
        const IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _IdentifierCard(
                  icon: Icons.credit_card,
                  label: 'Shopping card',
                  example: 'e.g. 8823-4419-0027',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _IdentifierCard(
                  icon: Icons.menu_book_outlined,
                  label: 'Passport',
                  example: 'e.g. CB912447',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _IdentifierCard(
                  icon: Icons.badge_outlined,
                  label: 'ID card',
                  example: 'e.g. 1101700000000',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IdentifierCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String example;

  const _IdentifierCard({
    required this.icon,
    required this.label,
    required this.example,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppColors.goldDark),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            example,
            style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }
}

/// "Find customer to start a sale": the lookup's scan field (kept filled
/// with the query, × clears the lookup), Search, and the stepper.
class _FindCustomerPanel extends StatelessWidget {
  final TextEditingController controller;
  final HomeLookupStep step;
  final ValueChanged<String> onScan;
  final VoidCallback onClear;

  const _FindCustomerPanel({
    required this.controller,
    required this.step,
    required this.onScan,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return DesktopPanel(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Find customer to start a sale',
                  style: DesktopText.sectionTitle,
                ),
              ),
              _LookupStepper(step: step),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TestId(
                  DesktopIds.homeScanField,
                  child: Container(
                    height: DesktopMetrics.fieldHeight,
                    padding: const EdgeInsets.only(left: 16),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.goldMuted, width: 2),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.qr_code_scanner,
                          size: 20,
                          color: AppColors.goldDark,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TestId(
                            HomeIds.dashboardScanInput,
                            child: TextField(
                              controller: controller,
                              // Ready for a scan as soon as Home shows, and
                              // after each one (a TextField otherwise drops
                              // focus on submit).
                              autofocus: true,
                              onEditingComplete: () {},
                              textInputAction: TextInputAction.search,
                              onSubmitted: onScan,
                              style: const TextStyle(fontSize: 20),
                              decoration: const InputDecoration.collapsed(
                                hintText:
                                    'Scan or type shopping card, passport or ID card number',
                                hintStyle: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.hintText,
                                ),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(
                            Icons.close,
                            size: 18,
                            color: AppColors.mutedText,
                          ),
                          onPressed: onClear,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              IntrinsicWidth(
                child: DesktopButton(
                  id: DesktopIds.homeSearchButton,
                  label: 'Search',
                  icon: Icons.search,
                  hotkey: 'ENTER',
                  height: DesktopMetrics.fieldHeight,
                  onPressed: () => onScan(controller.text),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Search → Register → Sale. A registered customer skips Register (struck
/// through) and lands on Sale; an unregistered one stops at Register.
class _LookupStepper extends StatelessWidget {
  final HomeLookupStep step;

  const _LookupStepper({required this.step});

  @override
  Widget build(BuildContext context) {
    const labels = ['Search', 'Register', 'Sale'];
    final current = step.index;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0)
            Container(
              width: 36,
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              color: AppColors.line,
            ),
          TestId(
            DesktopIds.homeStep(i),
            child: Semantics(
              selected: i == current,
              child: _Step(
                number: i + 1,
                label: labels[i],
                done: i < current && !(i == 1 && step == HomeLookupStep.sale),
                skipped: i == 1 && step == HomeLookupStep.sale,
                current: i == current,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final int number;
  final String label;
  final bool done;
  final bool skipped;
  final bool current;

  const _Step({
    required this.number,
    required this.label,
    required this.done,
    required this.skipped,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final Widget dot;
    if (done) {
      dot = const CircleAvatar(
        radius: 11,
        backgroundColor: AppColors.online,
        child: Icon(Icons.check, size: 14, color: Colors.white),
      );
    } else {
      dot = Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: current ? AppColors.goldDark : AppColors.surface,
          border: current ? null : Border.all(color: AppColors.hintText),
        ),
        child: Text(
          '$number',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: current ? Colors.white : AppColors.mutedText,
          ),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot,
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: current ? FontWeight.w700 : FontWeight.w400,
            color: skipped ? AppColors.hintText : AppColors.textPrimary,
            decoration: skipped ? TextDecoration.lineThrough : null,
          ),
        ),
      ],
    );
  }
}
