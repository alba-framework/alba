import 'package:flutter/widgets.dart';

import '../route_definition.dart';
import '../router_state.dart';
import 'page_router.dart';

/// A signature for a function that creates the root.
typedef _RouterRootWidgetBuilder = Widget Function(
  BuildContext context,
  PageRouterDelegate pageRouterDelegate,
  PageRouteInformationParser pageRouteInformationParser,
);

/// A router root configuration.
class RouterRootConfiguration {
  /// The definition of routes.
  final List<RouteDefinition> routeDefinitions;

  /// The key used for [Navigator].
  final GlobalKey<NavigatorState>? navigatorKey;

  /// The initial path when there isn't any page.
  final String initialPath;

  /// The not found path.
  final String notFoundPath;

  /// Creates a [RouterRootConfiguration].
  RouterRootConfiguration({
    required this.routeDefinitions,
    this.initialPath = '/',
    this.notFoundPath = '/not-found',
    GlobalKey<NavigatorState>? navigatorKey,
  }) : navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>();
}

/// A root router widget.
class RouterRoot extends StatefulWidget {
  /// The router configuration.
  final RouterRootConfiguration configuration;

  /// The router root builder.
  final _RouterRootWidgetBuilder builder;

  /// Creates a [RouterRoot].
  const RouterRoot({
    required this.configuration,
    required this.builder,
    Key? key,
  }) : super(key: key);

  @override
  State<RouterRoot> createState() => _RouterRootState();
}

class _RouterRootState extends State<RouterRoot> {
  late final PageRouteInformationParser _pageRouteInformationParser;

  late final RouterState _routerState;

  late final PageRouterDelegate _pageRouterDelegate;

  @override
  void initState() {
    super.initState();

    _pageRouteInformationParser = PageRouteInformationParser();
    _routerState = RouterState(
      routeDefinitions: widget.configuration.routeDefinitions,
      initialPath: widget.configuration.initialPath,
      notFoundPath: widget.configuration.notFoundPath,
    );
    _pageRouterDelegate = PageRouterDelegate(
      routerState: _routerState,
      navigatorKey: widget.configuration.navigatorKey,
    );
  }

  @override
  void dispose() {
    super.dispose();
    _routerState.clean();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      _pageRouterDelegate,
      _pageRouteInformationParser,
    );
  }
}

/// A router delegate for the app.
class PageRouterDelegate extends RouterDelegate<String>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<String> {
  final RouterState _routerState;

  final GlobalKey<NavigatorState>? _navigatorKey;

  /// Creates a [PageRouterDelegate]
  PageRouterDelegate({
    required RouterState routerState,
    required GlobalKey<NavigatorState>? navigatorKey,
  })  : _routerState = routerState,
        _navigatorKey = navigatorKey;

  @override
  GlobalKey<NavigatorState>? get navigatorKey => _navigatorKey;

  @override
  String get currentConfiguration {
    return _routerState.currentPath();
  }

  @override
  Future<void> setInitialRoutePath(String configuration) async {
    // Do nothing. The initial route is already created.
  }

  @override
  Future<void> setNewRoutePath(String configuration) async {
    // TODO (web)
  }

  @override
  Future<void> setRestoredRoutePath(String configuration) {
    // TODO (web)
    return super.setRestoredRoutePath(configuration);
  }

  @override
  Widget build(BuildContext context) {
    return PageRouter(
      navigatorKey: navigatorKey,
      routerState: _routerState,
      notifyDelegate: () => notifyListeners(),
    );
  }
}

/// A router information parser for the app.
class PageRouteInformationParser extends RouteInformationParser<String> {
  @override
  Future<String> parseRouteInformation(
    RouteInformation routeInformation,
  ) async {
    return routeInformation.location ?? '';
  }

  @override
  RouteInformation restoreRouteInformation(String configuration) {
    return RouteInformation(location: configuration);
  }
}
