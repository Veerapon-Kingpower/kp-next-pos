/// Domain-level failure types, returned by repositories/use cases instead of
/// throwing. Mirrors the legacy app's `ReturnObject<T>` error shape
/// (`isCompleted`, `Message[0].MessageCode`/`MessageDesc`) so existing
/// server error codes/messages survive the migration — see
/// `openspec/changes/migrate-smart-pos-to-flutter/api-contracts.md` section 3.
sealed class Failure {
  final String message;

  const Failure(this.message);
}

/// The request reached the server, which reported a business-level failure
/// (`isCompleted == false`), or a per-field message the app should surface.
class ApiFailure extends Failure {
  final String? messageCode;

  const ApiFailure({required String messageDesc, this.messageCode})
    : super(messageDesc);
}

/// No connectivity, DNS failure, or the request could not be sent at all.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No network connection.']);
}

/// The request timed out waiting for a response — distinct from a definitive
/// server error, since (per design.md's checkout state machine) a timeout on
/// a payment-affecting call must be treated as unresolved, not failed.
class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'The request timed out.']);
}

/// A non-2xx HTTP response the app could not interpret as an `ApiFailure`.
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({required String message, this.statusCode})
    : super(message);
}

/// The static app-level bearer token / session key was rejected.
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Session is no longer valid.']);
}

/// A device/hardware peripheral operation failed (printer, EDC, signature
/// pad, card reader, AOT agent). Kept distinct from network failures since
/// hardware readiness is diagnosed and surfaced separately (see
/// `cross-platform-hardware` spec's hardware readiness requirement).
class DeviceFailure extends Failure {
  const DeviceFailure(super.message);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred.']);
}
