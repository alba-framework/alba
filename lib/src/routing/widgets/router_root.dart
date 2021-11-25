import 'package:flutter/widgets.dart';

import '../route_definition.dart';
import '../router_state.dart';
import 'page_router.dart';

/// A signature for a function that creates the root.
typedef _RouterRootWidgetBuilder = Widget Function(
  BuildContext context,
  String? restorationScopeId,
  _PageRouterDelegate pageRouterDelegate,
  _PageRouteInformationParser pageRouteInformationParser,
);

/// A root router widget.
class RouterRoot extends StatefulWidget {
  /// The definition of routes.
  final List<RouteDefinition> routeDefinitions;

  /// The router root builder
  final _RouterRootWidgetBuilder builder;

  /// The identifier to use for state restoration of this app.
  ///
  /// Providing a restoration ID inserts a [RootRestorationScope] into the
  /// widget hierarchy, which enables state restoration for descendant widgets.
  final String? restorationScopeId;

  /// The key used for [Navigator].
  final GlobalKey<NavigatorState>? navigatorKey;

  /// The initial path when there isn't any page.
  final String initialPath;

  /// The not found path.
  final String notFoundPath;

  /// Creates a [RouterRoot].
  const RouterRoot({
    required this.routeDefinitions,
    required this.builder,
    required this.navigatorKey,
    this.restorationScopeId,
    this.initialPath = '/',
    this.notFoundPath = '/not-found',
    Key? key,
  }) : super(key: key);

  @override
  State<RouterRoot> createState() => _RouterRootState();
}

class _RouterRootState extends State<RouterRoot> {
  late final _PageRouteInformationParser _pageRouteInformationParser;

  late final RouterState _routerState;

  late final _PageRouterDelegate _pageRouterDelegate;

  @override
  void initState() {
    super.initState();

    _pageRouteInformationParser = _PageRouteInformationParser();
    _routerState = RouterState(
      routeDefinitions: widget.routeDefinitions,
      initialPath: widget.initialPath,
      notFoundPath: widget.notFoundPath,
    );
    _pageRouterDelegate = _PageRouterDelegate(
      routerState: _routerState,
      navigatorKey: widget.navigatorKey,
    );
  }

  @override
  void dispose() {
    super.dispose();
    _routerState.clean();
  }

  @override
  Widget build(BuildContext context) {
    return RootRestorationScope(
      restorationId: widget.restorationScopeId,
      child: widget.builder(
        context,
        '${widget.restorationScopeId}_app',
        _pageRouterDelegate,
        _pageRouteInformationParser,
      ),
    );
  }
}

/// A router delegate for the app.
class _PageRouterDelegate extends RouterDelegate<String>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<String> {
  final RouterState _routerState;

  final GlobalKey<NavigatorState>? _navigatorKey;

  /// Creates a [_PageRouterDelegate]
  _PageRouterDelegate({
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
class _PageRouteInformationParser extends RouteInformationParser<String> {
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
