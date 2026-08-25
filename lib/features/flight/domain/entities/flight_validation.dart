/// Port of `ValidateFlightReturn`, returned by `flight/ValidateFlight`
/// (`api-contracts.md` section 7, op 3).
class FlightValidation {
  final bool flightValidate;
  final String pickupCode;
  final String pickupName;
  final String puImageUrl;

  const FlightValidation({
    required this.flightValidate,
    required this.pickupCode,
    required this.pickupName,
    required this.puImageUrl,
  });
}
