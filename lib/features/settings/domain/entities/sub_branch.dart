/// Port of `SubBranchModel` from `Register/GetListSubbranch`
/// (`api-contracts.md` section 6, op 6).
class SubBranch {
  final String subbranchCode;
  final String subbranchName;
  final String branchNo;
  final String configSC;
  final String cutOffTime;

  const SubBranch({
    required this.subbranchCode,
    required this.subbranchName,
    required this.branchNo,
    required this.configSC,
    required this.cutOffTime,
  });
}
