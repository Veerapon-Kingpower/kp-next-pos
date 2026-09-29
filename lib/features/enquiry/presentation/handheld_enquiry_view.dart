import 'package:flutter/material.dart';

import '../../../core/presentation/handheld/handheld.dart';
import '../../../core/presentation/test_ids.dart';
import '../../../core/presentation/widgets/test_id.dart';
import '../../../core/theme/app_colors.dart';

/// Handheld Enquiry (mockup screen 10): search bills / claim checks /
/// shopping cards, quick filters, results, Reprint / Refund.
///
/// Search text and filters are local UI state. There is no bill-search API
/// yet (same as the desktop Enquiry stub — see the desktop spec's
/// decision 4), so results show an honest notice instead of sample bills,
/// and Reprint / Refund are inert.
// TODO(pos-handheld): wire to a transaction-search use case and enable
// Reprint / Refund on a selected bill once the APIs exist.
class HandheldEnquiryView extends StatefulWidget {
  const HandheldEnquiryView({super.key});

  @override
  State<HandheldEnquiryView> createState() => _HandheldEnquiryViewState();
}

enum _Filter {
  today(EnquiryIds.filterToday, 'Today'),
  mine(EnquiryIds.filterMine, 'Mine'),
  notPicked(EnquiryIds.filterNotPicked, 'Not picked'),
  refunded(EnquiryIds.filterRefunded, 'Refunded');

  final String id;
  final String label;

  const _Filter(this.id, this.label);
}

class _HandheldEnquiryViewState extends State<HandheldEnquiryView> {
  final _query = TextEditingController();
  final Set<_Filter> _filters = {_Filter.today};
  String? _searched;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ColoredBox(
          color: AppColors.ink,
          child: SafeArea(
            bottom: false,
            child: HandheldContentWidth(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Enquiry',
                      style: HandheldText.title.copyWith(
                        fontSize: 17,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Bills, claim checks & refunds',
                      style: HandheldText.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ScanField(
                      id: EnquiryIds.searchField,
                      controller: _query,
                      hintText: 'Bill no., claim check or card',
                      onDark: true,
                      onSubmitted: (value) =>
                          setState(() => _searched = value.trim()),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final filter in _Filter.values)
                          _FilterChip(
                            filter: filter,
                            selected: _filters.contains(filter),
                            onTap: () => setState(() {
                              if (!_filters.remove(filter)) {
                                _filters.add(filter);
                              }
                            }),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: HandheldContentWidth(
            child: ListView(
              padding: const EdgeInsets.all(HandheldMetrics.pagePadding),
              children: [
                TestId(
                  EnquiryIds.resultsNotice,
                  child: HandheldSection(
                    title: 'Results',
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _searched == null || _searched!.isEmpty
                              ? 'Search by bill number, claim check or '
                                    'shopping card.'
                              : 'Bill search for "$_searched" is not '
                                    'available yet on this device.',
                          style: HandheldText.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const HandheldActionBar(
          primary: HandheldPrimaryButton(
            id: EnquiryIds.reprintButton,
            label: 'Reprint',
            icon: Icons.print_outlined,
          ),
          secondary: HandheldSecondaryButton(
            id: EnquiryIds.refundButton,
            label: 'Refund',
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final _Filter filter;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.filter,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TestId(
      filter.id,
      child: Semantics(
        button: true,
        selected: selected,
        child: Material(
          color: selected ? AppColors.gold : Colors.transparent,
          shape: StadiumBorder(
            side: selected
                ? BorderSide.none
                : BorderSide(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Text(
                filter.label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected
                      ? AppColors.ink
                      : Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
