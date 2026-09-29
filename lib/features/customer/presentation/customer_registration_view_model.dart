import 'package:get/get.dart';

import '../../../core/error/app_exception.dart';
import '../../flight/domain/entities/flight.dart';
import '../../flight/domain/usecases/get_date_by_flight_usecase.dart';
import '../../flight/domain/usecases/get_flight_by_code_usecase.dart';
import '../../nationality/domain/entities/nationality.dart';
import '../../nationality/domain/usecases/list_nationalities_usecase.dart';
import '../domain/entities/agent.dart';
import '../domain/entities/customer_registration.dart';
import '../domain/usecases/list_agents_usecase.dart';
import '../domain/usecases/list_customer_types_usecase.dart';
import '../domain/usecases/list_guides_usecase.dart';
import '../domain/usecases/register_customer_usecase.dart';

/// Matches the legacy mobile client's hardcoded
/// `RegisterParamModel.prefixShoppingCard = "99"` (`customer-form.ts`) — not
/// derived from device settings.
const _prefixShoppingCard = '99';

/// Matches `customer-form.ts`'s `this.action` — `"REGISTER_ADD"` for a
/// brand-new customer, `"REGISTER_EDIT"` for editing one found via search.
/// Both submit to the same `RegisterAPI` endpoint; only the action string
/// (and, on the page, which fields start prefilled) differs.
const _registerAddAction = 'REGISTER_ADD';
const _registerEditAction = 'REGISTER_EDIT';

enum CustomerRegistrationStatus { idle, submitting, success, failure }

/// Drives the manual-entry "Register new customer" form, shared with the
/// edit-existing-customer flow (`isEdit: true` on [submit]). Ports
/// `customer-form.ts`'s `addDatatoModel()` for the fields this form
/// collects (English name, passport, nationality, agent, guide, allow
/// take-away); every other `PersonInfo` field defaults the same way an
/// empty/never-touched form field would in the legacy client.
class CustomerRegistrationViewModel extends GetxController {
  final ListNationalitiesUseCase _listNationalities;
  final ListAgentsUseCase _listAgents;
  final ListGuidesUseCase _listGuides;
  final ListCustomerTypesUseCase _listCustomerTypes;
  final GetFlightByCodeUseCase _getFlightByCode;
  final GetDateByFlightUseCase _getDateByFlight;
  final RegisterCustomerUseCase _registerCustomer;

  CustomerRegistrationViewModel({
    required ListNationalitiesUseCase listNationalities,
    required ListAgentsUseCase listAgents,
    required ListGuidesUseCase listGuides,
    required ListCustomerTypesUseCase listCustomerTypes,
    required GetFlightByCodeUseCase getFlightByCode,
    required GetDateByFlightUseCase getDateByFlight,
    required RegisterCustomerUseCase registerCustomer,
  }) : _listNationalities = listNationalities,
       _listAgents = listAgents,
       _listGuides = listGuides,
       _listCustomerTypes = listCustomerTypes,
       _getFlightByCode = getFlightByCode,
       _getDateByFlight = getDateByFlight,
       _registerCustomer = registerCustomer;

  CustomerRegistrationStatus status = CustomerRegistrationStatus.idle;
  String? errorMessage;
  RegisterResult? result;

  /// `pageSize: 0` matches `nationality.ts`'s picker call — the legacy
  /// nationality search treats it as "return every match" rather than
  /// paging results.
  Future<List<Nationality>> searchNationalities(String query) =>
      _listNationalities(countryCode: query, pageSize: 0);

  Future<List<Agent>> searchAgents(String query) => _listAgents(input: query);

  Future<List<Agent>> searchGuides(String query) => _listGuides(input: query);

  /// Backs the desktop Customer type lookup; handheld keeps the free-text
  /// field.
  Future<List<Agent>> searchCustomerTypes(String query) =>
      _listCustomerTypes(input: query);

  /// `pageSize: 60` matches `flight.ts`'s picker call.
  Future<List<Flight>> searchFlights(String query) =>
      _getFlightByCode(flightCode: query, pageSize: 60);

  /// Ports `customer-form.ts`'s `getFlightDate()` — called once a flight is
  /// picked, to resolve the candidate dates for that flight code.
  Future<List<Flight>> getDatesForFlight(String flightCode) =>
      _getDateByFlight(flightCode: flightCode, pageSize: 60);

  Future<bool> submit({
    required String englishName,
    required String passportNo,
    required String nationality,
    required String gender,
    required String customerTypeCode,
    required bool allowTakeAway,
    required bool isAirportMpos,
    required String userCode,
    String agentCode = '',
    String subAgentCode = '',
    String flightCode = '',
    String flightDate = '',
    String flightTime = '',
    String airlineCode = '',
    String email = '',
    String mobile = '',
    String weChat = '',
    bool isEdit = false,
    bool isActivate = false,
    List<Map<String, dynamic>> listIdentity = const [],
    String provinceCode = '',
    String cityCode = '',
  }) async {
    status = CustomerRegistrationStatus.submitting;
    errorMessage = null;
    update();

    try {
      result = await _registerCustomer(
        agentCode: agentCode,
        subAgentCode: subAgentCode,
        prefixShoppingCard: _prefixShoppingCard,
        userCode: userCode,
        action: isEdit ? _registerEditAction : _registerAddAction,
        allowTakeAway: allowTakeAway,
        isAirport: isAirportMpos,
        tour: const {},
        listPersonal: [
          _buildPersonInfo(
            englishName: englishName,
            passportNo: passportNo,
            nationality: nationality,
            gender: gender,
            // Airport-mode registrations force customer type to "FIT" server-side,
            // regardless of what (if anything) the form collected — matches
            // legacy's `if (this.settingsService.settings.isAirportMpos) {
            // personNew.customerTypeCode = "FIT"; }`, applied AFTER the
            // shoppingCard-present override below in legacy's own source order.
            customerTypeCode: isAirportMpos ? 'FIT' : customerTypeCode,
            flightCode: flightCode,
            flightDate: flightDate,
            flightTime: flightTime,
            airlineCode: airlineCode,
            email: email,
            mobile: mobile,
            weChat: weChat,
            isActivate: isActivate,
            listIdentity: listIdentity,
            provinceCode: provinceCode,
            cityCode: cityCode,
          ),
        ],
      );
      status = CustomerRegistrationStatus.success;
      update();
      return true;
    } catch (e) {
      status = CustomerRegistrationStatus.failure;
      errorMessage = e is ApiException
          ? e.messageDesc
          : 'Could not register the customer.';
      update();
      return false;
    }
  }

  Map<String, dynamic> _buildPersonInfo({
    required String englishName,
    required String passportNo,
    required String nationality,
    required String gender,
    required String customerTypeCode,
    required String flightCode,
    required String flightDate,
    required String flightTime,
    required String airlineCode,
    required String email,
    required String mobile,
    required String weChat,
    required bool isActivate,
    required List<Map<String, dynamic>> listIdentity,
    required String provinceCode,
    required String cityCode,
  }) => {
    'runningNo': 1,
    'englishName': englishName,
    'nativeName': englishName,
    'passportNo': passportNo,
    // Uppercased, matching `customer-form.ts`'s `nationality.toUpperCase()`.
    'nationality': nationality.toUpperCase(),
    'customerTypeCode': customerTypeCode,
    'gender': gender,
    // Echoed from the found customer's current value when one exists
    // (empty otherwise) — see `listIdentity`'s doc comment below.
    'provinceCode': provinceCode,
    'cityCode': cityCode,
    // Not user-entered — legacy sets this from `getDateByFlight`'s first
    // resolved candidate (`data.Data[0].airlineCode`, `customer-form.ts`'s
    // `getFlightDate()`), not from the flight-search result itself.
    'airlineCode': airlineCode,
    'flightCode': flightCode,
    // Sent as separate `yyyy-MM-dd`/`HH:mm` fields — see the page's
    // `_wireFlightDate`/`_wireFlightTime` doc comment for why these aren't
    // the combined display string.
    'flightDate': flightDate,
    'flightTime': flightTime,
    'listContact': _buildListContact(
      email: email,
      mobile: mobile,
      weChat: weChat,
    ),
    // Echoed back verbatim from the found customer's own `listIdentity`
    // when one already has a shopping card (empty for a brand-new
    // registration) — matches legacy's `if (this.shoppingCard != "") {
    // personNew.listIdentity = this.personInfo.listIdentity; ... }`
    // exactly. This is keyed to the *existing shopping card* being
    // present, independent of REGISTER_ADD vs REGISTER_EDIT — a
    // not-yet-completed customer (`isFound: false`) still has a shopping
    // card and still echoes this. Sending an empty list here for an edit
    // was suspected of preventing the server from correctly linking the
    // submission back to the searched shopping card.
    'listIdentity': listIdentity,
    // Echoed back from the found customer's current value (`false` for a
    // brand-new one) — matches legacy's `personNew.isActivate =
    // this.isActivate` exactly. The server, not the client, decides when a
    // customer actually becomes "Registered"; sending `true` unconditionally
    // (the previous behavior here) never matched legacy and had no effect
    // either way, since the server computes this itself.
    'isActivate': isActivate,
    'fast_register': false,
    'order_status': '',
  };

  // Matches `customer-form.ts`'s `addDatatoModel()`: only non-empty contact
  // values are pushed, using the same `contactType` strings it sends.
  List<Map<String, dynamic>> _buildListContact({
    required String email,
    required String mobile,
    required String weChat,
  }) {
    final contacts = <Map<String, dynamic>>[];
    if (email.isNotEmpty) {
      contacts.add({'contactType': 'E-MAIL', 'contactValue': email});
    }
    if (mobile.isNotEmpty) {
      contacts.add({'contactType': 'MOBILE', 'contactValue': mobile});
    }
    if (weChat.isNotEmpty) {
      contacts.add({'contactType': 'WECHAT', 'contactValue': weChat});
    }
    return contacts;
  }
}
