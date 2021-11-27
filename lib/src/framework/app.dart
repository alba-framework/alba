import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';

import '../../routing.dart';
import '../core/error.dart';

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
    restorationScopeId: restorationScopeId,
    appProviders: appProviders,
    routerRootConfiguration: routerRootConfiguration,
  );

  return _instance!;
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

  /// The identifier to use for state restoration of this app.
  ///
  /// Providing a restoration ID inserts a [RootRestorationScope] into the
  /// widget hierarchy, which enables state restoration for descendant widgets.
  final String? restorationScopeId;

  /// The router root configuration.
  ///
  /// Setting it enables the router.
  final RouterRootConfiguration? routerRootConfiguration;

  /// The root router delegate.
  PageRouterDelegate? _pageRouterDelegate;

  /// The root router information parser.
  PageRouteInformationParser? _pageRouteInformationParser;

  /// Creates an [App].
  App._({
    required this.widget,
    this.restorationScopeId,
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
  PageRouterDelegate? get pageRouterDelegate => _pageRouterDelegate;

  /// The root router information parser.
  PageRouteInformationParser? get pageRouteInformationParser =>
      _pageRouteInformationParser;

  /// Runs the app.
  Future<void> run() async {
    await _boot();

    runApp(_createChild());
  }

  /// Boots the app and the providers.
  Future<void> _boot() async {
    for (var boot in appProviders ?? []) {
      await boot.boot(serviceLocator);
    }
  }

  Widget _createChild() {
    var child = widget;

    if (null != routerRootConfiguration) {
      child = RouterRoot(
        configuration: routerRootConfiguration!,
        builder: (
          BuildContext context,
          PageRouterDelegate pageRouterDelegate,
          PageRouteInformationParser pageRouteInformationParser,
        ) {
          _routerInitialized(
            pageRouterDelegate,
            pageRouteInformationParser,
          );

          return widget;
        },
      );
    }

    return RootRestorationScope(
      restorationId: restorationScopeId,
      child: child,
    );
  }

  /// Saves router's delegate and information parser instances.
  void _routerInitialized(
    PageRouterDelegate pageRouterDelegate,
    PageRouteInformationParser? pageRouteInformationParser,
  ) {
    _pageRouterDelegate = pageRouterDelegate;
    _pageRouteInformationParser = pageRouteInformationParser;
  }
}
