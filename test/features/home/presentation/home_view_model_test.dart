import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/config/device_settings.dart';
import 'package:kp_pos/core/error/app_exception.dart';
import 'package:kp_pos/features/auth/domain/entities/user_session.dart';
import 'package:kp_pos/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:kp_pos/features/customer/domain/entities/customer.dart';
import 'package:kp_pos/features/customer/domain/usecases/search_customer_usecase.dart';
import 'package:kp_pos/features/home/presentation/home_view_model.dart';
import 'package:kp_pos/features/settings/domain/usecases/load_device_settings_usecase.dart';

import '../../auth/fake_auth_repository.dart';
import '../../customer/fake_customer_repository.dart';
import '../../settings/fake_settings_repository.dart';

HomeViewModel _buildViewModel({
  UserSession? session,
  DeviceSettings settings = const DeviceSettings(),
  List<Customer> searchResult = const [],
  Object? searchError,
}) {
  return HomeViewModel(
    restoreSession: RestoreSessionUseCase(
      FakeAuthRepository(currentSessionResult: session),
    ),
    loadDeviceSettings: LoadDeviceSettingsUseCase(
      FakeSettingsRepository(settings: settings),
    ),
    searchCustomer: SearchCustomerUseCase(
      FakeCustomerRepository(
        searchResult: searchResult,
        searchError: searchError,
      ),
    ),
  );
}

void main() {
  test(
    'load composes the current session and device settings, then stops loading',
    () async {
      const session = UserSession(
        sessionKey: 'abc123',
        branchNo: '03',
        userCode: 'U001',
        userName: 'Test User',
        authorizedActions: [],
      );
      const settings = DeviceSettings(
        branch: '03',
        moduleKey: 'MposKpi',
        subBranchCode: 'CPX-DT',
      );
      final viewModel = _buildViewModel(session: session, settings: settings);

      expect(viewModel.isLoading, isTrue);

      await viewModel.load();

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.session, session);
      expect(viewModel.settings, settings);
    },
  );

  test('load leaves session null when no session is persisted', () async {
    final viewModel = _buildViewModel();

    await viewModel.load();

    expect(viewModel.isLoading, isFalse);
    expect(viewModel.session, isNull);
  });

  test(
    'searchCustomer populates results and marks the search as performed',
    () async {
      const customer = Customer(
        action: 'found',
        isFound: true,
        person: CustomerPerson(
          englishName: 'Jane Doe',
          passportNo: 'P1234567',
          nationality: 'THA',
          contacts: [],
          privileges: [],
          walletMembers: [],
        ),
        tour: {},
        agentCode: 'AG1',
        isMember: true,
      );
      final viewModel = _buildViewModel(searchResult: const [customer]);

      expect(viewModel.hasSearchedCustomer, isFalse);

      await viewModel.searchCustomer('CPX0001');

      expect(viewModel.isSearchingCustomer, isFalse);
      expect(viewModel.hasSearchedCustomer, isTrue);
      expect(viewModel.customerSearchResults, [customer]);
      expect(viewModel.customerSearchError, isNull);
    },
  );

  test('searchCustomer ignores a blank query', () async {
    final viewModel = _buildViewModel();

    await viewModel.searchCustomer('   ');

    expect(viewModel.hasSearchedCustomer, isFalse);
  });

  test('searchCustomer surfaces the server message on failure', () async {
    final viewModel = _buildViewModel(
      searchError: const ApiException(messageDesc: 'Customer not found.'),
    );

    await viewModel.searchCustomer('CPX0001');

    expect(viewModel.customerSearchError, 'Customer not found.');
    expect(viewModel.customerSearchResults, isEmpty);
  });
}
