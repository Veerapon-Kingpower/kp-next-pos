import '../../../../core/config/device_settings.dart';
import '../../../../core/storage/device_settings_storage.dart';
import '../../domain/entities/sub_branch.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_remote_data_source.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsRemoteDataSource _remote;
  final DeviceSettingsStorage _deviceSettingsStorage;

  const SettingsRepositoryImpl({
    required SettingsRemoteDataSource remote,
    required DeviceSettingsStorage deviceSettingsStorage,
  }) : _remote = remote,
       _deviceSettingsStorage = deviceSettingsStorage;

  @override
  Future<DeviceSettings> readDeviceSettings() => _deviceSettingsStorage.read();

  @override
  Future<void> saveDeviceSettings(DeviceSettings settings) =>
      _deviceSettingsStorage.save(settings);

  @override
  Future<List<SubBranch>> listSubBranches({
    required String baseUrl,
    String key = '',
  }) => _remote.listSubBranches(baseUrl: baseUrl, key: key);
}
