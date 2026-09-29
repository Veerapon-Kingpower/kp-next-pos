import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/error/app_exception.dart';
import 'package:kp_pos/features/customer/domain/entities/customer_registration.dart';
import 'package:kp_pos/features/customer/domain/usecases/list_agents_usecase.dart';
import 'package:kp_pos/features/customer/domain/usecases/list_guides_usecase.dart';
import 'package:kp_pos/features/customer/domain/usecases/list_customer_types_usecase.dart';
import 'package:kp_pos/features/customer/domain/usecases/register_customer_usecase.dart';
import 'package:kp_pos/features/customer/presentation/customer_registration_view_model.dart';
import 'package:kp_pos/features/flight/domain/entities/flight.dart';
import 'package:kp_pos/features/flight/domain/usecases/get_date_by_flight_usecase.dart';
import 'package:kp_pos/features/flight/domain/usecases/get_flight_by_code_usecase.dart';
import 'package:kp_pos/features/nationality/domain/usecases/list_nationalities_usecase.dart';

import '../../flight/fake_flight_repository.dart';
import '../../nationality/fake_nationality_repository.dart';
import '../fake_customer_repository.dart';

void main() {
  CustomerRegistrationViewModel buildViewModel(
    FakeCustomerRepository repo, {
    FakeNationalityRepository? nationalityRepo,
    FakeFlightRepository? flightRepo,
  }) {
    final flight = flightRepo ?? FakeFlightRepository();
    return CustomerRegistrationViewModel(
      listNationalities: ListNationalitiesUseCase(
        nationalityRepo ?? FakeNationalityRepository(),
      ),
      listAgents: ListAgentsUseCase(repo),
      listGuides: ListGuidesUseCase(repo),
      listCustomerTypes: ListCustomerTypesUseCase(repo),
      getFlightByCode: GetFlightByCodeUseCase(flight),
      getDateByFlight: GetDateByFlightUseCase(flight),
      registerCustomer: RegisterCustomerUseCase(repo),
    );
  }

  test(
    'submit sends REGISTER_ADD, the "99" shopping-card prefix, and a listPersonal entry built from the form fields',
    () async {
      final repo = FakeCustomerRepository();
      final viewModel = buildViewModel(repo);

      await viewModel.submit(
        englishName: 'Jane Doe',
        passportNo: 'P1234567',
        nationality: 'tha',
        gender: 'M',
        customerTypeCode: 'VIP',
        agentCode: 'AG1',
        subAgentCode: 'GD1',
        allowTakeAway: true,
        isAirportMpos: true,
        userCode: 'U001',
      );

      final sent = repo.lastRegisterCall!;
      expect(sent['action'], 'REGISTER_ADD');
      expect(sent['prefixShoppingCard'], '99');
      expect(sent['agentCode'], 'AG1');
      expect(sent['subAgentCode'], 'GD1');
      expect(sent['allowTakeAway'], true);
      expect(sent['isAirport'], true);
      expect(sent['userCode'], 'U001');
      expect(sent['tour'], <String, dynamic>{});

      final listPersonal = sent['listPersonal'] as List<Map<String, dynamic>>;
      expect(listPersonal, hasLength(1));
      expect(listPersonal.single['englishName'], 'Jane Doe');
      expect(listPersonal.single['passportNo'], 'P1234567');
      // Uppercased, matching the legacy client's `nationality.toUpperCase()`.
      expect(listPersonal.single['nationality'], 'THA');
    },
  );

  test('submit sends REGISTER_EDIT when isEdit is true', () async {
    final repo = FakeCustomerRepository();
    final viewModel = buildViewModel(repo);

    await viewModel.submit(
      englishName: 'Jane Doe',
      passportNo: 'P1234567',
      nationality: 'THA',
      gender: 'M',
      customerTypeCode: 'VIP',
      allowTakeAway: false,
      isAirportMpos: false,
      userCode: 'U001',
      isEdit: true,
    );

    expect(repo.lastRegisterCall!['action'], 'REGISTER_EDIT');
  });

  test(
    'submit includes the selected flight code in listPersonal, defaulting to empty',
    () async {
      final repo = FakeCustomerRepository();
      final viewModel = buildViewModel(repo);

      await viewModel.submit(
        englishName: 'Jane Doe',
        passportNo: 'P1234567',
        nationality: 'THA',
        gender: 'M',
        customerTypeCode: 'VIP',
        allowTakeAway: false,
        isAirportMpos: false,
        userCode: 'U001',
        flightCode: 'TG101',
      );

      final listPersonal =
          repo.lastRegisterCall!['listPersonal'] as List<Map<String, dynamic>>;
      expect(listPersonal.single['flightCode'], 'TG101');

      await viewModel.submit(
        englishName: 'Jane Doe',
        passportNo: 'P1234567',
        nationality: 'THA',
        gender: 'M',
        customerTypeCode: 'VIP',
        allowTakeAway: false,
        isAirportMpos: false,
        userCode: 'U001',
      );

      final secondListPersonal =
          repo.lastRegisterCall!['listPersonal'] as List<Map<String, dynamic>>;
      expect(secondListPersonal.single['flightCode'], '');
    },
  );

  test(
    'submit includes the selected flight date in listPersonal, defaulting to empty',
    () async {
      final repo = FakeCustomerRepository();
      final viewModel = buildViewModel(repo);

      await viewModel.submit(
        englishName: 'Jane Doe',
        passportNo: 'P1234567',
        nationality: 'THA',
        gender: 'M',
        customerTypeCode: 'VIP',
        allowTakeAway: false,
        isAirportMpos: false,
        userCode: 'U001',
        flightCode: 'TG101',
        flightDate: '2026-08-18 10:00',
      );

      final listPersonal =
          repo.lastRegisterCall!['listPersonal'] as List<Map<String, dynamic>>;
      expect(listPersonal.single['flightDate'], '2026-08-18 10:00');

      await viewModel.submit(
        englishName: 'Jane Doe',
        passportNo: 'P1234567',
        nationality: 'THA',
        gender: 'M',
        customerTypeCode: 'VIP',
        allowTakeAway: false,
        isAirportMpos: false,
        userCode: 'U001',
      );

      final secondListPersonal =
          repo.lastRegisterCall!['listPersonal'] as List<Map<String, dynamic>>;
      expect(secondListPersonal.single['flightDate'], '');
    },
  );

  test(
    'submit includes the selected flight time in listPersonal, defaulting to empty '
    '— sent as a separate field from flightDate, matching legacy',
    () async {
      final repo = FakeCustomerRepository();
      final viewModel = buildViewModel(repo);

      await viewModel.submit(
        englishName: 'Jane Doe',
        passportNo: 'P1234567',
        nationality: 'THA',
        gender: 'M',
        customerTypeCode: 'VIP',
        allowTakeAway: false,
        isAirportMpos: false,
        userCode: 'U001',
        flightCode: 'TG101',
        flightDate: '2026-08-18',
        flightTime: '10:00',
      );

      final listPersonal =
          repo.lastRegisterCall!['listPersonal'] as List<Map<String, dynamic>>;
      expect(listPersonal.single['flightDate'], '2026-08-18');
      expect(listPersonal.single['flightTime'], '10:00');

      await viewModel.submit(
        englishName: 'Jane Doe',
        passportNo: 'P1234567',
        nationality: 'THA',
        gender: 'M',
        customerTypeCode: 'VIP',
        allowTakeAway: false,
        isAirportMpos: false,
        userCode: 'U001',
      );

      final secondListPersonal =
          repo.lastRegisterCall!['listPersonal'] as List<Map<String, dynamic>>;
      expect(secondListPersonal.single['flightTime'], '');
    },
  );

  test(
    'submit includes the resolved airline code in listPersonal, defaulting to empty '
    '— legacy sources this from the flight-date lookup, not the flight search result',
    () async {
      final repo = FakeCustomerRepository();
      final viewModel = buildViewModel(repo);

      await viewModel.submit(
        englishName: 'Jane Doe',
        passportNo: 'P1234567',
        nationality: 'THA',
        gender: 'M',
        customerTypeCode: 'VIP',
        allowTakeAway: false,
        isAirportMpos: false,
        userCode: 'U001',
        flightCode: 'TG101',
        airlineCode: 'TG',
      );

      final listPersonal =
          repo.lastRegisterCall!['listPersonal'] as List<Map<String, dynamic>>;
      expect(listPersonal.single['airlineCode'], 'TG');

      await viewModel.submit(
        englishName: 'Jane Doe',
        passportNo: 'P1234567',
        nationality: 'THA',
        gender: 'M',
        customerTypeCode: 'VIP',
        allowTakeAway: false,
        isAirportMpos: false,
        userCode: 'U001',
      );

      final secondListPersonal =
          repo.lastRegisterCall!['listPersonal'] as List<Map<String, dynamic>>;
      expect(secondListPersonal.single['airlineCode'], '');
    },
  );

  test(
    'submit echoes isActivate from the found customer, defaulting to false '
    '— the server, not the client, decides when it flips true (matches legacy exactly)',
    () async {
      final repo = FakeCustomerRepository();
      final viewModel = buildViewModel(repo);

      await viewModel.submit(
        englishName: 'Jane Doe',
        passportNo: 'P1234567',
        nationality: 'THA',
        gender: 'M',
        customerTypeCode: 'VIP',
        allowTakeAway: false,
        isAirportMpos: false,
        userCode: 'U001',
      );

      final listPersonal =
          repo.lastRegisterCall!['listPersonal'] as List<Map<String, dynamic>>;
      expect(listPersonal.single['isActivate'], false);

      await viewModel.submit(
        englishName: 'Jane Doe',
        passportNo: 'P1234567',
        nationality: 'THA',
        gender: 'M',
        customerTypeCode: 'VIP',
        allowTakeAway: false,
        isAirportMpos: false,
        userCode: 'U001',
        isActivate: true,
      );

      final secondListPersonal =
          repo.lastRegisterCall!['listPersonal'] as List<Map<String, dynamic>>;
      expect(secondListPersonal.single['isActivate'], true);
    },
  );

  test(
    'submit echoes listIdentity/provinceCode/cityCode verbatim when given, '
    'defaulting to empty — matches legacy\'s `if (this.shoppingCard != "")` echo',
    () async {
      final repo = FakeCustomerRepository();
      final viewModel = buildViewModel(repo);
      const existingIdentity = [
        {'IdentityType': 'SHOPCARD', 'IdentityValue': 'CPX0001'},
      ];

      await viewModel.submit(
        englishName: 'Jane Doe',
        passportNo: 'P1234567',
        nationality: 'THA',
        gender: 'M',
        customerTypeCode: 'VIP',
        allowTakeAway: false,
        isAirportMpos: false,
        userCode: 'U001',
        listIdentity: existingIdentity,
        provinceCode: 'PC1',
        cityCode: 'CC1',
      );

      final listPersonal =
          repo.lastRegisterCall!['listPersonal'] as List<Map<String, dynamic>>;
      expect(listPersonal.single['listIdentity'], existingIdentity);
      expect(listPersonal.single['provinceCode'], 'PC1');
      expect(listPersonal.single['cityCode'], 'CC1');

      await viewModel.submit(
        englishName: 'Jane Doe',
        passportNo: 'P1234567',
        nationality: 'THA',
        gender: 'M',
        customerTypeCode: 'VIP',
        allowTakeAway: false,
        isAirportMpos: false,
        userCode: 'U001',
      );

      final secondListPersonal =
          repo.lastRegisterCall!['listPersonal'] as List<Map<String, dynamic>>;
      expect(secondListPersonal.single['listIdentity'], isEmpty);
      expect(secondListPersonal.single['provinceCode'], '');
      expect(secondListPersonal.single['cityCode'], '');
    },
  );

  test('submit forces customerTypeCode to "FIT" when isAirportMpos is true, '
      'regardless of what was collected — matches legacy exactly', () async {
    final repo = FakeCustomerRepository();
    final viewModel = buildViewModel(repo);

    await viewModel.submit(
      englishName: 'Jane Doe',
      passportNo: 'P1234567',
      nationality: 'THA',
      gender: 'M',
      customerTypeCode: 'VIP',
      allowTakeAway: false,
      isAirportMpos: true,
      userCode: 'U001',
    );

    final listPersonal =
        repo.lastRegisterCall!['listPersonal'] as List<Map<String, dynamic>>;
    expect(listPersonal.single['customerTypeCode'], 'FIT');
  });

  test('a successful submit stores the register result', () async {
    const registerResult = RegisterResult(
      outputs: [
        RegisterOutput(
          runningNo: '1',
          shoppingCard: 'CPX0099',
          qrShoppingCard: 'QR-CPX0099',
          coupons: [],
        ),
      ],
      messages: [],
      isComplete: true,
    );
    final repo = FakeCustomerRepository(registerResult: registerResult);
    final viewModel = buildViewModel(repo);

    final success = await viewModel.submit(
      englishName: 'Jane Doe',
      passportNo: 'P1234567',
      nationality: 'THA',
      gender: 'M',
      customerTypeCode: 'VIP',
      allowTakeAway: false,
      isAirportMpos: false,
      userCode: 'U001',
    );

    expect(success, true);
    expect(viewModel.status, CustomerRegistrationStatus.success);
    expect(viewModel.result!.outputs.single.shoppingCard, 'CPX0099');
  });

  test(
    'a failed submit surfaces the server message and leaves status as failure',
    () async {
      final repo = FakeCustomerRepository(
        registerError: const ApiException(
          messageDesc: 'Passport already registered.',
        ),
      );
      final viewModel = buildViewModel(repo);

      final success = await viewModel.submit(
        englishName: 'Jane Doe',
        passportNo: 'P1234567',
        nationality: 'THA',
        gender: 'M',
        customerTypeCode: 'VIP',
        allowTakeAway: false,
        isAirportMpos: false,
        userCode: 'U001',
      );

      expect(success, false);
      expect(viewModel.status, CustomerRegistrationStatus.failure);
      expect(viewModel.errorMessage, 'Passport already registered.');
    },
  );

  test('searchNationalities delegates to ListNationalitiesUseCase', () async {
    final nationalityRepo = FakeNationalityRepository();
    final viewModel = buildViewModel(
      FakeCustomerRepository(),
      nationalityRepo: nationalityRepo,
    );

    await viewModel.searchNationalities('tha');

    expect(nationalityRepo.lastCountryCode, 'tha');
  });

  test(
    'searchAgents delegates to ListAgentsUseCase with typeSearch "A"',
    () async {
      final repo = FakeCustomerRepository();
      final viewModel = buildViewModel(repo);

      await viewModel.searchAgents('AG');

      expect(repo.lastAgentsInput, 'AG');
      expect(repo.lastAgentsTypeSearch, 'A');
    },
  );

  test(
    'searchGuides delegates to ListGuidesUseCase with typeSearch "S"',
    () async {
      final repo = FakeCustomerRepository();
      final viewModel = buildViewModel(repo);

      await viewModel.searchGuides('GD');

      expect(repo.lastAgentsInput, 'GD');
      expect(repo.lastAgentsTypeSearch, 'S');
    },
  );

  test(
    'searchCustomerTypes delegates with typeSearch "C"',
    () async {
      final repo = FakeCustomerRepository();
      final viewModel = buildViewModel(repo);

      await viewModel.searchCustomerTypes('TOU');

      expect(repo.lastAgentsInput, 'TOU');
      expect(repo.lastAgentsTypeSearch, 'C');
    },
  );

  test('searchFlights delegates to GetFlightByCodeUseCase', () async {
    final flightRepo = FakeFlightRepository();
    final viewModel = buildViewModel(
      FakeCustomerRepository(),
      flightRepo: flightRepo,
    );

    await viewModel.searchFlights('TG');

    expect(flightRepo.lastFlightCode, 'TG');
  });

  test('getDatesForFlight delegates to GetDateByFlightUseCase', () async {
    const dates = [
      Flight(
        flightCode: 'TG101',
        flightDescription: 'Bangkok - Tokyo',
        arrDepAirportName: 'Suvarnabhumi',
        destAirportName: 'Narita',
        flightType: 'D',
        airlineCode: 'TG',
        flightNo: '101',
        flightDate: '2026-08-18 10:00',
      ),
    ];
    final flightRepo = FakeFlightRepository(dateResult: dates);
    final viewModel = buildViewModel(
      FakeCustomerRepository(),
      flightRepo: flightRepo,
    );

    final result = await viewModel.getDatesForFlight('TG101');

    expect(flightRepo.lastDateByFlightCode, 'TG101');
    expect(result, dates);
  });

  test(
    'submit includes gender and customer type code in listPersonal',
    () async {
      final repo = FakeCustomerRepository();
      final viewModel = buildViewModel(repo);

      await viewModel.submit(
        englishName: 'Jane Doe',
        passportNo: 'P1234567',
        nationality: 'THA',
        gender: 'F',
        customerTypeCode: 'VIP',
        allowTakeAway: false,
        isAirportMpos: false,
        userCode: 'U001',
      );

      final listPersonal =
          repo.lastRegisterCall!['listPersonal'] as List<Map<String, dynamic>>;
      expect(listPersonal.single['gender'], 'F');
      expect(listPersonal.single['customerTypeCode'], 'VIP');
    },
  );

  test(
    'submit builds listContact from email, mobile, and weChat when provided',
    () async {
      final repo = FakeCustomerRepository();
      final viewModel = buildViewModel(repo);

      await viewModel.submit(
        englishName: 'Jane Doe',
        passportNo: 'P1234567',
        nationality: 'THA',
        gender: 'M',
        customerTypeCode: 'VIP',
        allowTakeAway: false,
        isAirportMpos: false,
        userCode: 'U001',
        email: 'jane@example.com',
        mobile: '0812345678',
        weChat: 'jane_wc',
      );

      final listPersonal =
          repo.lastRegisterCall!['listPersonal'] as List<Map<String, dynamic>>;
      final listContact =
          listPersonal.single['listContact'] as List<Map<String, dynamic>>;
      expect(listContact, [
        {'contactType': 'E-MAIL', 'contactValue': 'jane@example.com'},
        {'contactType': 'MOBILE', 'contactValue': '0812345678'},
        {'contactType': 'WECHAT', 'contactValue': 'jane_wc'},
      ]);
    },
  );

  test('submit always sends all three contacts, blank ones included '
      '(legacy addDatatoModel)', () async {
    final repo = FakeCustomerRepository();
    final viewModel = buildViewModel(repo);

    await viewModel.submit(
      englishName: 'Jane Doe',
      passportNo: 'P1234567',
      nationality: 'THA',
      gender: 'M',
      customerTypeCode: 'VIP',
      allowTakeAway: false,
      isAirportMpos: false,
      userCode: 'U001',
    );

    final listPersonal =
        repo.lastRegisterCall!['listPersonal'] as List<Map<String, dynamic>>;
    expect(listPersonal.single['listContact'], [
      {'contactType': 'E-MAIL', 'contactValue': ''},
      {'contactType': 'MOBILE', 'contactValue': ''},
      {'contactType': 'WECHAT', 'contactValue': ''},
    ]);
    expect(listPersonal.single['dateOfBirth'], isNull);
    expect(listPersonal.single, containsPair('order_date', null));
    expect(repo.lastRegisterCall!['tour'], isEmpty);
  });

  test('submit echoes the found customer\'s tour and dateOfBirth', () async {
    final repo = FakeCustomerRepository();
    final viewModel = buildViewModel(repo);

    await viewModel.submit(
      englishName: 'Jane Doe',
      passportNo: 'P1234567',
      nationality: 'THA',
      gender: 'F',
      customerTypeCode: 'VIP',
      allowTakeAway: false,
      isAirportMpos: false,
      userCode: 'U001',
      dateOfBirth: '1990-01-02T00:00:00',
      tour: const {'tourCode': 'T1'},
    );

    final listPersonal =
        repo.lastRegisterCall!['listPersonal'] as List<Map<String, dynamic>>;
    expect(listPersonal.single['dateOfBirth'], '1990-01-02T00:00:00');
    expect(repo.lastRegisterCall!['tour'], {'tourCode': 'T1'});
  });
}
