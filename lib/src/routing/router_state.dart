import 'package:flutter/widgets.dart';

import 'active_page.dart';
import 'listener.dart';
import 'restoration.dart';
import 'route_definition.dart';
import 'router_error.dart';

/// A router state.
///
/// It maintains the state of the router, like routes, active pages,
/// and so on...
class RouterState {
  /// The definition of routes.
  final List<RouteDefinition> routeDefinitions;

  /// The list of active pages.
  List<ActivePage> activePages = [];

  /// The not found page.
  late final RouteDefinition _notFoundRoute;

  /// The page listeners.
  final List<PageListenerDefinition> _pageListeners = [];

  /// The pages index.
  ///
  /// Use [_nextPageIndex] for getting the next index.
  int _pageIndex = 0;

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

  /// Push new page by path.
  ///
  /// [id] is used to match listeners.
  void push(String path, String? id) {
    var routeDefinition = _findRouteDefinition(path);
    var activePage = ActivePage(routeDefinition, path, _nextPageIndex, id: id);

    activePages.add(activePage);
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
          throw RouterError('Path $path not found. Is it registered?\n');
        }

        return _notFoundRoute;
      },
    );

    return routeDefinition;
  }

  /// Adds a page listener
  void addPageListener(PageListenerDefinition pageListener) {
    _pageListeners.add(pageListener);
  }

  /// Removes a page listener
  void removePageListener(PageListenerDefinition pageListener) {
    _pageListeners.remove(pageListener);
  }

  /// Notify a pop event to matched listeners.
  void _notifyPop(
    ActivePage activePage,
    dynamic result,
  ) {
    for (var pageListener in _pageListeners) {
      if (pageListener.isMatch(activePage)) {
        pageListener.notifyPop(activePage, result);
      }
    }
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
