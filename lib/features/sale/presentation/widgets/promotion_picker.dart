import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/presentation/desktop/desktop.dart';
import '../../../../core/presentation/handheld/handheld.dart';
import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/promotion.dart';
import '../sale_cart_view_model.dart';

/// Promotion picker — ports legacy `PromotionPickerPage`: the branch's
/// promotion master (`GetPromotionList`), re-queried as the cashier types;
/// tapping one picks it. Same frame as the currency picker: a dialog on
/// desktop, a handheld sheet below it. Resolves to the picked promotion, or
/// null when dismissed.
Future<Promotion?> showPromotionPicker(
  BuildContext context, {
  required SaleCartViewModel viewModel,
  String initialQuery = '',
}) {
  final picker = PromotionPicker(
    load: viewModel.searchPromotions,
    initialQuery: initialQuery,
  );
  if (!AppBreakpoints.isWide(context)) {
    return showHandheldSheet<Promotion>(
      context,
      id: DiscountIds.picker,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * 0.7,
        child: picker,
      ),
    );
  }
  return showDialog<Promotion>(
    context: context,
    barrierColor: AppColors.ink.withValues(alpha: 0.55),
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(40),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
        child: TestId(
          DiscountIds.picker,
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 12, 0),
              child: picker,
            ),
          ),
        ),
      ),
    ),
  );
}

class PromotionPicker extends StatefulWidget {
  final Future<List<Promotion>> Function(String query) load;
  final String initialQuery;

  const PromotionPicker({
    super.key,
    required this.load,
    this.initialQuery = '',
  });

  @override
  State<PromotionPicker> createState() => _PromotionPickerState();
}

class _PromotionPickerState extends State<PromotionPicker> {
  late final _query = TextEditingController(text: widget.initialQuery);
  List<Promotion>? _promotions;
  String? _error;
  Timer? _debounce;
  // Drops a slower, older response that lands after a newer query's.
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _error = null;
      _promotions = null;
    });
    try {
      final list = await widget.load(_query.text.trim());
      if (mounted && request == _request) setState(() => _promotions = list);
    } catch (_) {
      if (!mounted || request != _request) return;
      setState(() => _error = 'Can not get promotions list from server');
    }
  }

  // Emptying the search lists the whole master again, at once.
  void _clear() {
    _debounce?.cancel();
    _query.clear();
    _load();
  }

  void _changed(String _) {
    setState(() {}); // shows / hides the clear button
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) _load();
    });
  }

  void _close([Promotion? promotion]) => Navigator.of(context).pop(promotion);

  @override
  Widget build(BuildContext context) {
    final visible = _promotions ?? const <Promotion>[];
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _close,
        const SingleActivator(LogicalKeyboardKey.enter): () {
          if (visible.isNotEmpty) _close(visible.first);
        },
      },
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer_outlined, color: AppColors.goldDark),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Promotions', style: DesktopText.sectionTitle),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: _close,
                icon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 4),
            child: TestId(
              DiscountIds.pickerSearch,
              child: TextField(
                controller: _query,
                autofocus: AppBreakpoints.isWide(context),
                onChanged: _changed,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, size: 18),
                  hintText: 'Search promotion code or name',
                  suffixIcon: _query.text.isEmpty
                      ? null
                      : TestId(
                          DiscountIds.pickerClearButton,
                          child: IconButton(
                            icon: const Icon(Icons.cancel, size: 18),
                            color: AppColors.mutedText,
                            tooltip: 'Clear',
                            onPressed: _clear,
                          ),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(child: _list()),
        ],
      ),
    );
  }

  Widget _list() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    final promotions = _promotions;
    if (promotions == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (promotions.isEmpty) {
      return const Center(
        child: Text(
          'No promotions',
          style: TextStyle(color: AppColors.mutedText),
        ),
      );
    }
    return ListView.builder(
      itemCount: promotions.length,
      itemBuilder: (context, i) {
        final p = promotions[i];
        final value = p.discountAmount > 0
            ? formatAmount(p.discountAmount)
            : p.discountRate > 0
            ? '${_trim(p.discountRate)} %'
            : '';
        return TestId(
          DiscountIds.pickerRow(p.code),
          child: Semantics(
            button: true,
            child: InkWell(
              onTap: () => _close(p),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.fromLTRB(4, 10, 16, 10),
                child: Row(
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 72),
                      child: Text(
                        p.code,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(p.name, style: const TextStyle(fontSize: 14)),
                    ),
                    if (value.isNotEmpty)
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.mutedText,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.circle_outlined,
                      size: 18,
                      color: AppColors.hintText,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}
