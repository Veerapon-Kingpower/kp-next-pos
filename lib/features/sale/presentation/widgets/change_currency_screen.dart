import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/presentation/desktop/desktop.dart';
import '../../../../core/presentation/handheld/handheld.dart'
    show formatAmount, formatBaht, showHandheldSheet;
import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/currency.dart';
import '../../domain/entities/exchange_quote.dart';

typedef ExchangeChange =
    Future<ExchangeQuote> Function({
      required String currencyCode,
      required double currencyAmount,
      required double changeInBaht,
      required bool isChangeButton,
    });

/// The CHANGE screen — ports legacy `ChangePage`: change due in baht, handed
/// back partly or wholly in another currency. Picking a currency asks the
/// sale engine (`SaleEngine/ExchangeCurrency`) how much of it covers the
/// change; typing an amount re-quotes what baht is still owed.
///
/// Save is inert: legacy saves with `ActionOrderPayment` `edit_exchange`
/// against the order's recorded cash payment, and this app does not record
/// cash tenders yet — the quote is real, nothing is written.
// TODO(pos-desktop): Save via ActionOrderPayment `edit_exchange` once cash
// tenders are recorded on the order (openspec 5.1).
Future<void> showChangeCurrencyScreen(
  BuildContext context, {
  required double changeInBaht,
  required Future<List<Currency>> Function() loadCurrencies,
  required ExchangeChange exchange,
  String initialCurrency = 'THB',
}) {
  // Handheld: a bottom sheet on phones, a dialog on tablets (legacy's
  // full-screen modal on the Sunmi).
  if (!AppBreakpoints.isWide(context)) {
    return showHandheldSheet<void>(
      context,
      id: CurrencyIds.changeScreen,
      builder: (_) => _ChangeCurrencyScreen(
        changeInBaht: changeInBaht,
        loadCurrencies: loadCurrencies,
        exchange: exchange,
        initialCurrency: initialCurrency,
        framed: false,
      ),
    );
  }
  return showDialog<void>(
    context: context,
    barrierColor: AppColors.ink.withValues(alpha: 0.55),
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(40),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: _ChangeCurrencyScreen(
          changeInBaht: changeInBaht,
          loadCurrencies: loadCurrencies,
          exchange: exchange,
          initialCurrency: initialCurrency,
          framed: true,
        ),
      ),
    ),
  );
}

class _ChangeCurrencyScreen extends StatefulWidget {
  final double changeInBaht;
  final Future<List<Currency>> Function() loadCurrencies;
  final ExchangeChange exchange;
  final String initialCurrency;

  /// Desktop dialog: own surface and id. Handheld sheet: bare content.
  final bool framed;

  const _ChangeCurrencyScreen({
    required this.changeInBaht,
    required this.loadCurrencies,
    required this.exchange,
    required this.initialCurrency,
    required this.framed,
  });

  @override
  State<_ChangeCurrencyScreen> createState() => _ChangeCurrencyScreenState();
}

class _ChangeCurrencyScreenState extends State<_ChangeCurrencyScreen> {
  final _amount = TextEditingController();
  Timer? _debounce;
  int _request = 0;
  List<Currency> _currencies = const [];
  late String _currency = widget.initialCurrency;
  ExchangeQuote? _quote;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
    // Legacy opens on the payment currency with the whole change quoted.
    _requote(isChangeButton: true, amount: widget.changeInBaht);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _loadCurrencies() async {
    try {
      final list = await widget.loadCurrencies();
      if (mounted) setState(() => _currencies = list);
    } catch (_) {
      // The picker row just stays empty; the current quote still stands.
    }
  }

  void _pick(String code) {
    setState(() => _currency = code);
    // Legacy `onExchangeCurrency(code, true)`: re-quote the current amount.
    _requote(
      isChangeButton: true,
      amount:
          double.tryParse(_amount.text.replaceAll(',', '')) ??
          widget.changeInBaht,
    );
  }

  void _onAmountChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final amount = double.tryParse(text.replaceAll(',', ''));
      if (amount != null) _requote(isChangeButton: false, amount: amount);
    });
  }

  Future<void> _requote({
    required bool isChangeButton,
    required double amount,
  }) async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final quote = await widget.exchange(
        currencyCode: _currency,
        currencyAmount: amount,
        changeInBaht: widget.changeInBaht,
        isChangeButton: isChangeButton,
      );
      if (!mounted || request != _request) return;
      setState(() {
        _quote = quote;
        _loading = false;
      });
      final text = quote.currencyAmount.toStringAsFixed(2);
      // Only a picked currency rewrites what the cashier is typing.
      if (isChangeButton && _amount.text != text) _amount.text = text;
    } catch (e) {
      if (!mounted || request != _request) return;
      setState(() {
        _loading = false;
        _error = e is ApiException
            ? e.messageDesc
            : 'Could not exchange the change amount.';
      });
    }
  }

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final quote = _quote;
    Widget row(String id, String label, String value, {bool strong = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.mutedText,
                  ),
                ),
              ),
              TestId(
                id,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: strong ? 22 : 17,
                    fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        );

    final body = SingleChildScrollView(
      padding: widget.framed
          ? const EdgeInsets.fromLTRB(28, 18, 20, 24)
          : EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.currency_exchange, color: AppColors.goldDark),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Change', style: DesktopText.sectionTitle),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: _close,
                icon: const Icon(Icons.close, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_currencies.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in _currencies)
                  TestId(
                    CurrencyIds.changeCurrency(c.code),
                    child: ChoiceChip(
                      label: Text(
                        c.symbol.isEmpty ? c.code : '${c.code} ${c.symbol}',
                      ),
                      selected: c.code == _currency,
                      selectedColor: AppColors.cream,
                      onSelected: (_) => _pick(c.code),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 12),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          row(
            CurrencyIds.changeRate,
            'Currency rate',
            quote == null ? '—' : quote.rate.toStringAsFixed(3),
          ),
          row(
            CurrencyIds.changeAmountThb,
            'Change amount (THB)',
            formatAmount(widget.changeInBaht),
          ),
          const SizedBox(height: 10),
          Text('CURRENCY CHANGE ($_currency)', style: DesktopText.fieldLabel),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TestId(
                  CurrencyIds.changeCurrencyField,
                  child: TextField(
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: _onAmountChanged,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      suffixText: _currency,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TestId(
                  CurrencyIds.changeCurrencyThb,
                  child: Text(
                    quote == null
                        ? '—'
                        : '= ${formatBaht(quote.currencyAmountInBaht)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.mutedText,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          row(
            CurrencyIds.changeLocal,
            'Local change (THB)',
            quote == null ? '—' : formatAmount(quote.localChange),
            strong: true,
          ),
          if (_error != null)
            TestId(
              CurrencyIds.changeError,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Text(
            'Saving the exchange needs a recorded cash tender — not '
            'available yet on this station. Hand the change back as '
            'quoted above.',
            style: TextStyle(fontSize: 12.5, color: AppColors.mutedText),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(
                child: DesktopButton(
                  id: CurrencyIds.changeSaveButton,
                  label: 'Save',
                  icon: Icons.check,
                  height: 52,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DesktopButton(
                  id: CurrencyIds.changeCancelButton,
                  label: 'Cancel',
                  secondary: true,
                  height: 52,
                  onPressed: _close,
                ),
              ),
            ],
          ),
        ],
      ),
    );
    final keyboard = CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _close},
      child: Focus(autofocus: true, child: body),
    );
    // The handheld sheet already carries the id and the surface.
    if (!widget.framed) return keyboard;
    return TestId(
      CurrencyIds.changeScreen,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: keyboard,
      ),
    );
  }
}
