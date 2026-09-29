import 'package:kp_pos/features/auth/domain/entities/authorized_action.dart';
import 'package:kp_pos/features/auth/domain/entities/user_session.dart';
import 'package:kp_pos/features/sale/domain/entities/cart.dart';
import 'package:kp_pos/features/sale/domain/entities/cart_item.dart';
import 'package:kp_pos/features/sale/domain/entities/currency.dart';
import 'package:kp_pos/features/sale/domain/entities/exchange_quote.dart';

/// A cashier holding legacy's `actCurrency` (ChangeCurrency) permission.
const currencySession = UserSession(
  sessionKey: 'abc123',
  branchNo: '03',
  userCode: 'U001',
  userName: 'Test User',
  authorizedActions: [
    AuthorizedAction(
      moduleCode: 'SALE',
      authCode: 'actCurrency',
      action: 'Currency',
    ),
  ],
);

const branchCurrencies = [
  Currency(code: 'THB', description: 'Thai Baht', rate: 1),
  Currency(code: 'USD', description: 'US Dollar', rate: 35.5, symbol: r'$'),
  Currency(code: 'EUR', description: 'Euro', rate: 38.2),
];

/// The sample order after the sale engine repriced it in USD.
const usdCart = Cart(
  guid: 'order-1',
  isCheckOut: false,
  items: [
    CartItem(
      row: '1',
      articleCode: '3145891255607',
      articleName: 'CHANEL N°5 EAU DE PARFUM 100ML',
      quantity: 1,
      unitPrice: 166.2,
      lineTotal: 166.2,
    ),
  ],
  billing: CartBilling(
    currencyCode: 'USD',
    currencyDescription: 'US Dollar',
    currencyRate: 35.5,
    total: 166.2,
    grand: 166.2,
    discount: 0,
    cashD: 0,
    netPay: 166.2,
    netPayBase: 5900,
  ),
);

/// A sale engine that converts at [branchCurrencies]' rates, the way
/// legacy's `ChangePage` reads the result.
ExchangeQuote quoteAtBranchRates(String code, double amount, double change) {
  final rate = branchCurrencies.firstWhere((c) => c.code == code).rate;
  final inBaht = amount * rate;
  return ExchangeQuote(
    currencyCode: code,
    rate: rate,
    currencyAmount: amount,
    currencyAmountInBaht: inBaht,
    localChange: change - inBaht,
  );
}
