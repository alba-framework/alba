import 'package:shared_preferences/shared_preferences.dart';

import '../../framework.dart';
import 'key_value_store.dart';

/// A provider for storage services.
class StorageProvider implements AppProvider {
  @override
  Future<void> boot(ServiceLocator serviceLocator) async {
    serviceLocator.registerSingleton<KeyValueStore>(
      KeyValueStore(await SharedPreferences.getInstance()),
    );
  }
}
