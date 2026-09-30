import 'package:flutter/widgets.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/line_discount.dart';
import '../../domain/entities/promotion.dart';
import '../sale_cart_view_model.dart';

/// The Discount page's form state — legacy `DiscountPage`'s
/// `discountModel` with its `isCanEditPercent` / `isCanEditAmount` rules.
/// A discount always comes from a promotion (legacy `canSaveDiscount`
/// needs its name); the promotion fills Per. or THB, editable only when it
/// allows overwriting. Shared by the desktop overlay and handheld sheet.
class LineDiscountForm extends ChangeNotifier {
  final code = TextEditingController();
  final percent = TextEditingController();
  final amount = TextEditingController();

  String description = '';
  bool isPercent = false;
  bool canEditPercent = true;
  bool canEditAmount = true;

  /// The applied discount being edited (legacy `isEditMode`), if any.
  LineDiscount? editing;

  // The mode a promotion fixed: true = rate (Per.), false = baht (THB).
  bool? _promotionMode;

  double get _percent => double.tryParse(percent.text) ?? 0;
  double get _amount => double.tryParse(amount.text) ?? 0;

  /// Legacy `canSaveDiscount`.
  bool get canSave =>
      description.isNotEmpty && (isPercent ? _percent > 0 : _amount > 0);

  LineDiscountDraft get draft => LineDiscountDraft(
    code: code.text.trim(),
    description: description,
    isPercent: isPercent,
    percent: _percent,
    amount: _amount,
    editing: editing,
  );

  /// Legacy `clearModel()` / `cleartext('code')`.
  void reset() {
    code.clear();
    percent.clear();
    amount.clear();
    description = '';
    isPercent = false;
    canEditPercent = true;
    canEditAmount = true;
    editing = null;
    _promotionMode = null;
    notifyListeners();
  }

  /// A promotion from the picker or `GetPromotion`: a baht promotion fills
  /// THB, a rate fills Per.; the other field is locked.
  void applyPromotion(Promotion promotion, {String? code}) {
    this.code.text = code ?? promotion.code;
    description = promotion.name;
    if (promotion.discountAmount > 0) {
      isPercent = false;
      _promotionMode = false;
      percent.text = '';
      amount.text = _format(promotion.discountAmount);
      canEditAmount = promotion.allowOverwrite;
      canEditPercent = false;
    } else if (promotion.discountRate > 0) {
      isPercent = true;
      _promotionMode = true;
      percent.text = _format(promotion.discountRate);
      amount.text = '';
      canEditPercent = promotion.allowOverwrite;
      canEditAmount = false;
    }
    notifyListeners();
  }

  /// Legacy `onBlurPromotionCode()` → `getPromotion()`. Returns the error
  /// to show (and clears the code, as legacy's OK does), or null.
  Future<String?> lookUpCode(SaleCartViewModel viewModel) async {
    final typed = code.text.trim();
    if (typed.isEmpty) return null;
    try {
      final promotion = await viewModel.findPromotion(typed);
      if (promotion != null) {
        applyPromotion(promotion, code: typed);
        return null;
      }
      _clearPromotion();
      return 'Promotion code : $typed not found.';
    } on ApiException catch (e) {
      _clearPromotion();
      return e.messageCode == null
          ? e.messageDesc
          : 'Error Code: ${e.messageCode}\n${e.messageDesc}';
    }
  }

  void _clearPromotion() {
    code.clear();
    percent.clear();
    amount.clear();
    _promotionMode = null;
    canEditPercent = true;
    canEditAmount = true;
    notifyListeners();
  }

  /// Tapping Per. ([percent] true) or THB: that one becomes the discount and
  /// the other's value is cleared, so only one is ever sent. A mode a
  /// promotion fixed (baht vs rate) can't be switched.
  void select({required bool percent}) {
    final fixed = _promotionMode;
    if (fixed != null && fixed != percent) return;
    if (fixed == null) {
      canEditPercent = true;
      canEditAmount = true;
    }
    isPercent = percent;
    (percent ? amount : this.percent).clear();
    notifyListeners();
  }

  /// Legacy `autoMode(0, …)`: a percent (or an emptied field) makes it a
  /// percent discount; zero switches to baht.
  void percentChanged(String value) {
    final entered = double.tryParse(value);
    final asPercent = entered == null || entered > 0;
    isPercent = asPercent;
    canEditPercent = asPercent;
    canEditAmount = !asPercent;
    notifyListeners();
  }

  /// Legacy `autoMode(1, …)`, the mirror of [percentChanged].
  void amountChanged(String value) {
    final entered = double.tryParse(value);
    final asAmount = entered == null || entered > 0;
    isPercent = !asAmount;
    canEditPercent = !asAmount;
    canEditAmount = asAmount;
    notifyListeners();
  }

  /// Legacy `edit()`: only an overwritable `Privilege` discount; tapping the
  /// one being edited again leaves edit mode. Returns the refusal, if any.
  String? toggleEdit(LineDiscount discount) {
    if (!discount.isEditable) return 'Promotion not allow to edit discount';
    if (editing?.guid == discount.guid) {
      reset();
      return null;
    }
    reset();
    editing = discount;
    code.text = discount.code;
    description = discount.description;
    isPercent = discount.isPercent;
    percent.text = discount.percent == 0 ? '' : _format(discount.percent);
    amount.text = discount.amount == 0 ? '' : _format(discount.amount);
    notifyListeners();
    return null;
  }

  static String _format(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toString();

  @override
  void dispose() {
    code.dispose();
    percent.dispose();
    amount.dispose();
    super.dispose();
  }
}
