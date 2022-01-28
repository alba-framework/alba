import 'package:shared_preferences/shared_preferences.dart';

/// A key-value store.
///
/// Keys are [String]s.
/// Accepts [int], [double], [bool] and [String] values.
///
/// It uses [shared_preferences](https://pub.dev/packages/shared_preferences)
/// package under the hood.
class KeyValueStore {
  final SharedPreferences _sharedPreferences;
  final String _prefix;

  /// Creates an [KeyValueStore] instance.
  KeyValueStore(this._sharedPreferences, [this._prefix = 'alba']);

  /// Retrieve a value by key.
  Future<T> get<T>(String key) {
    return Future.value(_sharedPreferences.get('${_prefix}_$key') as T);
  }

  /// Saves or replaces a value for a key.
  Future<void> set<T extends Object>(String key, T value) async {
    if (value is int) {
      await _sharedPreferences.setInt('${_prefix}_$key', value);
      return;
    }

    if (value is double) {
      await _sharedPreferences.setDouble('${_prefix}_$key', value);
      return;
    }

    if (value is bool) {
      await _sharedPreferences.setBool('${_prefix}_$key', value);
      return;
    }

    if (value is String) {
      await _sharedPreferences.setString('${_prefix}_$key', value);
      return;
    }

    throw ArgumentError('Type ${value.runtimeType} is not supported.');
  }

  /// Removes a value by key.
  Future<void> remove(String key) async {
    await _sharedPreferences.remove('${_prefix}_$key');
  }
}
