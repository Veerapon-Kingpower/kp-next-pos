import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/presentation/desktop/desktop.dart';
import '../../../../core/presentation/handheld/handheld.dart';
import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/currency.dart';

/// Currency picker — ports legacy `CurrencyPickerPage`: the branch list
/// from `SaleEngine/GetCurrency`, filtered by code or name, with the
/// order's [current] currency first. A dialog on desktop, a handheld sheet
/// below it. Resolves to the picked code, or null when dismissed.
Future<String?> showCurrencyPicker(
  BuildContext context, {
  required Future<List<Currency>> Function() load,
  required String current,
}) {
  final picker = CurrencyPicker(load: load, current: current);
  if (!AppBreakpoints.isWide(context)) {
    return showHandheldSheet<String>(
      context,
      id: CurrencyIds.picker,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * 0.7,
        child: picker,
      ),
    );
  }
  return showDialog<String>(
    context: context,
    barrierColor: AppColors.ink.withValues(alpha: 0.55),
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(40),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
        child: TestId(
          CurrencyIds.picker,
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

class CurrencyPicker extends StatefulWidget {
  final Future<List<Currency>> Function() load;
  final String current;

  const CurrencyPicker({super.key, required this.load, required this.current});

  @override
  State<CurrencyPicker> createState() => _CurrencyPickerState();
}

class _CurrencyPickerState extends State<CurrencyPicker> {
  final _query = TextEditingController();
  List<Currency>? _all;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final list = [...await widget.load()];
      // Legacy moves the current currency to the top.
      final index = list.indexWhere((c) => c.code == widget.current);
      if (index > 0) list.insert(0, list.removeAt(index));
      if (mounted) setState(() => _all = list);
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _error = e is ApiException
            ? e.messageDesc
            : 'Could not load currencies.',
      );
    }
  }

  List<Currency> get _visible {
    final q = _query.text.trim().toLowerCase();
    final all = _all ?? const <Currency>[];
    if (q.isEmpty) return all;
    return [
      for (final c in all)
        if (c.code.toLowerCase().contains(q) ||
            c.description.toLowerCase().contains(q))
          c,
    ];
  }

  void _close([String? code]) => Navigator.of(context).pop(code);

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _close,
        const SingleActivator(LogicalKeyboardKey.enter): () {
          if (visible.isNotEmpty) _close(visible.first.code);
        },
      },
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.currency_exchange, color: AppColors.goldDark),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Change currency', style: DesktopText.sectionTitle),
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
              CurrencyIds.search,
              child: TextField(
                controller: _query,
                autofocus: AppBreakpoints.isWide(context),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, size: 18),
                  hintText: 'Search code or name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(child: _list(visible)),
        ],
      ),
    );
  }

  Widget _list(List<Currency> visible) {
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
    if (_all == null) return const Center(child: CircularProgressIndicator());
    if (visible.isEmpty) {
      return const Center(
        child: Text(
          'No currency matches.',
          style: TextStyle(color: AppColors.mutedText),
        ),
      );
    }
    return ListView.builder(
      itemCount: visible.length,
      itemBuilder: (context, i) {
        final c = visible[i];
        final selected = c.code == widget.current;
        return TestId(
          CurrencyIds.option(c.code),
          child: Semantics(
            button: true,
            selected: selected,
            child: InkWell(
              onTap: () => _close(c.code),
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                color: selected ? const Color(0xFFFBF8F1) : null,
                padding: const EdgeInsets.fromLTRB(4, 10, 16, 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 56,
                      child: Text(
                        c.code,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        c.symbol.isEmpty
                            ? c.description
                            : '${c.description} (${c.symbol})',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      c.rate.toStringAsFixed(5),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.mutedText,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      selected ? Icons.check_circle : Icons.circle_outlined,
                      size: 18,
                      color: selected ? AppColors.success : AppColors.hintText,
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
}
