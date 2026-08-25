import 'package:kp_pos/features/flight/domain/entities/flight.dart';
import 'package:kp_pos/features/flight/domain/entities/flight_validation.dart';
import 'package:kp_pos/features/flight/domain/repositories/flight_repository.dart';

/// Shared test double for [FlightRepository].
class FakeFlightRepository implements FlightRepository {
  final List<Flight> searchResult;
  final List<Flight> dateResult;

  String? lastFlightCode;
  String? lastDateByFlightCode;

  FakeFlightRepository({this.searchResult = const [], List<Flight>? dateResult})
    : dateResult = dateResult ?? searchResult;

  @override
  Future<List<Flight>> getFlightByCode({
    required String flightCode,
    String flightType = '',
    int pageNo = 0,
    int pageSize = 60,
  }) async {
    lastFlightCode = flightCode;
    return searchResult;
  }

  @override
  Future<List<Flight>> getDateByFlight({
    required String flightCode,
    String flightType = '',
    int pageNo = 0,
    int pageSize = 60,
  }) async {
    lastDateByFlightCode = flightCode;
    return dateResult;
  }

  @override
  Future<FlightValidation> validateFlight({
    required String flightCode,
    required String flightDateTime,
  }) async => const FlightValidation(
    flightValidate: true,
    pickupCode: '',
    pickupName: '',
    puImageUrl: '',
  );
}
