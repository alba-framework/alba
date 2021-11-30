import 'package:alba/src/framework/env.dart';
import 'package:flutter_test/flutter_test.dart';

var envFile = 'STRING_VARIABLE=hello\n'
    'STRING_WITH_SPACES_VARIABLE=hello world\n'
    'TRUE_VARIABLE=true\n'
    'FALSE_VARIABLE=false\n';

void main() {
  group('EnvironmentManager', () {
    setUp(() {
      EnvironmentManager().testLoad(envFile);
    });

    test('is a singleton', () {
      var instanceA = EnvironmentManager();
      var instanceB = EnvironmentManager();

      expect(instanceA, instanceB);
    });

    test('gets a string environment variable', () {
      var variable = EnvironmentManager().get('STRING_VARIABLE');

      expect(variable, 'hello');
    });

    test('gets a string with spaces environment variable', () {
      var variable = EnvironmentManager().get('STRING_WITH_SPACES_VARIABLE');

      expect(variable, 'hello world');
    });

    test('gets a boolean true variable', () {
      var variable = EnvironmentManager().get('TRUE_VARIABLE');

      expect(variable, true);
    });

    test('gets a boolean false variable', () {
      var variable = EnvironmentManager().get('FALSE_VARIABLE');

      expect(variable, false);
    });
  });

  group('env()', () {
    setUp(() {
      EnvironmentManager().testLoad(envFile);
    });

    test('gets a variable', () {
      var variable = env('STRING_VARIABLE');

      expect(variable, 'hello');
    });
  });
}
