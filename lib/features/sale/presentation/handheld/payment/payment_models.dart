import 'package:flutter/material.dart';

/// Presentation-only payment models for the handheld Payment / Wallet
/// screens (mockup screens 6, 18–20). There is no payment domain yet — no
/// EDC, 2C2P or sale-completion API — so these describe what the screens
/// display, not persisted state.
// TODO(pos-handheld): replace with domain entities once a payment API exists.
enum TenderMethod {
  card('Card', Icons.credit_card),
  cash('Cash', Icons.payments_outlined),
  unionPay('UnionPay', Icons.credit_card_outlined),
  wallet('Wallet', Icons.qr_code_2),
  ePurse('e-Purse', Icons.card_giftcard),
  voucher('Voucher', Icons.receipt_long_outlined);

  final String label;
  final IconData icon;

  const TenderMethod(this.label, this.icon);
}

enum TenderStatus { pending, approved, declined, voided }

class Tender {
  final TenderMethod method;
  final String title;
  final double amount;
  final TenderStatus status;
  final String? reference;
  final WalletProvider? walletProvider;

  const Tender({
    required this.method,
    required this.title,
    required this.amount,
    required this.status,
    this.reference,
    this.walletProvider,
  });

  bool get isSettled => status == TenderStatus.approved;

  /// Wallet QR tenders are voided here; card tenders on the EDC.
  bool get isVoidableHere =>
      method == TenderMethod.wallet && status == TenderStatus.approved;
}

double tenderedTotal(Iterable<Tender> tenders) => tenders
    .where((t) => t.isSettled)
    .fold<double>(0, (sum, t) => sum + t.amount);

enum WalletProvider {
  alipay('Alipay'),
  wechatPay('WeChat Pay'),
  unknown('Unknown wallet');

  final String label;

  const WalletProvider(this.label);
}

/// Identifies the wallet from a customer's payment barcode (B scan C).
///
/// Published formats: Alipay codes are 16–24 digits starting 25–30;
/// WeChat Pay codes are 18 digits starting 10–15. Anything else — an EAN
/// scanned by mistake, a too-short code — is [WalletProvider.unknown].
WalletProvider detectWalletProvider(String rawCode) {
  final code = rawCode.replaceAll(RegExp(r'\s'), '');
  if (!RegExp(r'^\d+$').hasMatch(code)) return WalletProvider.unknown;
  final prefix = int.parse(code.substring(0, 2));
  if (code.length == 18 && prefix >= 10 && prefix <= 15) {
    return WalletProvider.wechatPay;
  }
  if (code.length >= 16 && code.length <= 24 && prefix >= 25 && prefix <= 30) {
    return WalletProvider.alipay;
  }
  return WalletProvider.unknown;
}

/// `28 •••• 4417` — enough for the cashier to confirm the scan without
/// showing the full one-time code.
String maskPaymentCode(String rawCode) {
  final code = rawCode.replaceAll(RegExp(r'\s'), '');
  if (code.length < 8) return code;
  return '${code.substring(0, 2)} •••• ${code.substring(code.length - 4)}';
}
