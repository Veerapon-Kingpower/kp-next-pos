import '../../domain/entities/sub_branch.dart';

class SubBranchModel extends SubBranch {
  const SubBranchModel({
    required super.subbranchCode,
    required super.subbranchName,
    required super.branchNo,
    required super.configSC,
    required super.cutOffTime,
  });

  factory SubBranchModel.fromJson(Map<String, dynamic> json) => SubBranchModel(
    subbranchCode: _asString(json['subbranchCode']),
    subbranchName: _asString(json['subbranchName']),
    branchNo: _asString(json['BranchNo']),
    configSC: _asString(json['ConfigSC']),
    cutOffTime: _asString(json['CutOffTime']),
  );
}

/// The server sends some fields documented as strings (e.g. `BranchNo`) as
/// JSON numbers instead — coerce defensively rather than a straight
/// `as String?` cast, which throws on a live 401-free response.
String _asString(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  return value.toString();
}
