import '../../domain/entities/customer.dart';
import 'privilege_model.dart';

class CustomerModel extends Customer {
  const CustomerModel({
    required super.action,
    required super.isFound,
    required super.person,
    required super.tour,
    required super.agentCode,
    super.subAgentCode,
    required super.isMember,
    super.pathURLMemberCard,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    final person = json['person'] as Map<String, dynamic>? ?? const {};
    return CustomerModel(
      action: json['action'] as String? ?? '',
      isFound: json['isFound'] as bool? ?? false,
      person: CustomerPersonModel.fromJson(person),
      tour: json['tour'] as Map<String, dynamic>? ?? const {},
      agentCode: json['agentCode'] as String? ?? '',
      subAgentCode: json['subAgentCode'] as String? ?? '',
      isMember: json['isMember'] as bool? ?? false,
      pathURLMemberCard: json['pathURLMemberCard'] as String? ?? '',
    );
  }
}

class CustomerPersonModel extends CustomerPerson {
  const CustomerPersonModel({
    required super.englishName,
    required super.passportNo,
    required super.nationality,
    required super.contacts,
    required super.privileges,
    required super.walletMembers,
    super.shoppingCard,
    super.customerTypeCode,
    super.customerTypeDetail,
    super.isActivate,
    super.flightCode,
    super.airlineCode,
    super.flightDate,
    super.flightTime,
    super.flightRouteDetail,
    super.flightPickup,
    super.custTypeCode,
    super.typeCardMember,
    super.gender,
    super.listIdentity,
    super.provinceCode,
    super.cityCode,
    super.dateOfBirth,
    super.fastRegister,
  });

  factory CustomerPersonModel.fromJson(Map<String, dynamic> json) {
    return CustomerPersonModel(
      englishName: json['englishName'] as String? ?? '',
      passportNo: json['passportNo'] as String? ?? '',
      nationality: json['nationality'] as String? ?? '',
      contacts: _rawList(json['listContact']),
      privileges: _privilegeList(json['listPrivilege']),
      walletMembers: _rawList(json['listWalletMember']),
      shoppingCard: _identityValue(json['listIdentity'], 'SHOPCARD'),
      customerTypeCode: json['customerTypeCode'] as String? ?? '',
      customerTypeDetail: json['customerTypeDetail'] as String? ?? '',
      isActivate: json['isActivate'] as bool? ?? false,
      flightCode: json['flightCode'] as String? ?? '',
      airlineCode: json['airlineCode'] as String? ?? '',
      flightDate: json['flightDate'] as String? ?? '',
      flightTime: json['flightTime'] as String? ?? '',
      flightRouteDetail: json['flightRouteDetail'] as String? ?? '',
      // Legacy's JSON key is lowercase `flightpickup` (`PersonInfo.flightpickup`
      // in `CustomerModel.ts`), unlike its Dart/camelCase counterpart.
      flightPickup: json['flightpickup'] as String? ?? '',
      custTypeCode: _identityValue(json['singleDiscount'], 'CODE'),
      typeCardMember: _identityValue(
        json['singleDiscount'],
        'TYPE CARD MEMBER',
      ),
      gender: json['gender'] as String? ?? 'M',
      listIdentity: _rawList(json['listIdentity']),
      provinceCode: json['provinceCode'] as String? ?? '',
      cityCode: json['cityCode'] as String? ?? '',
      dateOfBirth: json['dateOfBirth'],
      fastRegister: json['fast_register'] as bool? ?? false,
    );
  }

  static List<Map<String, dynamic>> _rawList(dynamic value) {
    return (value as List<dynamic>? ?? const [])
        .map((e) => e as Map<String, dynamic>)
        .toList(growable: false);
  }

  static List<PrivilegeModel> _privilegeList(dynamic value) {
    return (value as List<dynamic>? ?? const [])
        .map((e) => PrivilegeModel.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  // Ports `customer.ts`'s repeated `list.find(n => n.IdentityType == ...)`
  // pattern — shared by `listIdentity` (shopping card) and `singleDiscount`
  // (member-card overlay fields), both `Array<Identity>` in legacy's
  // `CustomerModel.ts`: `{IdentityType, IdentityValue}` pairs rather than
  // direct API fields.
  static String _identityValue(dynamic list, String identityType) {
    final entries = list as List<dynamic>? ?? const [];
    for (final entry in entries) {
      final map = entry as Map<String, dynamic>;
      if (map['IdentityType'] == identityType) {
        return map['IdentityValue'] as String? ?? '';
      }
    }
    return '';
  }
}
