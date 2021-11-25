/// Error class used to report router-specific assertion failures and
/// contract violations.
class RouterError extends Error {
  final String _message;

  /// Creates an error from a string.
  RouterError(String message) : _message = message;

  @override
  String toString() => _message;
}