/// Static app-level credentials the legacy client sends on every request
/// (see `api-contracts.md` section 2 — `TokenInterceptor`). These are
/// transport-level app authentication, separate from the per-user session
/// key.
///
/// Their literal values were not discoverable from the client source
/// (`smart-pos-mobile/src/constants/constants.ts` was out of scope for the
/// migration inventory) and MUST be obtained from King Power before any
/// network call can succeed against a real backend. Do not fabricate values
/// here — leave them empty until the real ones are provided.
class AppConstants {
  const AppConstants._();

  /// TODO(migration): obtain from King Power — default bearer token sent to
  /// Sale Engine/Register/Flight/Print Hub/Cash Card.
  static const String appToken = '';

  /// TODO(migration): obtain from King Power — default `CallerID` header.
  static const String callerId = '';

  /// TODO(migration): obtain from King Power — bearer token used only for
  /// Member-domain (`api/Member/*`) calls.
  static const String appTokenMember = '';

  /// TODO(migration): obtain from King Power — `CallerID` used only for
  /// Member-domain calls.
  static const String callerIdMember = '';
}
