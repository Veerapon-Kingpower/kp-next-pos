import 'package:flutter/material.dart';

import '../../../core/presentation/desktop/desktop.dart';
import '../../../core/presentation/test_ids.dart';
import '../../../core/presentation/widgets/desktop_data_table.dart';
import '../../../core/presentation/widgets/test_id.dart';
import '../../../core/theme/app_colors.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Desktop Enquiry — transaction search (POS Desktop mockup screen 10):
/// filter row (shopping card, date, status), results table, selected-bill
/// detail panel, Reprint / Refund / Open bill.
///
/// Presentation-only per the desktop spec's decision 4: filters are local
/// UI state and there is no transaction-search API yet, so the table stays
/// empty with a notice (no placeholder bills) and the bill actions are
/// inert. Handheld widths use `HandheldEnquiryView` instead.
// TODO(pos-desktop): transaction search API (openspec task 6.3) — fill the
// table, drive the detail panel from the selected row (↑↓ / Enter), and
// enable Reprint / Refund / Open bill.
class EnquiryPage extends StatefulWidget {
  final DateTime? today;

  const EnquiryPage({super.key, this.today});

  @override
  State<EnquiryPage> createState() => _EnquiryPageState();
}

class _EnquiryPageState extends State<EnquiryPage> {
  static const _statuses = [
    'All',
    'Complete',
    'Not picked',
    'In transit',
    'Refunded',
    'Void',
  ];

  final _query = TextEditingController();
  String _status = _statuses.first;
  String? _searched;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _search() => setState(() => _searched = _query.text.trim());

  @override
  Widget build(BuildContext context) {
    final today = widget.today ?? DateTime.now();
    final date = '${today.day} ${_months[today.month - 1]} ${today.year}';
    final notice = _searched == null || _searched!.isEmpty
        ? 'Search by shopping card to find a bill.'
        : 'Bill search for "$_searched" is not available yet on this '
              'station.';

    return Padding(
      padding: const EdgeInsets.all(DesktopMetrics.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Bills, claim checks and refunds',
                  style: TextStyle(fontSize: 13.5, color: AppColors.mutedText),
                ),
              ),
              const DesktopButton(
                id: EnquiryIds.reprintButton,
                label: 'Reprint',
                icon: Icons.print_outlined,
                secondary: true,
              ),
              const SizedBox(width: 10),
              const DesktopButton(
                id: EnquiryIds.refundButton,
                label: 'Refund',
                icon: Icons.undo,
                secondary: true,
              ),
              const SizedBox(width: 10),
              const DesktopButton(
                id: DesktopIds.enquiryOpenBillButton,
                label: 'Open bill',
                icon: Icons.receipt_long_outlined,
                hotkey: 'ENTER',
              ),
            ],
          ),
          const SizedBox(height: 16),
          DesktopPanel(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _Labeled(
                    label: 'Shopping card',
                    child: TestId(
                      EnquiryIds.searchField,
                      child: TextField(
                        controller: _query,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _search(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: _boxDecoration(
                          hint: 'Shopping card or bill no.',
                          icon: Icons.search,
                          emphasised: true,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(
                  width: 200,
                  child: _Labeled(
                    label: 'Date range',
                    // TODO(pos-desktop): date-range picker with the search API.
                    child: TestId(
                      DesktopIds.enquiryDateRange,
                      child: InputDecorator(
                        decoration: _boxDecoration(icon: Icons.event),
                        child: Text(
                          date,
                          style: const TextStyle(fontSize: 14.5),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(
                  width: 180,
                  child: _Labeled(
                    label: 'Status',
                    child: TestId(
                      DesktopIds.enquiryStatus,
                      child: DropdownButtonFormField<String>(
                        initialValue: _status,
                        isExpanded: true,
                        decoration: _boxDecoration(),
                        items: [
                          for (final s in _statuses)
                            DropdownMenuItem(value: s, child: Text(s)),
                        ],
                        onChanged: (v) =>
                            setState(() => _status = v ?? _status),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                DesktopButton(
                  id: DesktopIds.enquirySearchButton,
                  label: 'Search',
                  height: DesktopMetrics.fieldHeight,
                  onPressed: _search,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final detailWidth = constraints.maxWidth >= 1300
                    ? 460.0
                    : 340.0;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TestId(
                        DesktopIds.enquiryTable,
                        child: SingleChildScrollView(
                          child: DesktopDataTable(
                            columns: const [
                              DesktopDataColumn(label: 'Shopping card'),
                              DesktopDataColumn(label: 'Time'),
                              DesktopDataColumn(label: 'Customer'),
                              DesktopDataColumn(
                                label: 'Lines',
                                align: TextAlign.right,
                              ),
                              DesktopDataColumn(
                                label: 'Net paid',
                                align: TextAlign.right,
                              ),
                              DesktopDataColumn(label: 'Status'),
                            ],
                            rows: const [],
                            keepHeaderWhenEmpty: true,
                            emptyPlaceholder: TestId(
                              EnquiryIds.resultsNotice,
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  notice,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: AppColors.mutedText,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    SizedBox(
                      width: detailWidth,
                      child: const DesktopPanel(
                        id: DesktopIds.enquiryDetail,
                        title: 'Bill',
                        child: Text(
                          'Select a bill to see its order type, totals, '
                          'tenders and claim check.',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static InputDecoration _boxDecoration({
    String? hint,
    IconData? icon,
    bool emphasised = false,
  }) {
    OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide(color: c, width: w),
    );
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, color: AppColors.goldDark),
      filled: true,
      fillColor: emphasised ? AppColors.surface : const Color(0xFFF7F9FB),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      enabledBorder: border(
        emphasised ? AppColors.goldMuted : const Color(0xFFD8DDE5),
        emphasised ? 2 : 1,
      ),
      focusedBorder: border(AppColors.goldMuted, 2),
    );
  }
}

class _Labeled extends StatelessWidget {
  final String label;
  final Widget child;

  const _Labeled({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(), style: DesktopText.fieldLabel),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
