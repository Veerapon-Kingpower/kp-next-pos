/// Data-layer exceptions. Thrown by data sources (API clients, local
/// storage, hardware adapters) and caught at the repository boundary, where
/// they are mapped to a [Failure] (see `failure.dart`) for the domain/
/// presentation layers to consume.
class ApiException implements Exception {
  final String messageDesc;
  final String? messageCode;

  const ApiException({required this.messageDesc, this.messageCode});

  @override
  String toString() => 'ApiException($messageCode: $messageDesc)';
}

class CacheException implements Exception {
  final String message;

  const CacheException(this.message);

  @override
  String toString() => 'CacheException($message)';
}

class DeviceException implements Exception {
  final String message;

  const DeviceException(this.message);

  @override
  String toString() => 'DeviceException($message)';
}
