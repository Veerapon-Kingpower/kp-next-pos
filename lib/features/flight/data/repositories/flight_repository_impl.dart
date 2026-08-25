import '../../../../core/storage/device_settings_storage.dart';
import '../../domain/entities/flight.dart';
import '../../domain/entities/flight_validation.dart';
import '../../domain/repositories/flight_repository.dart';
import '../datasources/flight_remote_data_source.dart';

class FlightRepositoryImpl implements FlightRepository {
  final FlightRemoteDataSource _remote;
  final DeviceSettingsStorage _deviceSettingsStorage;

  FlightRepositoryImpl({
    required FlightRemoteDataSource remote,
    required DeviceSettingsStorage deviceSettingsStorage,
  }) : _remote = remote,
       _deviceSettingsStorage = deviceSettingsStorage;

  @override
  Future<List<Flight>> getFlightByCode({
    required String flightCode,
    String flightType = '',
    int pageNo = 0,
    int pageSize = 60,
  }) async {
    final settings = await _deviceSettingsStorage.read();
    return _remote.getFlightByCode(
      flightApi: settings.flightApi,
      flightCode: flightCode,
      subBranchCode: settings.subBranchCode,
      flightType: flightType,
      isAirport: settings.isAirportMpos,
      pageNo: pageNo,
      pageSize: pageSize,
    );
  }

  @override
  Future<List<Flight>> getDateByFlight({
    required String flightCode,
    String flightType = '',
    int pageNo = 0,
    int pageSize = 60,
  }) async {
    final settings = await _deviceSettingsStorage.read();
    return _remote.getDateByFlight(
      flightApi: settings.flightApi,
      flightCode: flightCode,
      subBranchCode: settings.subBranchCode,
      flightType: flightType,
      isAirport: settings.isAirportMpos,
      pageNo: pageNo,
      pageSize: pageSize,
    );
  }

  @override
  Future<FlightValidation> validateFlight({
    required String flightCode,
    required String flightDateTime,
  }) async {
    final settings = await _deviceSettingsStorage.read();
    return _remote.validateFlight(
      flightApi: settings.flightApi,
      flightCode: flightCode,
      flightDateTime: flightDateTime,
    );
  }
}
