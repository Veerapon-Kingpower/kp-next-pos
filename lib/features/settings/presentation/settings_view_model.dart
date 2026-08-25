import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/config/device_settings.dart';
import '../../../core/error/app_exception.dart';
import '../domain/entities/sub_branch.dart';
import '../domain/usecases/list_sub_branches_usecase.dart';
import '../domain/usecases/load_device_settings_usecase.dart';
import '../domain/usecases/save_device_settings_usecase.dart';

enum SettingsLoadStatus { loading, ready, failure }

enum SettingsSaveStatus { idle, saving, success, failure }

class SettingsViewModel extends GetxController {
  final LoadDeviceSettingsUseCase _loadDeviceSettings;
  final SaveDeviceSettingsUseCase _saveDeviceSettings;
  final ListSubBranchesUseCase _listSubBranches;

  SettingsViewModel({
    required LoadDeviceSettingsUseCase loadDeviceSettings,
    required SaveDeviceSettingsUseCase saveDeviceSettings,
    required ListSubBranchesUseCase listSubBranches,
  }) : _loadDeviceSettings = loadDeviceSettings,
       _saveDeviceSettings = saveDeviceSettings,
       _listSubBranches = listSubBranches;

  SettingsLoadStatus loadStatus = SettingsLoadStatus.loading;
  SettingsSaveStatus saveStatus = SettingsSaveStatus.idle;
  String? errorMessage;

  DeviceSettings settings = const DeviceSettings();
  List<SubBranch> subBranches = const [];
  String? subBranchLoadError;

  Future<void> load() async {
    loadStatus = SettingsLoadStatus.loading;
    update();

    try {
      settings = await _loadDeviceSettings();
    } catch (_) {
      loadStatus = SettingsLoadStatus.failure;
      errorMessage = 'Could not load device settings.';
      update();
      return;
    }

    loadStatus = SettingsLoadStatus.ready;
    update();

    // The sub-branch lookup is best-effort and NOT awaited here: a device
    // being set up for the first time (or reopening Settings against a
    // slow/unreachable Register endpoint) must not block the page on this
    // network call — the form stays usable as free text either way, and
    // this populates the dropdown asynchronously once (if ever) it resolves.
    // It depends on the Register endpoint the user is configuring, so it's
    // only fetched here if one is already persisted; otherwise it waits for
    // [loadSubBranches] once the user has entered one on the form.
    if (settings.webServiceEndpoint.isNotEmpty) {
      unawaited(loadSubBranches(settings.webServiceEndpoint));
    }
  }

  /// Re-fetches sub-branches against [webServiceEndpoint] — called as the
  /// user enters/edits the Register endpoint field on the Settings page,
  /// since the correct endpoint isn't known until they've typed it.
  Future<void> loadSubBranches(String webServiceEndpoint) async {
    if (webServiceEndpoint.isEmpty) {
      subBranches = const [];
      subBranchLoadError = null;
      update();
      return;
    }
    try {
      subBranches = await _listSubBranches(baseUrl: webServiceEndpoint);
      subBranchLoadError = null;
    } catch (e) {
      subBranches = const [];
      subBranchLoadError = e is ApiException
          ? e.messageDesc
          : 'Could not load sub-branches from the Register endpoint.';
    }
    update();
  }

  Future<bool> save(DeviceSettings updated) async {
    saveStatus = SettingsSaveStatus.saving;
    errorMessage = null;
    update();
    if (kDebugMode) {
      debugPrint('[SettingsViewModel.save] saving: ${updated.toJson()}');
    }

    try {
      await _saveDeviceSettings(updated);
      settings = updated;
      saveStatus = SettingsSaveStatus.success;
      update();
      if (kDebugMode) {
        debugPrint('[SettingsViewModel.save] success');
      }
      return true;
    } catch (e) {
      saveStatus = SettingsSaveStatus.failure;
      errorMessage = 'Could not save device settings.';
      update();
      if (kDebugMode) {
        debugPrint('[SettingsViewModel.save] failed: $e');
      }
      return false;
    }
  }
}
