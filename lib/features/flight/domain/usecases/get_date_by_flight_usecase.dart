import '../entities/flight.dart';
import '../repositories/flight_repository.dart';

/// Ports `customer-form`'s flight-date lookup (`flightService.getDateByFlight`)
/// — used to populate the flight-date picker once a flight code is chosen.
class GetDateByFlightUseCase {
  final FlightRepository _repository;

  const GetDateByFlightUseCase(this._repository);

  Future<List<Flight>> call({
    required String flightCode,
    String flightType = '',
    int pageNo = 0,
    int pageSize = 60,
  }) {
    return _repository.getDateByFlight(
      flightCode: flightCode,
      flightType: flightType,
      pageNo: pageNo,
      pageSize: pageSize,
    );
  }
}
