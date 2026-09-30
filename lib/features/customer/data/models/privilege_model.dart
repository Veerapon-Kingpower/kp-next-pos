import '../../domain/entities/privilege.dart';

/// Legacy's `PrivilegeModel` fields are PascalCase JSON keys (`Name`,
/// `Discount`, ...), matching this backend's other list-of-object fields
/// (`ReturnMessage`'s `MessageType`/`MessageCode`/`MessageDesc`,
/// `Identity`'s `IdentityType`/`IdentityValue`) rather than the camelCase
/// used for top-level `PersonInfo` fields.
class PrivilegeModel extends Privilege {
  const PrivilegeModel({
    required super.name,
    required super.discount,
    super.promoCode,
    super.typeCode,
    super.subTypeCode,
    super.minimumSpendingPerBill,
    super.maxAmountPerBill,
    super.raw,
  });

  factory PrivilegeModel.fromJson(Map<String, dynamic> json) => PrivilegeModel(
    name: json['Name'] as String? ?? '',
    discount: (json['Discount'] as num?)?.toDouble() ?? 0,
    promoCode: json['PromoCode'] as String? ?? '',
    typeCode: json['TypeCode'] as String? ?? '',
    subTypeCode: json['SubTypeCode'] as String? ?? '',
    minimumSpendingPerBill:
        (json['MinimumSpendingPerBill'] as num?)?.toDouble() ?? 0,
    maxAmountPerBill: (json['MaxAmountPerBill'] as num?)?.toDouble() ?? 0,
    raw: json,
  );
}
