import '../../core/di/service_locator.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/device_settings_storage.dart';
import '../flight/domain/usecases/get_date_by_flight_usecase.dart';
import '../flight/domain/usecases/get_flight_by_code_usecase.dart';
import '../nationality/domain/usecases/list_nationalities_usecase.dart';
import 'data/datasources/customer_remote_data_source.dart';
import 'data/repositories/customer_repository_impl.dart';
import 'domain/repositories/customer_repository.dart';
import 'domain/usecases/list_agents_usecase.dart';
import 'domain/usecases/list_customer_types_usecase.dart';
import 'domain/usecases/list_guides_usecase.dart';
import 'domain/usecases/register_customer_usecase.dart';
import 'domain/usecases/search_customer_usecase.dart';
import 'domain/usecases/shipping_address_usecases.dart';
import 'presentation/customer_registration_view_model.dart';

void setupCustomerServiceLocator() {
  sl.registerLazySingleton<CustomerRemoteDataSource>(
    () => CustomerRemoteDataSource(apiClient: sl<ApiClient>()),
  );
  sl.registerLazySingleton<CustomerRepository>(
    () => CustomerRepositoryImpl(
      remote: sl<CustomerRemoteDataSource>(),
      deviceSettingsStorage: sl<DeviceSettingsStorage>(),
    ),
  );
  sl.registerFactory<SearchCustomerUseCase>(
    () => SearchCustomerUseCase(sl<CustomerRepository>()),
  );
  sl.registerFactory<RegisterCustomerUseCase>(
    () => RegisterCustomerUseCase(sl<CustomerRepository>()),
  );
  sl.registerFactory<ListAgentsUseCase>(
    () => ListAgentsUseCase(sl<CustomerRepository>()),
  );
  sl.registerFactory<ListGuidesUseCase>(
    () => ListGuidesUseCase(sl<CustomerRepository>()),
  );
  sl.registerFactory<ListCustomerTypesUseCase>(
    () => ListCustomerTypesUseCase(sl<CustomerRepository>()),
  );
  sl.registerFactory<GetShippingAddressUseCase>(
    () => GetShippingAddressUseCase(sl<CustomerRepository>()),
  );
  sl.registerFactory<UpdateShippingAddressUseCase>(
    () => UpdateShippingAddressUseCase(sl<CustomerRepository>()),
  );
  sl.registerFactory<CustomerRegistrationViewModel>(
    () => CustomerRegistrationViewModel(
      listNationalities: sl<ListNationalitiesUseCase>(),
      listAgents: sl<ListAgentsUseCase>(),
      listGuides: sl<ListGuidesUseCase>(),
      listCustomerTypes: sl<ListCustomerTypesUseCase>(),
      getFlightByCode: sl<GetFlightByCodeUseCase>(),
      getDateByFlight: sl<GetDateByFlightUseCase>(),
      registerCustomer: sl<RegisterCustomerUseCase>(),
    ),
  );
}
