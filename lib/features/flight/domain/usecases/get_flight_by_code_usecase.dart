import '../entities/flight.dart';
import '../repositories/flight_repository.dart';

/// Ports `FlightPage`'s search-as-you-type flight lookup.
class GetFlightByCodeUseCase {
  final FlightRepository _repository;

  const GetFlightByCodeUseCase(this._repository);

  Future<List<Flight>> call({
    required String flightCode,
    String flightType = '',
    int pageNo = 0,
    int pageSize = 60,
  }) {
    return _repository.getFlightByCode(
      flightCode: flightCode,
      flightType: flightType,
      pageNo: pageNo,
      pageSize: pageSize,
    );
  }
}
