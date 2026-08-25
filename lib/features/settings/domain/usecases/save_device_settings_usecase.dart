import '../../../../core/config/device_settings.dart';
import '../repositories/settings_repository.dart';

class SaveDeviceSettingsUseCase {
  final SettingsRepository _repository;

  const SaveDeviceSettingsUseCase(this._repository);

  Future<void> call(DeviceSettings settings) =>
      _repository.saveDeviceSettings(settings);
}
