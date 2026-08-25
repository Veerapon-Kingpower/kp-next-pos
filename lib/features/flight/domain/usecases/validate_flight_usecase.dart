import '../entities/flight_validation.dart';
import '../repositories/flight_repository.dart';

/// Ports `customer-form`'s `validateFlight` call — confirms a chosen flight
/// code/date pair and resolves the pickup counter for it.
class ValidateFlightUseCase {
  final FlightRepository _repository;

  const ValidateFlightUseCase(this._repository);

  Future<FlightValidation> call({
    required String flightCode,
    required String flightDateTime,
  }) {
    return _repository.validateFlight(
      flightCode: flightCode,
      flightDateTime: flightDateTime,
    );
  }
}
