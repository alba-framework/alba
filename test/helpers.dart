/// A simple spy for tracking calls.
///
/// Tracks how many times [call] method is called.
class Spy {
  int _times = 0;

  void call() {
    _times++;
  }

  bool get called => 0 < _times;

  int get times => _times;
}
