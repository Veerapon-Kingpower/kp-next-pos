/// Field-for-field port of the legacy `CustomerModel` returned by
/// `Register/GetCustomer` (`api-contracts.md` section 6, op 2). The nested
/// `person.listContact`/`listPrivilege`/`listWalletMember` and `tour` shapes
/// are not documented beyond their field names in the source material, so
/// they are carried as raw JSON rather than guessed at.
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
  final List<Map<String, dynamic>> privileges;
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
    this.flightDate = '',
    this.flightTime = '',
    this.flightRouteDetail = '',
    this.flightPickup = '',
    this.custTypeCode = '',
    this.typeCardMember = '',
    this.gender = 'M',
  });
}
