import '../domain/entities/customer.dart';

/// Display helpers for a looked-up customer, shared by the desktop Home
/// result and the handheld profile so both read the same way.

/// One row of "Registration checks": [passed] drives the ✓ / ✕, [detail]
/// is the value that satisfied it (empty when there's nothing to show).
class RegistrationCheck {
  final String label;
  final bool passed;
  final String detail;

  const RegistrationCheck(this.label, {required this.passed, this.detail = ''});
}

/// What must be on file before a sale: registered (`isActivate`, legacy's
/// sale guard), a passport, a flight with its date, and a customer type.
List<RegistrationCheck> registrationChecks(CustomerPerson person) {
  final hasFlight = person.flightCode.isNotEmpty && _flightDay(person) != null;
  final flightDay = hasFlight ? _dayLabel(_flightDay(person)!) : '';
  return [
    RegistrationCheck('Customer registered', passed: person.isActivate),
    RegistrationCheck(
      'Passport on file',
      passed: person.passportNo.isNotEmpty,
      detail: person.passportNo,
    ),
    RegistrationCheck(
      'Flight info complete',
      passed: hasFlight,
      detail: hasFlight ? '${person.flightCode} · $flightDay' : '',
    ),
    RegistrationCheck(
      'Customer type set',
      passed: person.customerTypeCode.isNotEmpty,
      detail: person.customerTypeCode,
    ),
  ];
}

/// `26 Aug 23:45` — the flight's calendar date as the API sends it (its
/// `yyyy-MM-dd` part, never shifted by time zone) plus `flightTime`; empty
/// without a date.
String flightWhen(CustomerPerson person) {
  final day = _flightDay(person);
  if (day == null) return '';
  final time = person.flightTime.trim();
  return time.isEmpty ? _dayLabel(day) : '${_dayLabel(day)} $time';
}

/// `9 h 19 m` / `2 d 3 h` until departure (device-local clock); null once
/// departed or when the flight has no date.
String? departsIn(CustomerPerson person, DateTime now) {
  final departure = _departure(person);
  if (departure == null) return null;
  final left = departure.difference(now);
  if (left.isNegative) return null;
  if (left.inDays > 0) return '${left.inDays} d ${left.inHours % 24} h';
  return '${left.inHours} h ${left.inMinutes % 60} m';
}

/// `passport CB912447` / `shopping card 8823-…` — which identifier the
/// lookup [query] matched; the bare query when it was neither (an ID card
/// number, say — `Register/GetCustomer` doesn't report the match).
String foundBy(Customer customer, String query) {
  final q = query.trim().toUpperCase();
  final person = customer.person;
  if (q.isNotEmpty && q == person.passportNo.trim().toUpperCase()) {
    return 'passport ${person.passportNo}';
  }
  if (q.isNotEmpty && q == person.shoppingCard.trim().toUpperCase()) {
    return 'shopping card ${person.shoppingCard}';
  }
  return query.trim();
}

/// Legacy's `gender` codes, `M` / `F`.
String genderLabel(String gender) => switch (gender.trim().toUpperCase()) {
  'M' => 'Male',
  'F' => 'Female',
  _ => '',
};

/// The `MOBILE` entry of `listContact`; empty when there is none.
String mobileNumber(CustomerPerson person) {
  for (final contact in person.contacts) {
    if (contact['contactType'] == 'MOBILE') {
      return '${contact['contactValue'] ?? ''}'.trim();
    }
  }
  return '';
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _dayLabel(DateTime day) => '${day.day} ${_months[day.month - 1]}';

// `2026-08-26T00:00:00+07:00` or `2026-08-26` — only the date part, so a
// `+07:00` offset can't move it to the previous day in UTC.
DateTime? _flightDay(CustomerPerson person) {
  final raw = person.flightDate.trim();
  if (raw.length < 10) return null;
  return DateTime.tryParse(raw.substring(0, 10));
}

DateTime? _departure(CustomerPerson person) {
  final day = _flightDay(person);
  if (day == null) return null;
  final parts = person.flightTime.trim().split(':');
  final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  return DateTime(day.year, day.month, day.day, hour, minute);
}
