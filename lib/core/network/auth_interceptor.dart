import 'package:dio/dio.dart';

import '../config/app_constants.dart';

/// Ports `TokenInterceptor` from the legacy app (see `api-contracts.md`
/// section 2). Branches on the request URL, not on which feature issued the
/// call, matching the source app's behaviour exactly:
///
/// 1. `api/Member/` → Member-specific bearer token + CallerID.
/// 2. `identityserverapi/connect/token` → form-urlencoded only, no bearer
///    (this is the OAuth token *acquisition* call itself).
/// 3. `/api/OrderManagement/` → no-op; the caller sets its own bearer token
///    explicitly (see Order Gateway operations in `api-contracts.md`
///    section 11).
/// 4. Default → static app bearer token + CallerID + JSON headers.
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final url = options.uri.toString();

    if (url.contains('api/Member/')) {
      options.headers['Authorization'] =
          'Bearer ${AppConstants.appTokenMember}';
      options.headers['CallerID'] = AppConstants.callerIdMember;
    } else if (url.contains('identityserverapi/connect/token')) {
      options.contentType = Headers.formUrlEncodedContentType;
    } else if (url.contains('/api/OrderManagement/')) {
      // No-op: caller sets Authorization explicitly for Order Gateway calls.
    } else {
      options.headers['Accept'] = 'application/json';
      options.headers['Content-Type'] = 'application/json';
      options.headers['Authorization'] = 'Bearer ${AppConstants.appToken}';
      options.headers['CallerID'] = AppConstants.callerId;
      options.extra['withCredentials'] = true;
    }

    handler.next(options);
  }
}
