import '../../../../core/config/device_settings.dart';
import '../repositories/settings_repository.dart';

class LoadDeviceSettingsUseCase {
  final SettingsRepository _repository;

  const LoadDeviceSettingsUseCase(this._repository);

  Future<DeviceSettings> call() => _repository.readDeviceSettings();
}
