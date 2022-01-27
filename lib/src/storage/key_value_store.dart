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

  /// Creates an [KeyValueStore] instance.
  KeyValueStore(this._sharedPreferences);

  /// Retrieve a value by key.
  Future<T> get<T>(String key) {
    return Future.value(_sharedPreferences.get(key) as T);
  }

  /// Saves or replaces a value for a key.
  Future<void> set<T extends Object>(String key, T value) async {
    if (value is int) {
      await _sharedPreferences.setInt(key, value);
      return;
    }

    if (value is double) {
      await _sharedPreferences.setDouble(key, value);
      return;
    }

    if (value is bool) {
      await _sharedPreferences.setBool(key, value);
      return;
    }

    if (value is String) {
      await _sharedPreferences.setString(key, value);
      return;
    }

    throw ArgumentError('Type ${value.runtimeType} is not supported.');
  }

  /// Removes a value by key.
  Future<void> remove(String key) async {
    await _sharedPreferences.remove(key);
  }
}
