/// Port of `NationalOutputModel`, returned by `Register/GetNationality`
/// (`api-contracts.md` section 6, op 4).
class Nationality {
  final String countryCode;
  final String countryName;

  const Nationality({required this.countryCode, required this.countryName});
}
