/// Port of `FlightClass`, returned by `flight/GetFlightByCode` and
/// `flight/getDateByFlight` (`api-contracts.md` section 7, ops 1/2).
class Flight {
  final String flightCode;
  final String flightDescription;
  final String arrDepAirportName;
  final String destAirportName;
  final String flightType;
  final String airlineCode;
  final String flightNo;
  final String flightDate;

  const Flight({
    required this.flightCode,
    required this.flightDescription,
    required this.arrDepAirportName,
    required this.destAirportName,
    required this.flightType,
    required this.airlineCode,
    required this.flightNo,
    required this.flightDate,
  });
}
