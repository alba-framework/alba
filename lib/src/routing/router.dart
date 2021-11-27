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
    String notFoundPath = '/404',
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

    activeRoutes.add(activeRoute);

    WidgetsBinding.instance
        ?.addPostFrameCallback((_) => _notifyPush(activeRoute));
  }

  /// Pops a route.
  void pop(Route route, dynamic result) {
    for (var i = activeRoutes.length - 1; i >= 0; i--) {
      var activePage = activeRoutes[i];

      if (activePage.name == route.settings.name) {
        activeRoutes.removeAt(i);

        WidgetsBinding.instance
            ?.addPostFrameCallback((_) => _notifyPop(activePage, result));

        break;
      }
    }
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

  /// Notifies a push event.
  void _notifyPush(ActiveRoute activeRoute) {
    _routerEventsController.sink.add(PushEvent(activeRoute));
  }

  /// Notifies a pop event.
  void _notifyPop(ActiveRoute activeRoute, dynamic result) {
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
class PopEvent extends RouterEvent {
  /// The page result.
  final dynamic result;

  /// Creates a [PopEvent].
  PopEvent(ActiveRoute activeRoute, this.result) : super(activeRoute);
}

/// A router push event.
class PushEvent extends RouterEvent {
  /// Creates a [PushEvent].
  PushEvent(ActiveRoute activeRoute) : super(activeRoute);
}
