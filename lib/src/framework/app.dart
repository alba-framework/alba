import 'package:flutter/widgets.dart' hide Router;
import 'package:get_it/get_it.dart';

import '../routing/router.dart';
import 'env.dart';
import 'error.dart';
import 'error_handler.dart';

/// A service locator.
///
/// Alias for [GetIt]. It can be useful in the future.
typedef ServiceLocator = GetIt;

/// App provider.
abstract class AppProvider {
  /// Boot.
  Future<void> boot(ServiceLocator serviceLocator);
}

/// Gets app instance.
App app() {
  if (null == App._instance) {
    throw AlbaError('App is not created yet!');
  }

  return App._instance!;
}

/// An Application.
class App {
  static App? _instance;

  /// The service locator.
  final ServiceLocator serviceLocator = ServiceLocator.instance;

  /// The app widget.
  final Widget widget;

  /// The app providers.
  ///
  /// Useful to bootstrap, register or configure services.
  final List<AppProvider>? appProviders;

  /// The key used for [Navigator].
  final GlobalKey<NavigatorState> _navigatorKey;

  /// The error listeners.
  final List<ErrorListener> errorListeners;

  static bool _isTesting = false;

  static Future<void> Function(App)? _bootTesting;

  /// Creates an [App].
  App._({
    required this.widget,
    this.appProviders,
    GlobalKey<NavigatorState>? navigatorKey,
    this.errorListeners = const [],
  }) : _navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>();

  /// Creates the app.
  factory App.create({
    required Widget widget,
    List<AppProvider>? appProviders,
    GlobalKey<NavigatorState>? navigatorKey,
    List<ErrorListener>? errorListeners,
  }) {
    if (null != _instance) {
      throw AlbaError('App is already created!');
    }

    _instance = App._(
      widget: widget,
      appProviders: appProviders,
      navigatorKey: navigatorKey,
      errorListeners: errorListeners ?? [DebugErrorListener()],
    );

    return _instance!;
  }

  /// Return true if app is in testing mode.
  bool get isTesting => _isTesting;

  /// Set testing mode.
  ///
  /// It is useful for testing.
  @visibleForTesting
  static void setTesting() {
    _isTesting = true;
    ServiceLocator.instance.allowReassignment = true;
  }

  /// Define a closure to be run on boot when test mode is enabled.
  @visibleForTesting
  static void bootTesting(Future<void> Function(App) bootTesting) {
    _bootTesting = bootTesting;
  }

  /// Clears the app.
  ///
  /// It is useful for testing.
  @visibleForTesting
  static Future<void> clear() async {
    _instance = null;
    _isTesting = false;
    ServiceLocator.instance.allowReassignment = false;
    _bootTesting = null;
    await ServiceLocator.instance.reset();
  }

  /// The navigator key.
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;

  /// The navigator context.
  ///
  /// It is only defined when the router is active.
  ///
  /// Useful when context is necessary out of a widget.
  /// Use at your own risk.
  BuildContext? get navigatorContext => _navigatorKey.currentState?.context;

  /// The state of root router.
  ///
  /// Useful to navigate when the context isn't available.
  RouterWidgetState? get router =>
      navigatorContext != null ? Router.of(navigatorContext!) : null;

  /// Runs the app.
  Future<void> run() async {
    await _boot();

    // Not run in a guarded zone when testing.
    if (_isTesting) {
      runApp(widget);
      return;
    }

    ErrorHandler(errorListeners).run(() => runApp(widget));
  }

  /// Boots the app and the providers.
  Future<void> _boot() async {
    await _loadEnv();

    for (var appProvider in appProviders ?? []) {
      await appProvider.boot(serviceLocator);
    }

    if (_isTesting && _bootTesting != null) {
      await _bootTesting!(this);
    }
  }

  Future<void> _loadEnv() async {
    if (!_isTesting) {
      await EnvironmentManager().load();
    }
  }
}
