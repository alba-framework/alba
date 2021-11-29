class CommandError implements Exception {
  final String message;

  CommandError(this.message);

  @override
  String toString() => 'Error: $message';
}