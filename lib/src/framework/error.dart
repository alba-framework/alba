/// Error class used to report core-specific assertion failures and
/// contract violations.
class AlbaError extends Error {
  final String _message;

  /// Creates an error from a string.
  AlbaError(String message) : _message = message;

  @override
  String toString() => _message;
}
