import 'dart:convert';
import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/network/api_client.dart';

/// Answers every request with `{}`, setting the ASP.NET session cookie on
/// the first one, and records the `Cookie` header each request carried.
class _SessionServer implements HttpClientAdapter {
  final List<String?> cookies = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    cookies.add(options.headers['cookie'] as String?);
    return ResponseBody.fromString(
      jsonEncode({}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        if (cookies.length == 1)
          'set-cookie': ['ASP.NET_SessionId=abc123; path=/; HttpOnly'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('sends the server session cookie back, as the legacy WebView does '
      '(Sale Engine "not found session" without it)', () async {
    final server = _SessionServer();
    final client = DioApiClient(cookieJar: CookieJar(), adapter: server);

    await client.post('https://pos.example/Login/Login');
    await client.post('https://pos.example/SaleEngine/GetOrder');

    expect(server.cookies.first, isNull);
    expect(server.cookies.last, 'ASP.NET_SessionId=abc123');
  });
}
