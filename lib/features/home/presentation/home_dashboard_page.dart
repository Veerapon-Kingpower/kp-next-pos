import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/presentation/desktop/desktop.dart';
import '../../../core/presentation/test_ids.dart';
import '../../../core/presentation/widgets/test_id.dart';
import '../../../core/theme/app_colors.dart';

/// Desktop Home (POS Desktop mockup screen 2): greeting + shift line with
/// KPIs, "Start a sale" scan field, Sale / Registration / Enquiry tiles
/// (F2 / F3 / F4), suspended bills and today's promotions.
///
/// Real: the scan field submits a shopping card / passport / member QR for
/// customer lookup (the mockup's hint), and every tile / hotkey routes to
/// an existing destination. Shift figures, KPIs, suspended bills and
/// promotions have no API yet, so they show "—" or a notice — never
/// placeholder numbers that could be mistaken for real ones.
// TODO(pos-desktop): shift summary, KPIs, suspended bills and promotions
// once their APIs exist.
class HomeDashboardPage extends StatelessWidget {
  final String userName;
  final DateTime now;
  final TextEditingController scanController;
  final ValueChanged<String> onScan;
  final VoidCallback onNewSale;
  final VoidCallback onRegister;
  final VoidCallback onEnquiry;

  const HomeDashboardPage({
    super.key,
    required this.userName,
    required this.now,
    required this.scanController,
    required this.onScan,
    required this.onNewSale,
    required this.onRegister,
    required this.onEnquiry,
  });

  static String greeting(DateTime time, String name) {
    final part = time.hour < 12
        ? 'Good morning'
        : time.hour < 18
        ? 'Good afternoon'
        : 'Good evening';
    final first = name.trim().split(RegExp(r'\s+')).first;
    return first.isEmpty ? part : '$part, $first';
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f2): onNewSale,
        const SingleActivator(LogicalKeyboardKey.f3): onRegister,
        const SingleActivator(LogicalKeyboardKey.f4): onEnquiry,
      },
      child: Focus(
        autofocus: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesktopMetrics.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeroPanel(greeting: greeting(now, userName), userName: userName),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final sideWidth = constraints.maxWidth >= 1300
                      ? 440.0
                      : 340.0;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _StartSalePanel(
                              controller: scanController,
                              onScan: onScan,
                              onNewSale: onNewSale,
                            ),
                            const SizedBox(height: 20),
                            // Equal heights too, whichever subtitle wraps.
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: DesktopActionTile(
                                      id: DesktopIds.homeTileSale,
                                      icon: Icons.shopping_bag_outlined,
                                      title: 'Sale',
                                      subtitle: 'Walk-in, take or collect',
                                      hotkey: 'F2',
                                      onTap: onNewSale,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: DesktopActionTile(
                                      id: DesktopIds.homeTileRegistration,
                                      icon: Icons.badge_outlined,
                                      title: 'Registration',
                                      subtitle: 'New member or shopping card',
                                      hotkey: 'F3',
                                      onTap: onRegister,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: DesktopActionTile(
                                      id: DesktopIds.homeTileEnquiry,
                                      icon: Icons.search,
                                      title: 'Enquiry',
                                      subtitle: 'Find or reprint a bill',
                                      hotkey: 'F4',
                                      onTap: onEnquiry,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      SizedBox(
                        width: sideWidth,
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DesktopPanel(
                              id: DesktopIds.homeSuspendedBills,
                              title: 'Suspended bills',
                              child: Text(
                                'Suspended bills are not available yet on '
                                'this station.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.mutedText,
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            DesktopPanel(
                              id: DesktopIds.homePromotions,
                              title: "Today's promotions",
                              child: Text(
                                'Promotion listing is not available yet — '
                                'promotions still apply at the sale engine.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.mutedText,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  final String greeting;
  final String userName;

  const _HeroPanel({required this.greeting, required this.userName});

  @override
  Widget build(BuildContext context) {
    final parts = userName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final initials = parts.isEmpty
        ? '?'
        : (parts.first[0] + (parts.length > 1 ? parts.last[0] : ''))
              .toUpperCase();
    return DesktopPanel(
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.goldMuted, AppColors.goldDark],
              ),
            ),
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TestId(
                  DesktopIds.homeGreeting,
                  child: Text(greeting, style: DesktopText.heroTitle),
                ),
                const SizedBox(height: 6),
                const TestId(
                  DesktopIds.homeShiftLine,
                  child: Text(
                    'Shift details (opening time, counted float) are not '
                    'available yet.',
                    style: TextStyle(fontSize: 14, color: AppColors.mutedText),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          const DesktopKpi(
            id: DesktopIds.homeBillsKpi,
            label: 'Bills',
            value: '—',
          ),
          const SizedBox(width: 40),
          const DesktopKpi(
            id: DesktopIds.homeNetSalesKpi,
            label: 'Net sales',
            value: '—',
          ),
          const SizedBox(width: 40),
          const DesktopKpi(
            id: DesktopIds.homeAvgBillKpi,
            label: 'Avg bill',
            value: '—',
          ),
        ],
      ),
    );
  }
}

class _StartSalePanel extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onScan;
  final VoidCallback onNewSale;

  const _StartSalePanel({
    required this.controller,
    required this.onScan,
    required this.onNewSale,
  });

  @override
  Widget build(BuildContext context) {
    return DesktopPanel(
      title: 'Start a sale',
      child: Row(
        children: [
          Expanded(
            child: TestId(
              DesktopIds.homeScanField,
              child: Container(
                height: DesktopMetrics.fieldHeight,
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      child: TextField(
                        controller: controller,
                        textInputAction: TextInputAction.search,
                        onSubmitted: onScan,
                        style: const TextStyle(fontSize: 16),
                        decoration: const InputDecoration.collapsed(
                          hintText: 'Scan shopping card, passport or member QR',
                          hintStyle: TextStyle(
                            fontSize: 16,
                            color: AppColors.hintText,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          DesktopButton(
            id: DesktopIds.homeNewSaleButton,
            label: 'New sale',
            hotkey: 'F2',
            height: DesktopMetrics.fieldHeight,
            onPressed: onNewSale,
          ),
        ],
      ),
    );
  }
}
