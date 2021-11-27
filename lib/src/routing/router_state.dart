import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';

import '../framework/error.dart';
import 'active_page.dart';
import 'restoration.dart';
import 'route.dart';

/// A router state.
///
/// It maintains the state of the router, like routes, active pages,
/// and so on...
class RouterState {
  /// The pages index.
  ///
  /// Use [_nextPageIndex] for getting the next index.
  int _pageIndex = 0;

  /// The definition of routes.
  final List<RouteDefinition> routeDefinitions;

  /// The list of active pages.
  List<ActivePage> activePages = [];

  /// The not found page.
  late final RouteDefinition _notFoundRoute;

  /// A stream controller for route events.
  final _routerEventsController = BehaviorSubject<RouterEvent>();

  /// Creates [RouterState]
  RouterState({
    required this.routeDefinitions,
    String notFoundPath = '/404',
    String initialPath = '/',
  }) {
    activePages = [
      ActivePage(
        _findRouteDefinition(initialPath),
        initialPath,
        _nextPageIndex,
        id: 'initial',
      )
    ];

    _notFoundRoute = _findRouteDefinition(notFoundPath, isNotFound: true);
  }

  /// The next page index
  int get _nextPageIndex {
    _pageIndex += 1;

    return _pageIndex;
  }

  /// The event stream.
  ValueStream<RouterEvent> get eventStream => _routerEventsController.stream;

  /// Frees memory, closes streams, and so on...
  void clean() {
    _routerEventsController.close();
  }

  /// Push new page by path.
  ///
  /// [id] is used to match listeners.
  void push(String path, String? id) {
    var routeDefinition = _findRouteDefinition(path);
    var activePage = ActivePage(routeDefinition, path, _nextPageIndex, id: id);

    activePages.add(activePage);

    WidgetsBinding.instance
        ?.addPostFrameCallback((_) => _notifyPush(activePage));
  }

  /// Pop a route.
  void pop(Route route, dynamic result) {
    for (var i = activePages.length - 1; i >= 0; i--) {
      var activePage = activePages[i];

      if (activePage.name == route.settings.name) {
        activePages.removeAt(i);

        WidgetsBinding.instance
            ?.addPostFrameCallback((_) => _notifyPop(activePage, result));

        break;
      }
    }
  }

  /// Get the current path.
  String currentPath() {
    return activePages.last.currentPath;
  }

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

  /// Notify a push event.
  void _notifyPush(ActivePage activePage) {
    _routerEventsController.sink.add(PushEvent(activePage));
  }

  /// Notify a pop event.
  void _notifyPop(ActivePage activePage, dynamic result) {
    _routerEventsController.sink.add(PopEvent(activePage, result));
  }

  /// Restore pages.
  void restorePages(RestorablePageInformationList restorablePages) {
    activePages = restorablePages.value
        .map(
          (restorablePageInformation) => ActivePage(
            _findRouteDefinition(restorablePageInformation.path),
            restorablePageInformation.path,
            restorablePageInformation.index,
            id: restorablePageInformation.id,
          ),
        )
        .toList();

    _pageIndex = activePages.last.index + 1;
  }
}

/// A router event.
class RouterEvent {
  /// Target page.
  final ActivePage activePage;

  /// Creates a [RouterEvent].
  RouterEvent(this.activePage);
}

/// A router pop event.
class PopEvent extends RouterEvent {
  /// The page result.
  final dynamic result;

  /// Creates a [PopEvent].
  PopEvent(ActivePage activePage, this.result) : super(activePage);
}

/// A router push event.
class PushEvent extends RouterEvent {
  /// Creates a [PushEvent].
  PushEvent(ActivePage activePage) : super(activePage);
}
