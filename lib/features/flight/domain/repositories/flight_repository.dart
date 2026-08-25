import '../entities/flight.dart';
import '../entities/flight_validation.dart';

abstract class FlightRepository {
  /// Ports `flightProvider.getFlightByCode` (`flight/GetFlightByCode`).
  /// `subBranchCode`/`isAirport` are resolved from device settings, matching
  /// the legacy client's `SettingsProvider`-sourced fields.
  Future<List<Flight>> getFlightByCode({
    required String flightCode,
    String flightType = '',
    int pageNo = 0,
    int pageSize = 60,
  });

  /// Ports `flightProvider.getDateByFlight` (`flight/getDateByFlight`) — same
  /// request shape as [getFlightByCode], different endpoint.
  Future<List<Flight>> getDateByFlight({
    required String flightCode,
    String flightType = '',
    int pageNo = 0,
    int pageSize = 60,
  });

  /// Ports `flightProvider.validateFlight` (`flight/ValidateFlight`).
  Future<FlightValidation> validateFlight({
    required String flightCode,
    required String flightDateTime,
  });
}
