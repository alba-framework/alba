import 'package:alba/src/storage/key_value_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> prepareSharedPreferences(
    Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);

  return SharedPreferences.getInstance();
}

void main() {
  group('KeyValueStore', () {
    tearDown(() async {
      await (await SharedPreferences.getInstance()).clear();
    });

    test('retrieves an int value', () async {
      var sharedPreferences =
          await prepareSharedPreferences(<String, Object>{'my_int': 223});
      var keyValueStore = KeyValueStore(sharedPreferences);

      int value = await keyValueStore.get('my_int');

      expect(value, 223);
    });

    test('retrieves an double value', () async {
      var sharedPreferences = await prepareSharedPreferences(
          <String, Object>{'my_double': 223.9992});
      var keyValueStore = KeyValueStore(sharedPreferences);

      double value = await keyValueStore.get('my_double');

      expect(value, 223.9992);
    });

    test('retrieves an bool value', () async {
      var sharedPreferences =
          await prepareSharedPreferences(<String, Object>{'my_bool': true});
      var keyValueStore = KeyValueStore(sharedPreferences);

      bool value = await keyValueStore.get('my_bool');

      expect(value, true);
    });

    test('retrieves an String value', () async {
      var sharedPreferences = await prepareSharedPreferences(<String, Object>{
        'my_string': 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.'
      });
      var keyValueStore = KeyValueStore(sharedPreferences);

      String value = await keyValueStore.get('my_string');

      expect(value, 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.');
    });

    test('saves an int value', () async {
      var keyValueStore = KeyValueStore(await SharedPreferences.getInstance());

      await keyValueStore.set('my_int', 223);

      expect(await keyValueStore.get('my_int'), 223);
    });

    test('saves an double value', () async {
      var keyValueStore = KeyValueStore(await SharedPreferences.getInstance());

      await keyValueStore.set('my_double', 223.9992);

      expect(await keyValueStore.get('my_double'), 223.9992);
    });

    test('saves an bool value', () async {
      var keyValueStore = KeyValueStore(await SharedPreferences.getInstance());

      await keyValueStore.set('my_bool', true);

      expect(await keyValueStore.get('my_bool'), true);
    });

    test('saves an String value', () async {
      var keyValueStore = KeyValueStore(await SharedPreferences.getInstance());

      await keyValueStore.set('my_string',
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit.');

      expect(await keyValueStore.get('my_string'),
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit.');
    });

    test('removes a value', () async {
      var sharedPreferences = await SharedPreferences.getInstance();
      var keyValueStore = KeyValueStore(sharedPreferences);
      await keyValueStore.set('my_value', 'something');

      await keyValueStore.remove('my_value');

      expect(await keyValueStore.get('my_value'), null);
    });
  });
}
