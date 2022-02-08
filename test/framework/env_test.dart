import 'package:alba/src/framework/env.dart';
import 'package:flutter_test/flutter_test.dart';

var environment = '''
STRING_VARIABLE=hello
STRING_WITH_SPACES_VARIABLE=hello world
TRUE_VARIABLE=true
FALSE_VARIABLE=false
''';

void main() {
  group('EnvironmentManager', () {
    setUp(() {
      testLoad(environment);
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
      testLoad(environment);
    });

    test('gets a variable', () {
      var variable = env('STRING_VARIABLE');

      expect(variable, 'hello');
    });
  });
}
