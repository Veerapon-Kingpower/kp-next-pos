/// One entry of the legacy `list_authorize` permission grant — a module,
/// an action within it, and an auth code. See `ShareDataProvider.canDoIt`
/// in the legacy client for how these gate UI actions.
class AuthorizedAction {
  final String moduleCode;
  final String authCode;
  final String action;

  const AuthorizedAction({
    required this.moduleCode,
    required this.authCode,
    required this.action,
  });
}
