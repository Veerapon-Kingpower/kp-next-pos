import '../../../../core/config/device_settings.dart';
import '../entities/sub_branch.dart';

abstract class SettingsRepository {
  /// Reads the currently persisted device configuration.
  Future<DeviceSettings> readDeviceSettings();

  /// Persists the device configuration edited on the Settings page.
  Future<void> saveDeviceSettings(DeviceSettings settings);

  /// Ports `shareData.getListSubBranch` (`Register/GetListSubbranch`).
  /// [baseUrl] is the Register endpoint currently entered on the Settings
  /// page, not a fixed build-time default.
  Future<List<SubBranch>> listSubBranches({
    required String baseUrl,
    String key = '',
  });
}
