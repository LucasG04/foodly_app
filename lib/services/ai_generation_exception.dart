/// Thrown before any stream content is received when the server rejects the
/// input as not food-related (HTTP 422), e.g. with code `NOT_FOOD_RELATED`.
class AIRejectionException implements Exception {
  final String code;

  const AIRejectionException(this.code);

  @override
  String toString() => 'AIRejectionException($code)';
}

/// Generic failure before the stream starts (HTTP 400, other non-200, or a
/// transport error). Failures that occur mid-stream are delivered as an
/// [ErrorEvent] instead so partial content survives.
class ApiException implements Exception {
  final String message;

  const ApiException(this.message);

  @override
  String toString() => 'ApiException($message)';
}
