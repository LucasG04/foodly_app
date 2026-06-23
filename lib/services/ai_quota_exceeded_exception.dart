/// Thrown when the backend refuses a generate-meal request because the user's
/// AI usage quota for the current period is exhausted.
class AiQuotaExceededException implements Exception {
  const AiQuotaExceededException();
}
