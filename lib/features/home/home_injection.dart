import '../../core/di/service_locator.dart';
import '../auth/domain/usecases/restore_session_usecase.dart';
import '../customer/domain/usecases/search_customer_usecase.dart';
import '../settings/domain/usecases/load_device_settings_usecase.dart';
import 'presentation/home_view_model.dart';

/// Registered after `setupAuthServiceLocator`/`setupCustomerServiceLocator`/
/// `setupSettingsServiceLocator`, since [HomeViewModel] composes usecases
/// owned by those features.
void setupHomeServiceLocator() {
  sl.registerFactory<HomeViewModel>(
    () => HomeViewModel(
      restoreSession: sl<RestoreSessionUseCase>(),
      loadDeviceSettings: sl<LoadDeviceSettingsUseCase>(),
      searchCustomer: sl<SearchCustomerUseCase>(),
    ),
  );
}
