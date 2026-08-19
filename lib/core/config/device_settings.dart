/// Per-device POS configuration, persisted locally and editable from the
/// Settings workflow (see `pos-sales-workflows` spec). Field-for-field port
/// of the legacy `SettingsModel` (`smart-pos-mobile/src/models/settings.ts`)
/// so existing device provisioning data has a direct migration path.
class DeviceSettings {
  final String moduleKey;
  final String branch;
  final String subBranchCode;
  final String location;
  final int machine;
  final String company;
  final String serial;
  final String macAddress;
  final String webServiceEndpoint;
  final String updateEndpoint;
  final String uuid;
  final String saleEngineEndpoint;
  final String defaultPage;
  final String flightApi;
  final String memberProfile;
  final String memberApi;
  final String cashCardApi;
  final String printHubEndpoint;
  final String pickupCode;
  final bool isAirportMpos;

  const DeviceSettings({
    this.moduleKey = '',
    this.branch = '',
    this.subBranchCode = '',
    this.location = '',
    this.machine = 0,
    this.company = '',
    this.serial = '',
    this.macAddress = '',
    this.webServiceEndpoint = '',
    this.updateEndpoint = '',
    this.uuid = '',
    this.saleEngineEndpoint = '',
    // Legacy default is "HomePage"; kept as a plain string since routing is
    // a Flutter-side concern, not a page-class name.
    this.defaultPage = 'home',
    this.flightApi = '',
    this.memberProfile = '',
    this.memberApi = '',
    this.cashCardApi = '',
    this.printHubEndpoint = '',
    this.pickupCode = '',
    this.isAirportMpos = false,
  });

  /// Matches the legacy Settings page's own completeness check
  /// (`settings.ts` — required: `saleEngineEndpoint`, `webServiceEndpoint`,
  /// `flightApi`). Used to gate startup: an incomplete device must go
  /// through first-time setup before any workflow can run.
  bool get isComplete =>
      saleEngineEndpoint.isNotEmpty &&
      webServiceEndpoint.isNotEmpty &&
      flightApi.isNotEmpty;

  DeviceSettings copyWith({
    String? moduleKey,
    String? branch,
    String? subBranchCode,
    String? location,
    int? machine,
    String? company,
    String? serial,
    String? macAddress,
    String? webServiceEndpoint,
    String? updateEndpoint,
    String? uuid,
    String? saleEngineEndpoint,
    String? defaultPage,
    String? flightApi,
    String? memberProfile,
    String? memberApi,
    String? cashCardApi,
    String? printHubEndpoint,
    String? pickupCode,
    bool? isAirportMpos,
  }) {
    return DeviceSettings(
      moduleKey: moduleKey ?? this.moduleKey,
      branch: branch ?? this.branch,
      subBranchCode: subBranchCode ?? this.subBranchCode,
      location: location ?? this.location,
      machine: machine ?? this.machine,
      company: company ?? this.company,
      serial: serial ?? this.serial,
      macAddress: macAddress ?? this.macAddress,
      webServiceEndpoint: webServiceEndpoint ?? this.webServiceEndpoint,
      updateEndpoint: updateEndpoint ?? this.updateEndpoint,
      uuid: uuid ?? this.uuid,
      saleEngineEndpoint: saleEngineEndpoint ?? this.saleEngineEndpoint,
      defaultPage: defaultPage ?? this.defaultPage,
      flightApi: flightApi ?? this.flightApi,
      memberProfile: memberProfile ?? this.memberProfile,
      memberApi: memberApi ?? this.memberApi,
      cashCardApi: cashCardApi ?? this.cashCardApi,
      printHubEndpoint: printHubEndpoint ?? this.printHubEndpoint,
      pickupCode: pickupCode ?? this.pickupCode,
      isAirportMpos: isAirportMpos ?? this.isAirportMpos,
    );
  }

  Map<String, dynamic> toJson() => {
    'moduleKey': moduleKey,
    'branch': branch,
    'subBranchCode': subBranchCode,
    'location': location,
    'machine': machine,
    'company': company,
    'serial': serial,
    'macAddress': macAddress,
    'webServiceEndpoint': webServiceEndpoint,
    'updateEndpoint': updateEndpoint,
    'uuid': uuid,
    'saleEngineEndpoint': saleEngineEndpoint,
    'defaultPage': defaultPage,
    'flightApi': flightApi,
    'memberProfile': memberProfile,
    'memberApi': memberApi,
    'cashCardApi': cashCardApi,
    'printHubEndpoint': printHubEndpoint,
    'pickupCode': pickupCode,
    'isAirportMpos': isAirportMpos,
  };

  factory DeviceSettings.fromJson(Map<String, dynamic> json) => DeviceSettings(
    moduleKey: json['moduleKey'] as String? ?? '',
    branch: json['branch'] as String? ?? '',
    subBranchCode: json['subBranchCode'] as String? ?? '',
    location: json['location'] as String? ?? '',
    machine: json['machine'] as int? ?? 0,
    company: json['company'] as String? ?? '',
    serial: json['serial'] as String? ?? '',
    macAddress: json['macAddress'] as String? ?? '',
    webServiceEndpoint: json['webServiceEndpoint'] as String? ?? '',
    updateEndpoint: json['updateEndpoint'] as String? ?? '',
    uuid: json['uuid'] as String? ?? '',
    saleEngineEndpoint: json['saleEngineEndpoint'] as String? ?? '',
    defaultPage: json['defaultPage'] as String? ?? 'home',
    flightApi: json['flightApi'] as String? ?? '',
    memberProfile: json['memberProfile'] as String? ?? '',
    memberApi: json['memberApi'] as String? ?? '',
    cashCardApi: json['cashCardApi'] as String? ?? '',
    printHubEndpoint: json['printHubEndpoint'] as String? ?? '',
    pickupCode: json['pickupCode'] as String? ?? '',
    isAirportMpos: json['isAirportMpos'] as bool? ?? false,
  );
}
