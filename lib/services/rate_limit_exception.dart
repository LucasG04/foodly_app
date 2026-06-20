class RateLimitException implements Exception {
  final int retryAfterSeconds;

  const RateLimitException({required this.retryAfterSeconds});

  @override
  String toString() =>
      'RateLimitException: retry after $retryAfterSeconds seconds';
}
