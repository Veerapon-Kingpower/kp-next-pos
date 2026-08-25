import 'package:kp_pos/core/config/device_settings.dart';
import 'package:kp_pos/features/settings/domain/entities/sub_branch.dart';
import 'package:kp_pos/features/settings/domain/repositories/settings_repository.dart';

/// Shared test double for [SettingsRepository] — used wherever a test needs
/// a working device-settings read/write and reference-data lookups without
/// real local storage or network calls.
class FakeSettingsRepository implements SettingsRepository {
  DeviceSettings settings;
  final List<SubBranch> subBranches;
  final Object? subBranchesError;

  FakeSettingsRepository({
    this.settings = const DeviceSettings(),
    this.subBranches = const [],
    this.subBranchesError,
  });

  @override
  Future<DeviceSettings> readDeviceSettings() async => settings;

  @override
  Future<void> saveDeviceSettings(DeviceSettings settings) async {
    this.settings = settings;
  }

  @override
  Future<List<SubBranch>> listSubBranches({
    required String baseUrl,
    String key = '',
  }) async {
    if (subBranchesError != null) throw subBranchesError!;
    return subBranches;
  }
}
