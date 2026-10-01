import 'privilege.dart';

/// Field-for-field port of the legacy `CustomerModel` returned by
/// `Register/GetCustomer` (`api-contracts.md` section 6, op 2). The nested
/// `person.listContact`/`listWalletMember` and `tour` shapes are carried as
/// raw JSON (the wallets are read through [CustomerPerson.caratBalance] /
/// [CustomerPerson.ePurseBalance]) — `listPrivilege` is the
/// exception, since legacy's `PrivilegeModel` documents its real shape (see
/// [Privilege]).
class Customer {
  final String action;
  final bool isFound;
  final CustomerPerson person;
  final Map<String, dynamic> tour;
  final String agentCode;
  // Top-level sibling of agentCode in the legacy `CustomerModel` ("Guide").
  final String subAgentCode;
  final bool isMember;
  // Member-card photo URL — a real top-level `CustomerModel` field in
  // legacy (`CustomerModel.ts`), swapped in for the generic `cardImg`
  // placeholder when present (`customer.ts`'s `ionViewWillEnter`). Empty
  // when the customer has no member card image.
  final String pathURLMemberCard;

  const Customer({
    required this.action,
    required this.isFound,
    required this.person,
    required this.tour,
    required this.agentCode,
    this.subAgentCode = '',
    required this.isMember,
    this.pathURLMemberCard = '',
  });
}

class CustomerPerson {
  final String englishName;
  final String passportNo;
  final String nationality;
  final List<Map<String, dynamic>> contacts;
  final List<Privilege> privileges;
  final List<Map<String, dynamic>> walletMembers;
  // Not a direct API field — extracted from `listIdentity` (the entry whose
  // `IdentityType` is `SHOPCARD`), matching legacy's
  // `IdentityTypeEnum.ShoppingCard`-keyed lookup in `customer.ts`.
  final String shoppingCard;
  final String customerTypeCode;
  final String customerTypeDetail;
  // Drives the Registered/Not Registered status in legacy — not `isFound`.
  final bool isActivate;
  final String flightCode;
  // With [flightCode] `OP000`, `OP` marks a take-away (non-international)
  // registration — legacy `setFormCustomerData()` restores Allow take-away
  // from exactly that pair.
  final String airlineCode;
  final String flightDate;
  final String flightTime;
  final String flightRouteDetail;
  final String flightPickup;
  // Not direct API fields — both extracted from `person.singleDiscount`
  // (the entries whose `IdentityType` are `CODE` and `TYPE CARD MEMBER`),
  // matching legacy's `cust_type_code`/`type_card_member` in `customer.ts`.
  // Distinct from `customerTypeCode`/`customerTypeDetail` above: legacy
  // shows *those* in the profile's label/value rows, but shows *these* as
  // an overlay on the member card visual itself — two different fields
  // that happen to share the word "type".
  final String custTypeCode;
  final String typeCardMember;
  // Used to prefill the Register form's Gender picker in edit mode
  // (`customer-form.ts`'s `setFormCustomerData`); defaults to `'M'` to
  // match that same form's untouched-field default.
  final String gender;
  // Raw `listIdentity` entries (`{IdentityType, IdentityValue}`) — kept
  // verbatim, not just scanned for `shoppingCard`/`custTypeCode`/etc., so
  // the Register form can echo the whole list back unmodified on submit
  // when editing (see `provinceCode`/`cityCode` below for why).
  final List<Map<String, dynamic>> listIdentity;
  // Only ever echoed back verbatim on an edit submit, never displayed or
  // user-edited — matches legacy's `addDatatoModel()`: `if (this.
  // shoppingCard != "") { personNew.listIdentity = this.personInfo.
  // listIdentity; personNew.provinceCode = this.personInfo.provinceCode;
  // personNew.cityCode = this.personInfo.cityCode; ... }`. Sent as empty
  // string when there's no existing customer, matching that same default.
  final String provinceCode;
  final String cityCode;
  // Raw `dateOfBirth` (legacy `PersonInfo.dateOfBirth`) — never displayed,
  // only echoed back on submit alongside [provinceCode]/[cityCode].
  final Object? dateOfBirth;
  // Gates "go to Sale" in legacy (`customer.ts`'s `isFastRegister` getter →
  // `checkConditionToSalePage()`'s first guard): a fast-registered card
  // can't be used to start a sale.
  final bool fastRegister;
  // From `listIdentity` (`MID`, `CARDGROUPCODE`, `CARDTYPECODE`) — legacy
  // `customer.ts` hands these to the Sale page, which sends them on
  // `GetOrder`.
  final String memberId;
  final String cardGroupCode;
  final String cardTypeCode;

  const CustomerPerson({
    required this.englishName,
    required this.passportNo,
    required this.nationality,
    required this.contacts,
    required this.privileges,
    required this.walletMembers,
    this.shoppingCard = '',
    this.customerTypeCode = '',
    this.customerTypeDetail = '',
    this.isActivate = false,
    this.flightCode = '',
    this.airlineCode = '',
    this.flightDate = '',
    this.flightTime = '',
    this.flightRouteDetail = '',
    this.flightPickup = '',
    this.custTypeCode = '',
    this.typeCardMember = '',
    this.gender = 'M',
    this.listIdentity = const [],
    this.provinceCode = '',
    this.cityCode = '',
    this.dateOfBirth,
    this.fastRegister = false,
    this.memberId = '',
    this.cardGroupCode = '',
    this.cardTypeCode = '',
  });

  /// A King Power member — legacy `customer.ts` treats a `MID` identity as
  /// one (the Sale page's `isMember`). Only members carry Carat, e-Purse
  /// and privileges.
  bool get isMember => memberId.isNotEmpty;

  /// Carat balance — the `listWalletMember` entry whose `PaymentCode` is
  /// `CARAT` (the `CARAT_WALLET`, legacy `PaymentType.CARAT`). Null when the
  /// customer has no such wallet.
  double? get caratBalance => _walletBalance('CARAT');

  /// e-Purse balance — the member's cash wallet, `PaymentCode` `CASHW`
  /// (`CASH_WALLET`, THB). Null when the customer has no such wallet.
  double? get ePurseBalance => _walletBalance('CASHW');

  /// Carat due to expire soon — the Carat wallet's `NearlyExpiredAmount`
  /// and `NearlyExpiredAt`. [at] is the Bangkok (UTC+7) calendar date: the
  /// API sends the end of that day in UTC (`2029-12-31T16:59:59.999Z`).
  /// Null when nothing is due, the date is missing, or there's no Carat.
  ({double amount, DateTime at})? get caratNearlyExpired {
    final wallet = _wallet('CARAT');
    if (wallet == null) return null;
    final amount = _toDouble(wallet['NearlyExpiredAmount']);
    final at = DateTime.tryParse('${wallet['NearlyExpiredAt'] ?? ''}');
    if (amount == null || amount <= 0 || at == null) return null;
    return (amount: amount, at: at.toUtc().add(const Duration(hours: 7)));
  }

  // Legacy's `WalletMemberModel` keys are PascalCase (`PaymentCode`,
  // `Balance`).
  double? _walletBalance(String paymentCode) {
    final wallet = _wallet(paymentCode);
    return wallet == null ? null : _toDouble(wallet['Balance']);
  }

  Map<String, dynamic>? _wallet(String paymentCode) {
    for (final wallet in walletMembers) {
      if ('${wallet['PaymentCode'] ?? ''}'.toUpperCase() == paymentCode) {
        return wallet;
      }
    }
    return null;
  }

  static double? _toDouble(Object? value) =>
      value is num ? value.toDouble() : double.tryParse('$value');
}
