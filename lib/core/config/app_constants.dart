/// Static app-level credentials the legacy client sends on every request
/// (see `api-contracts.md` section 2 — `TokenInterceptor`). These are
/// transport-level app authentication, separate from the per-user session
/// key.
class AppConstants {
  const AppConstants._();

  /// Default bearer token sent to Sale Engine/Register/Flight/Print
  /// Hub/Cash Card.
  static const String appToken = 'e1f55e15a78d4a26ae2f9da21a6fab24';

  /// Default `CallerID` header.
  static const String callerId = 'KINGPOWER';

  /// TODO(migration): obtain from King Power — bearer token used only for
  /// Member-domain (`api/Member/*`) calls.
  static const String appTokenMember = '';

  /// TODO(migration): obtain from King Power — `CallerID` used only for
  /// Member-domain calls.
  static const String callerIdMember = '';
}
