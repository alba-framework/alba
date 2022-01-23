import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';

import '../framework/error.dart';
import 'restoration.dart';
import 'route.dart';

/// A router.
class AlbaRouter {
  /// The routes index.
  ///
  /// Use [_nextRouteIndex] for getting the next index.
  int _routeIndex = 0;

  /// The definition of routes.
  final List<RouteDefinition> routeDefinitions;

  /// The active routes.
  List<ActiveRoute> activeRoutes = [];

  /// The not found route.
  late final RouteDefinition _notFoundRoute;

  /// A stream controller for router events.
  final _routerEventsController = BehaviorSubject<RouterEvent>();

  /// Creates [AlbaRouter].
  AlbaRouter({
    required this.routeDefinitions,
    String notFoundPath = '/not-found',
    String initialPath = '/',
  }) {
    activeRoutes = [
      ActiveRoute(
        _findRouteDefinition(initialPath),
        initialPath,
        _nextRouteIndex,
        id: 'initial',
      )
    ];

    _notFoundRoute = _findRouteDefinition(notFoundPath, isNotFound: true);
  }

  /// Gets the current path.
  String get currentPath => activeRoutes.last.path;

  /// The event stream.
  ValueStream<RouterEvent> get eventStream => _routerEventsController.stream;

  /// The next page index.
  int get _nextRouteIndex => ++_routeIndex;

  /// Frees memory, closes streams, and so on...
  void clean() {
    _routerEventsController.close();
  }

  /// Pushes a new page by path.
  ///
  /// [id] is used to match listeners.
  void push(String path, String? id) {
    var routeDefinition = _findRouteDefinition(path);
    var activeRoute =
        ActiveRoute(routeDefinition, path, _nextRouteIndex, id: id);

    _push(activeRoute);
  }

  /// Pops the top-most route.
  void pop<T extends Object?>([T? result]) {
    var activeRoute = activeRoutes.isEmpty ? null : activeRoutes.last;
    _pop(activeRoute!, result);
  }

  /// Pops a specific route by `Route`.
  void popByRoute<T extends Object?>(Route route, [T? result]) {
    var activeRoute = _findActiveRouteByRoute(route);
    _pop(activeRoute!, result);
  }

  /// Removes a route by path.
  void removeRoute(String path) {
    var activeRoute = _findActiveRouteByPath(path);
    _remove(activeRoute!);
  }

  /// Finds a route definition for a path.
  RouteDefinition _findRouteDefinition(String path, {bool isNotFound = false}) {
    var routeDefinition = routeDefinitions.firstWhere(
      (routeDefinition) => routeDefinition.match(path),
      orElse: () {
        if (isNotFound) {
          throw AlbaError('Path $path not found. Is it registered?\n');
        }

        return _notFoundRoute;
      },
    );

    return routeDefinition;
  }

  ActiveRoute? _findActiveRouteByRoute(Route route) {
    for (var i = activeRoutes.length - 1; i >= 0; i--) {
      var activeRoute = activeRoutes[i];

      if (activeRoute.name == route.settings.name) {
        return activeRoute;
      }
    }

    return null;
  }

  ActiveRoute? _findActiveRouteByPath(String path) {
    for (var i = activeRoutes.length - 1; i >= 0; i--) {
      var activeRoute = activeRoutes[i];

      if (activeRoute.path == path) {
        return activeRoute;
      }
    }

    return null;
  }

  void _push(ActiveRoute? activeRoute) {
    assert(null != activeRoute);

    activeRoutes.add(activeRoute!);

    WidgetsBinding.instance
        ?.addPostFrameCallback((_) => _notifyPush(activeRoute));
  }

  void _pop<T extends Object?>(ActiveRoute? activeRoute, T? result) {
    assert(null != activeRoute);

    if (1 == activeRoutes.length) {
      SystemNavigator.pop();
      return;
    }

    activeRoutes.remove(activeRoute);

    WidgetsBinding.instance
        ?.addPostFrameCallback((_) => _notifyPop(activeRoute!, result));
  }

  void _remove<T extends Object?>(ActiveRoute? activeRoute) {
    assert(null != activeRoute);

    activeRoutes.remove(activeRoute);
  }

  /// Notifies a push event.
  void _notifyPush(ActiveRoute activeRoute) {
    _routerEventsController.sink.add(PushEvent(activeRoute));
  }

  /// Notifies a pop event.
  void _notifyPop<T extends Object?>(ActiveRoute activeRoute, T result) {
    _routerEventsController.sink.add(PopEvent(activeRoute, result));
  }

  /// Restores pages.
  void restorePages(RestorablePageInformationList restorablePages) {
    activeRoutes = restorablePages.value
        .map(
          (restorablePageInformation) => ActiveRoute(
            _findRouteDefinition(restorablePageInformation.path),
            restorablePageInformation.path,
            restorablePageInformation.index,
            id: restorablePageInformation.id,
          ),
        )
        .toList();

    _routeIndex = activeRoutes.last.index + 1;
  }
}

/// A router event.
class RouterEvent {
  /// Target page.
  final ActiveRoute activeRoute;

  /// Creates a [RouterEvent].
  RouterEvent(this.activeRoute);
}

/// A router pop event.
class PopEvent<T extends Object?> extends RouterEvent {
  /// The page result.
  final T result;

  /// Creates a [PopEvent].
  PopEvent(ActiveRoute activeRoute, this.result) : super(activeRoute);
}

/// A router push event.
class PushEvent extends RouterEvent {
  /// Creates a [PushEvent].
  PushEvent(ActiveRoute activeRoute) : super(activeRoute);
}
