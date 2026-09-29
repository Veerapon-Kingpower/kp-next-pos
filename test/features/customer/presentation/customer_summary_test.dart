import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/features/customer/domain/entities/customer.dart';
import 'package:kp_pos/features/customer/presentation/customer_summary.dart';

CustomerPerson _person({
  String passportNo = '',
  String flightCode = '',
  String flightDate = '',
  String flightTime = '',
  String customerTypeCode = '',
  String gender = 'M',
  bool isActivate = false,
  String shoppingCard = '',
  List<Map<String, dynamic>> contacts = const [],
}) => CustomerPerson(
  englishName: 'Sofia Almeida',
  passportNo: passportNo,
  nationality: 'PRT',
  contacts: contacts,
  privileges: const [],
  walletMembers: const [],
  flightCode: flightCode,
  flightDate: flightDate,
  flightTime: flightTime,
  customerTypeCode: customerTypeCode,
  gender: gender,
  isActivate: isActivate,
  shoppingCard: shoppingCard,
);

Customer _customer(CustomerPerson person) => Customer(
  action: 'found',
  isFound: true,
  person: person,
  tour: const {},
  agentCode: '',
  isMember: true,
);

void main() {
  group('registrationChecks', () {
    test('all four pass for a complete, registered customer', () {
      final checks = registrationChecks(
        _person(
          isActivate: true,
          passportNo: 'CB912447',
          flightCode: 'TG916',
          flightDate: '2026-08-26T00:00:00+07:00',
          flightTime: '23:45',
          customerTypeCode: 'TOURIST',
        ),
      );
      expect(checks.map((c) => c.label), [
        'Customer registered',
        'Passport on file',
        'Flight info complete',
        'Customer type set',
      ]);
      expect(checks.every((c) => c.passed), isTrue);
      expect(checks.map((c) => c.detail), [
        '',
        'CB912447',
        'TG916 · 26 Aug',
        'TOURIST',
      ]);
    });

    test('missing data fails its check with no detail', () {
      final checks = registrationChecks(_person(flightCode: 'TG916'));
      expect(checks.map((c) => c.passed), [false, false, false, false]);
      expect(checks.map((c) => c.detail), ['', '', '', '']);
    });
  });

  test('flightWhen reads the calendar date as sent, plus the time', () {
    expect(
      flightWhen(
        _person(flightDate: '2026-08-26T00:00:00+07:00', flightTime: '23:45'),
      ),
      '26 Aug 23:45',
    );
    expect(flightWhen(_person(flightDate: '2026-01-05')), '5 Jan');
    expect(flightWhen(_person()), '');
  });

  group('departsIn', () {
    final flight = _person(flightDate: '2026-08-26', flightTime: '23:45');

    test('hours and minutes until a later departure', () {
      expect(departsIn(flight, DateTime(2026, 8, 26, 14, 26)), '9 h 19 m');
      expect(departsIn(flight, DateTime(2026, 8, 24, 20, 45)), '2 d 3 h');
    });

    test('null once departed, or without a date', () {
      expect(departsIn(flight, DateTime(2026, 8, 27)), isNull);
      expect(departsIn(_person(), DateTime(2026)), isNull);
    });
  });

  test('foundBy names the identifier the query matched', () {
    final customer = _customer(
      _person(passportNo: 'CB912447', shoppingCard: '8823-4419-0027'),
    );
    expect(foundBy(customer, ' cb912447 '), 'passport CB912447');
    expect(foundBy(customer, '8823-4419-0027'), 'shopping card 8823-4419-0027');
    expect(foundBy(customer, '1101700000000'), '1101700000000');
  });

  test('genderLabel and mobileNumber', () {
    expect(genderLabel('M'), 'Male');
    expect(genderLabel('F'), 'Female');
    expect(genderLabel(''), '');
    expect(
      mobileNumber(
        _person(
          contacts: const [
            {'contactType': 'E-MAIL', 'contactValue': 'a@b.c'},
            {'contactType': 'MOBILE', 'contactValue': '+351 91 442 8830'},
          ],
        ),
      ),
      '+351 91 442 8830',
    );
    expect(mobileNumber(_person()), '');
  });
}
