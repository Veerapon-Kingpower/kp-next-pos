import '../../../../core/storage/device_settings_storage.dart';
import '../../domain/entities/nationality.dart';
import '../../domain/repositories/nationality_repository.dart';
import '../datasources/nationality_remote_data_source.dart';

class NationalityRepositoryImpl implements NationalityRepository {
  final NationalityRemoteDataSource _remote;
  final DeviceSettingsStorage _deviceSettingsStorage;

  NationalityRepositoryImpl({
    required NationalityRemoteDataSource remote,
    required DeviceSettingsStorage deviceSettingsStorage,
  }) : _remote = remote,
       _deviceSettingsStorage = deviceSettingsStorage;

  @override
  Future<List<Nationality>> search({
    String countryCode = '',
    int pageNo = 0,
    int pageSize = 50,
  }) async {
    final settings = await _deviceSettingsStorage.read();
    return _remote.search(
      webServiceEndpoint: settings.webServiceEndpoint,
      countryCode: countryCode,
      pageNo: pageNo,
      pageSize: pageSize,
    );
  }
}
