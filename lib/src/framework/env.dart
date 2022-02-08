import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:meta/meta.dart';

/// Gets an env variable.
dynamic env(String key, {dynamic defaultValue}) =>
    EnvironmentManager().get(key);

/// Load environment for testing.
@visibleForTesting
void testLoad(String environment) {
  EnvironmentManager().testLoad(environment);
}

/// An environment manager.
///
/// It loads and gives environment variables.
class EnvironmentManager {
  static final EnvironmentManager _instance = EnvironmentManager._internal();

  static final DotEnv _dotEnv = DotEnv();

  /// Gives the [EnvironmentManager] instance.
  factory EnvironmentManager() => _instance;

  EnvironmentManager._internal() {
    //
  }

  /// Loads the file.
  Future<void> load() async {
    await _dotEnv.load(
      fileName: '.env',
      parser: const Parser(),
    );
  }

  /// Loads the environment from a [String] for testing purposes.
  @visibleForTesting
  void testLoad(String fileInput) {
    _dotEnv.testLoad(
      fileInput: fileInput,
      parser: const Parser(),
    );
  }

  /// Gets the value for an environment variable.
  dynamic get(String key) {
    String? value = _dotEnv.env[key];

    if (value is String && value.toLowerCase() == 'true') {
      return true;
    }

    if (value is String && value.toLowerCase() == 'false') {
      return false;
    }

    return value;
  }
}
