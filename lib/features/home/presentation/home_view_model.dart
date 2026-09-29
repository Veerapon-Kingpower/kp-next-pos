import 'package:get/get.dart';

import '../../../core/config/device_settings.dart';
import '../../../core/error/app_exception.dart';
import '../../auth/domain/entities/user_session.dart';
import '../../auth/domain/usecases/restore_session_usecase.dart';
import '../../customer/domain/entities/customer.dart';
import '../../customer/domain/usecases/search_customer_usecase.dart';
import '../../settings/domain/usecases/load_device_settings_usecase.dart';

/// Composes the signed-in session and current device settings for the
/// post-login dashboard — both already-persisted, local reads (no network
/// call), so a single [load] covers both without its own loading substates.
/// Also drives the dashboard's customer search section — a thin pass-through
/// to [SearchCustomerUseCase] (`Register/GetCustomer`), which only accepts a
/// single `shoppingCard` identifier; the shopping-card/passport/ID-card
/// choice on the page is presentation-only (changes the input's label/hint),
/// not a different backend field.
class HomeViewModel extends GetxController {
  final RestoreSessionUseCase _restoreSession;
  final LoadDeviceSettingsUseCase _loadDeviceSettings;
  final SearchCustomerUseCase _searchCustomer;

  HomeViewModel({
    required RestoreSessionUseCase restoreSession,
    required LoadDeviceSettingsUseCase loadDeviceSettings,
    required SearchCustomerUseCase searchCustomer,
  }) : _restoreSession = restoreSession,
       _loadDeviceSettings = loadDeviceSettings,
       _searchCustomer = searchCustomer;

  bool isLoading = true;
  UserSession? session;
  DeviceSettings settings = const DeviceSettings();

  bool isSearchingCustomer = false;
  bool hasSearchedCustomer = false;
  List<Customer> customerSearchResults = const [];
  String? customerSearchError;

  Future<void> load() async {
    isLoading = true;
    update();

    session = await _restoreSession();
    settings = await _loadDeviceSettings();

    isLoading = false;
    update();
  }

  Future<void> searchCustomer(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    isSearchingCustomer = true;
    hasSearchedCustomer = true;
    customerSearchError = null;
    update();

    try {
      customerSearchResults = await _searchCustomer(
        shoppingCard: trimmed,
        isTour: false,
      );
    } catch (e) {
      customerSearchResults = const [];
      customerSearchError = e is ApiException
          ? e.messageDesc
          : 'Could not search for the customer.';
    }

    isSearchingCustomer = false;
    update();
  }

  /// Back to the not-yet-searched state (desktop Customer "New customer").
  void clearCustomerSearch() {
    hasSearchedCustomer = false;
    customerSearchResults = const [];
    customerSearchError = null;
    update();
  }
}
