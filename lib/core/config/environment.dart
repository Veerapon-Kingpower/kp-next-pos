/// Build-time environment configuration.
///
/// Selected at build/run time via `--dart-define=ENV=development|uat|production`
/// (defaults to `development`). Base URLs are sourced from the legacy app's
/// deploy configs (`smart-pos-mobile/jsonconfig/*.json`), documented in
/// `openspec/changes/migrate-smart-pos-to-flutter/api-contracts.md` section 1.
///
/// There is no separate legacy "development" backend — only UAT/SIT variants
/// per store and a single production. `development` currently points at the
/// same values as `uat` (`hq-uat`) as a placeholder; confirm with the open
/// question in `design.md` before treating any of this as final.
enum AppEnvironment { development, uat, production }

class EnvironmentConfig {
  final AppEnvironment environment;
  final String saleEngineEndpoint;
  final String webServiceEndpoint;
  final String flightApi;
  final String printHubEndpoint;
  final String memberApi;
  final String cashCardApi;

  const EnvironmentConfig({
    required this.environment,
    required this.saleEngineEndpoint,
    required this.webServiceEndpoint,
    required this.flightApi,
    required this.printHubEndpoint,
    required this.memberApi,
    required this.cashCardApi,
  });

  static const uat = EnvironmentConfig(
    environment: AppEnvironment.uat,
    saleEngineEndpoint:
        'https://uat-api-saleengine-hq.kingpower.com/SaleEngineAPI/api',
    webServiceEndpoint: 'https://uat-api2.kingpower.com/registerapi/api',
    flightApi: 'https://uat-api2.kingpower.com/flightapi/api',
    printHubEndpoint: 'http://printhub.kingpower.com',
    memberApi: 'https://uat-api2.kingpower.com/KPServicesapi',
    cashCardApi: 'https://uat-api2.kingpower.com/cashcardapi/api',
  );

  static const production = EnvironmentConfig(
    environment: AppEnvironment.production,
    saleEngineEndpoint: 'http://10.3.0.57/SaleEngineAPI/api',
    webServiceEndpoint: 'https://api2.kingpower.com/registerapi/api/',
    flightApi: 'https://api2.kingpower.com/flightapi/api',
    printHubEndpoint: 'http://printhub.kingpower.com',
    memberApi: 'https://api2.kingpower.com/KPServicesAPI',
    cashCardApi: 'https://api2.kingpower.com/CashCardAPI/api',
  );

  // Mirrors `uat` — no separate legacy "development" backend exists (see class doc comment).
  static const development = EnvironmentConfig(
    environment: AppEnvironment.development,
    saleEngineEndpoint:
        'https://uat-api-saleengine-hq.kingpower.com/SaleEngineAPI/api',
    webServiceEndpoint: 'https://uat-api2.kingpower.com/registerapi/api',
    flightApi: 'https://uat-api2.kingpower.com/flightapi/api',
    printHubEndpoint: 'http://printhub.kingpower.com',
    memberApi: 'https://uat-api2.kingpower.com/KPServicesapi',
    cashCardApi: 'https://uat-api2.kingpower.com/cashcardapi/api',
  );

  static const _envName = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );

  static AppEnvironment get _selected {
    switch (_envName) {
      case 'production':
        return AppEnvironment.production;
      case 'uat':
        return AppEnvironment.uat;
      case 'development':
      default:
        return AppEnvironment.development;
    }
  }

  static EnvironmentConfig get current {
    switch (_selected) {
      case AppEnvironment.production:
        return production;
      case AppEnvironment.uat:
        return uat;
      case AppEnvironment.development:
        return development;
    }
  }
}
