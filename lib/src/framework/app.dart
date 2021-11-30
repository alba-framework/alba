import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';

import '../../routing.dart';
import 'env.dart';
import 'error.dart';

/// A service locator.
///
/// Alias for [GetIt]. It can be useful in the future.
typedef ServiceLocator = GetIt;

/// App provider.
abstract class AppProvider {
  /// Boot.
  Future<void> boot(ServiceLocator serviceLocator);
}

/// The app instance.
App? _instance;

/// Flag to determine if the app is running in a testing environment.
bool _isTesting = false;

/// Gets app instance.
App app() {
  if (null == _instance) {
    throw AlbaError('App is not created yet!');
  }

  return _instance!;
}

/// Creates the app.
App createApp({
  required Widget widget,
  String? restorationScopeId,
  List<AppProvider>? appProviders,
  RouterRootConfiguration? routerRootConfiguration,
}) {
  if (null != _instance) {
    throw AlbaError('App is already created!');
  }

  _instance = App._(
    widget: widget,
    appProviders: appProviders,
    routerRootConfiguration: routerRootConfiguration,
  );

  return _instance!;
}

/// Set testing mode.
///
/// It is useful for testing.
@visibleForTesting
void setTesting() {
  _isTesting = true;
}

/// Clears the app.
///
/// It is useful for testing.
@visibleForTesting
void clearApp() {
  _instance = null;
  _isTesting = false;
}

/// An Application.
class App {
  /// The service locator.
  final ServiceLocator serviceLocator = ServiceLocator.instance;

  /// The app widget.
  final Widget widget;

  /// The app providers
  ///
  /// Useful to bootstrap, register or configure services.
  final List<AppProvider>? appProviders;

  /// The router root configuration.
  ///
  /// Setting it enables the router.
  final RouterRootConfiguration? routerRootConfiguration;

  /// The root router delegate.
  AlbaRouterDelegate? _pageRouterDelegate;

  /// The root router information parser.
  AlbaRouteInformationParser? _pageRouteInformationParser;

  /// Creates an [App].
  App._({
    required this.widget,
    this.appProviders,
    this.routerRootConfiguration,
  });

  /// The navigator context.
  ///
  /// It is only defined when the router is active.
  ///
  /// Useful when context is necessary out of a widget.
  /// Use at your own risk.
  BuildContext get navigatorContext =>
      routerRootConfiguration!.navigatorKey!.currentState!.context;

  /// The root router delegate.
  AlbaRouterDelegate? get pageRouterDelegate => _pageRouterDelegate;

  /// The root router information parser.
  AlbaRouteInformationParser? get pageRouteInformationParser =>
      _pageRouteInformationParser;

  /// Runs the app.
  Future<void> run() async {
    await _boot();

    runApp(_createChild());
  }

  /// Boots the app and the providers.
  Future<void> _boot() async {
    await _loadEnv();

    for (var boot in appProviders ?? []) {
      await boot.boot(serviceLocator);
    }
  }

  Future<void> _loadEnv() async {
    if (!_isTesting) {
      await EnvironmentManager().load();
    }
  }

  Widget _createChild() {
    var child = widget;

    if (null != routerRootConfiguration) {
      child = RouterRoot(
        configuration: routerRootConfiguration!,
        builder: (
          BuildContext context,
          AlbaRouterDelegate pageRouterDelegate,
          AlbaRouteInformationParser pageRouteInformationParser,
        ) {
          _routerInitialized(
            pageRouterDelegate,
            pageRouteInformationParser,
          );

          return widget;
        },
      );
    }

    return child;
  }

  /// Saves router's delegate and information parser instances.
  void _routerInitialized(
    AlbaRouterDelegate pageRouterDelegate,
    AlbaRouteInformationParser? pageRouteInformationParser,
  ) {
    _pageRouterDelegate = pageRouterDelegate;
    _pageRouteInformationParser = pageRouteInformationParser;
  }
}
