import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DialogRoute, MaterialPage;
import 'package:path_to_regexp/path_to_regexp.dart';
import 'package:rxdart/rxdart.dart';

import '../../framework.dart';
import '../framework/pipeline.dart';

/// A route middleware
typedef Middleware = PipelineHandler<RouteDefinition>;

/// A signature for a function that creates a route [Widget].
typedef RouteWidgetBuilder = Widget Function(
  BuildContext context,
  Map<String, String> parameters,
  Map<String, String> query,
);

/// A signature for a function that creates a router [Page].
typedef RouterPageBuilder = Page Function(
  BuildContext context,
  PageWrapper pageWrapper,
);

/// A route that should behave like a dialog.
abstract class RouteDialogBehavior {}

/// A dialog page.
class DialogPage<T> extends Page<T> {
  /// The content to be shown in the [Route] created by this page.
  final Widget child;

  /// Creates a [DialogPage].
  const DialogPage({
    required this.child,
    LocalKey? key,
    String? name,
    Object? arguments,
    String? restorationId,
  }) : super(
          key: key,
          name: name,
          arguments: arguments,
          restorationId: restorationId,
        );

  @override
  Route<T> createRoute(BuildContext context) {
    return DialogRoute<T>(
      context: context,
      builder: (_) => child,
      settings: this,
    );
  }
}

/// Utility to add a trailing slash to a path.
String _addTrailingSlash(String path) {
  if ('/' == path[path.length - 1]) {
    return path;
  }

  return '$path/';
}

/// A router configuration.
///
/// Used by [AlbaRouteInformationParser] to restore state.
class RouterConfiguration {
  final List<RouteInfo> _routesInfo;

  /// Creates a [RouterConfiguration].
  RouterConfiguration(this._routesInfo);

  /// Transform routes information to [RouteInformation].
  RouteInformation toRouteInformation() {
    return RouteInformation(
      location: _routesInfo.last.path,
      state: _routesInfo.map((routeInfo) => routeInfo.toMap()).toList(),
    );
  }

  /// Creates an instance from [RouteInformation].
  RouterConfiguration.fromRouteInformation(RouteInformation routeInformation)
      : _routesInfo = List<dynamic>.from(routeInformation.state as List)
            .map((entry) => Map<String, dynamic>.from(entry))
            .map((routeInfo) => RouteInfo.fromMap(routeInfo))
            .toList();
}

/// A route info.
class RouteInfo {
  /// Route path.
  final String path;

  /// Creates a [RouteInfo].
  RouteInfo({required this.path});

  /// Converts it to a [Map].
  Map<String, dynamic> toMap() {
    return {'path': path};
  }

  /// Creates an instance from a [Map].
  RouteInfo.fromMap(Map<String, dynamic> map) : path = map['path'];
}

/// A router state.
///
/// Keeps router state.
class RouterState with ChangeNotifier {
  final List<RouteDefinition> _routeDefinitions;

  final String _notFoundPath;

  final GlobalKey<NavigatorState> _navigatorKey;

  final List<PageWrapper> _pageStack = [];

  /// Creates a [RouterState].
  RouterState({
    required List<RouteDefinition> routeDefinitions,
    required String notFoundPath,
    required GlobalKey<NavigatorState> navigatorKey,
  })  : _routeDefinitions = routeDefinitions,
        _notFoundPath = notFoundPath,
        _navigatorKey = navigatorKey;

  /// The routes index.
  ///
  /// Use [_nextRouteIndex] for getting the next index.
  int _routeIndex = 0;

  /// The next page index.
  int get _nextRouteIndex => ++_routeIndex;

  /// Gets the current path.
  String get currentPath => _pageStack.last.path;

  /// Builds pages for using in [Navigator].
  List<Page<dynamic>> _buildPages(BuildContext context) =>
      _pageStack.map((page) => page.getOrBuildPage(context)).toList();

  NavigatorState get _navigatorState => _navigatorKey.currentState!;

  /// A stream controller for router events.
  final _routerEventsController = BehaviorSubject<RouterEvent>();

  /// Router event stream.
  ValueStream<RouterEvent> get eventStream => _routerEventsController.stream;

  /// Finds a route definition for a path.
  ///
  /// [isNotFound] argument is used internally to stop recursion when the
  /// searched route is the `not found`.
  RouteDefinition _findRouteDefinition(
    String path, {
    bool isNotFound = false,
  }) {
    final routeDefinition = _routeDefinitions.firstWhere(
      (routeDefinition) => routeDefinition.match(path),
      orElse: () {
        if (isNotFound) {
          throw AlbaError('Path $path not found. Is it registered?\n');
        }

        return _findRouteDefinition(_notFoundPath, isNotFound: true);
      },
    );

    return routeDefinition;
  }

  /// Finds a [PageWrapper] for a path.
  PageWrapper? _findPageWrapper(String path) {
    for (var i = _pageStack.length - 1; i >= 0; i--) {
      var pageWrapper = _pageStack[i];

      if (pageWrapper.path == path) {
        return pageWrapper;
      }
    }

    return null;
  }

  void _processMiddlewares(
    RouteDefinition routeDefinition,
    void Function(RouteDefinition routeDefinition) then,
  ) {
    pipeline(
      routeDefinition,
      routeDefinition.middlewares,
      then,
    );
  }

  /// Sets the initial path.
  void _initial(String path) {
    final routeDefinition = _findRouteDefinition(path);
    final page = PageWrapper(routeDefinition, path, _nextRouteIndex);

    _pageStack.clear();
    _pageStack.add(page);

    notifyListeners();
  }

  /// Restores pages from [RouterConfiguration].
  void _restore(RouterConfiguration routerConfiguration) {
    _pageStack.clear();

    for (var routeInfo in routerConfiguration._routesInfo) {
      final routeDefinition = _findRouteDefinition(routeInfo.path);
      final page =
          PageWrapper(routeDefinition, routeInfo.path, _nextRouteIndex);
      _pageStack.add(page);
    }

    notifyListeners();
  }

  /// Pushes a new page by path.
  ///
  /// [id] is used to match listeners.
  ///
  /// Process route middlewares before push.
  void push(String path, {String? id}) {
    final routeDefinition = _findRouteDefinition(path);

    _processMiddlewares(
      routeDefinition,
      (RouteDefinition routeDefinition) {
        final page =
            PageWrapper(routeDefinition, path, _nextRouteIndex, id: id);
        _pageStack.add(page);
        notifyListeners();
        _notifyPush(page);
      },
    );
  }

  /// Pops the top-most route.
  Future<bool> pop<T extends Object?>([T? result]) async {
    return _navigatorState.maybePop(result);
  }

  /// Pops all the previous routes until the [predicate] returns true.
  void popUntil(bool Function(PageWrapper pageWrapper) predicate) async {
    for (var index = _pageStack.length - 1;
        index > 0 && !predicate(_pageStack[index]);
        index--) {
      _navigatorState.pop();
    }
  }

  /// Replace the current route by a new one by path.
  ///
  /// [id] is used to match listeners.
  ///
  /// Process route middlewares before replace.
  void replace(String path, {String? id}) {
    final routeDefinition = _findRouteDefinition(path);

    _processMiddlewares(
      routeDefinition,
      (RouteDefinition routeDefinition) {
        final page =
            PageWrapper(routeDefinition, path, _nextRouteIndex, id: id);
        final oldPage = _pageStack.removeLast();
        _pageStack.add(page);
        notifyListeners();
        _notifyReplace(page, oldPage);
      },
    );
  }

  /// Removes a route by path.
  void remove(String path) {
    final pageWrapper = _findPageWrapper(path);
    _pageStack.remove(pageWrapper);
    notifyListeners();
  }

  /// Removes all routes then pushes a new page by path.
  ///
  /// [id] is used to match listeners.
  ///
  /// Process route middlewares before remove.
  void removeAllAndPush(String path, {String? id}) {
    final routeDefinition = _findRouteDefinition(path);

    _processMiddlewares(
      routeDefinition,
      (RouteDefinition routeDefinition) {
        final page =
            PageWrapper(routeDefinition, path, _nextRouteIndex, id: id);
        _pageStack.clear();
        _pageStack.add(page);
        notifyListeners();
        _notifyPush(page);
      },
    );
  }

  /// Removes all the previous routes until the [predicate] returns true.
  ///
  /// [id] is used to match listeners.
  ///
  /// Process route middlewares before remove.
  void removeUntilAndPush(
    bool Function(PageWrapper pageWrapper) predicate,
    String path, {
    String? id,
  }) {
    final routeDefinition = _findRouteDefinition(path);

    _processMiddlewares(
      routeDefinition,
      (RouteDefinition routeDefinition) {
        for (var index = _pageStack.length - 1;
            index >= 0 && !predicate(_pageStack[index]);
            index--) {
          _pageStack.removeAt(index);
        }

        final page =
            PageWrapper(routeDefinition, path, _nextRouteIndex, id: id);
        _pageStack.add(page);
        notifyListeners();
        _notifyPush(page);
      },
    );
  }

  /// Removes last page.
  ///
  /// Called internally when the [Navigator] calls `onPopPage` callback.
  void _onPop<T extends Object?>(T result) {
    final page = _pageStack.removeLast();
    notifyListeners();
    _notifyPop(page, result);
  }

  /// Notifies a push event.
  void _notifyPush(PageWrapper pageWrapper) {
    _routerEventsController.sink.add(PushEvent(pageWrapper));
  }

  /// Notifies a pop event.
  void _notifyPop<T extends Object?>(PageWrapper pageWrapper, T result) {
    _routerEventsController.sink.add(PopEvent(pageWrapper, result));
  }

  /// Notifies a replace event.
  void _notifyReplace(PageWrapper pageWrapper, PageWrapper oldPageWrapper) {
    _routerEventsController.sink.add(ReplaceEvent(pageWrapper, oldPageWrapper));
  }

  /// Returns the [Widget] of the nearest [Page] the is an instance
  /// of the given type `T`.
  T? findWidget<T extends Widget>() {
    for (var pageWrapper in _pageStack.reversed) {
      final page = pageWrapper.pageOrNull;

      if (page is MaterialPage && page.child is T) {
        return page.child as T;
      }

      if (page is CupertinoPage && page.child is T) {
        return page.child as T;
      }

      if (page is DialogPage && page.child is T) {
        return page.child as T;
      }
    }

    return null;
  }

  @override
  void dispose() {
    super.dispose();
    _routerEventsController.close();
  }
}

/// A router delegate.
class AlbaRouterDelegate extends RouterDelegate<RouterConfiguration>
    with ChangeNotifier {
  final RouterState _routerState;

  /// The key used for [Navigator].
  final GlobalKey<NavigatorState> _navigatorKey;

  /// The key used for [Router].
  final GlobalKey<RouterWidgetState>? _routerKey;

  final List<NavigatorObserver> Function()? _observers;

  /// The initial path when there isn't any page.
  final String Function()? _initialPath;

  /// Creates a [AlbaRouterDelegate].
  AlbaRouterDelegate({
    required RouterState routerState,
    GlobalKey<RouterWidgetState>? routerKey,
    String Function()? initialPath,
    List<NavigatorObserver> Function()? observers,
  })  : _routerState = routerState,
        _navigatorKey = routerState._navigatorKey,
        _routerKey = routerKey,
        _initialPath = initialPath,
        _observers = observers {
    _routerState.addListener(() {
      notifyListeners();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Router(
      key: _routerKey,
      state: _routerState,
      navigatorKey: _navigatorKey,
      observers: _observers ?? () => [],
    );
  }

  @override
  Future<bool> popRoute() {
    return _routerState.pop();
  }

  @override
  Future<void> setInitialRoutePath(RouterConfiguration configuration) {
    var path = configuration._routesInfo.first.path;

    if (_initialPath != null && path == Navigator.defaultRouteName) {
      path = _initialPath!();
    }

    _routerState._initial(path);

    return Future.value();
  }

  @override
  Future<void> setNewRoutePath(RouterConfiguration configuration) {
    _routerState.push(configuration._routesInfo.first.path);

    return Future.value();
  }

  @override
  Future<void> setRestoredRoutePath(RouterConfiguration configuration) {
    _routerState._restore(configuration);

    return Future.value();
  }

  @override
  RouterConfiguration? get currentConfiguration {
    return RouterConfiguration(_routerState._pageStack
        .map((page) => RouteInfo(path: page.path))
        .toList());
  }
}

/// A router information parser.
class AlbaRouteInformationParser
    extends RouteInformationParser<RouterConfiguration> {
  @override
  Future<RouterConfiguration> parseRouteInformation(
      RouteInformation routeInformation) {
    if (routeInformation.state != null) {
      return SynchronousFuture(
          RouterConfiguration.fromRouteInformation(routeInformation));
    }

    return SynchronousFuture(
        RouterConfiguration([RouteInfo(path: routeInformation.location!)]));
  }

  @override
  RouteInformation restoreRouteInformation(RouterConfiguration configuration) {
    return configuration.toRouteInformation();
  }
}

/// A widget that manages routes and pages though the [Navigator].
///
/// [Router.of] operates on the nearest ancestor [Router] from the
/// given [BuildContext]. Be sure to provide a [BuildContext] below the
/// intended [Router].
class Router extends StatefulWidget {
  /// The router state.
  final RouterState _state;

  /// The key used for [Navigator].
  final GlobalKey<NavigatorState> _navigatorKey;

  /// A list of observers for this [Router].
  final List<NavigatorObserver> Function() _observers;

  /// Creates a [Router].
  const Router({
    required RouterState state,
    required GlobalKey<NavigatorState> navigatorKey,
    required List<NavigatorObserver> Function() observers,
    Key? key,
  })  : _state = state,
        _navigatorKey = navigatorKey,
        _observers = observers,
        super(key: key);

  @override
  State<Router> createState() => RouterWidgetState();

  /// The state from the closest instance of this class that encloses the given
  /// context.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// Router.of(context).push('/my/path');
  /// ```
  ///
  /// If there is no [Router] in the give `context`, this function will
  /// throw a [AlbaError] in debug mode, and an exception in release mode.
  ///
  /// This method can be expensive (it walks the element tree).
  static RouterWidgetState of(BuildContext context) {
    var routerState = context.findRootAncestorStateOfType<RouterWidgetState>();

    assert(() {
      if (routerState == null) {
        throw AlbaError(
            'Router operation requested with a context that does not include a Router.\n');
      }
      return true;
    }());

    return routerState!;
  }
}

/// A state for a [Router] widget.
///
/// A reference to this class can be obtained by calling [Router.of].
class RouterWidgetState extends State<Router> {
  /// Gets the current path.
  String get currentPath => widget._state.currentPath;

  /// Router event stream.
  ValueStream<RouterEvent> get eventStream => widget._state.eventStream;

  /// Pushes a new page by path.
  ///
  /// [id] is used to match listeners.
  void push(String path, {String? id}) {
    widget._state.push(path, id: id);
  }

  /// Pops the top-most route.
  Future<bool> pop<T extends Object?>([T? result]) {
    return widget._state.pop(result);
  }

  /// Pops all the previous routes until the [predicate] returns true.
  void popUntil(bool Function(PageWrapper pageWrapper) predicate) {
    return widget._state.popUntil(predicate);
  }

  /// Replace the current route by a new one by path.
  ///
  /// [id] is used to match listeners.
  ///
  /// Process route middlewares before replace.
  void replace(String path, {String? id}) {
    widget._state.replace(path, id: id);
  }

  /// Removes a route by path.
  void remove(String path) {
    widget._state.remove(path);
  }

  /// Removes all routes then pushes a new page by path.
  ///
  /// [id] is used to match listeners.
  ///
  /// Process route middlewares before remove.
  void removeAllAndPush(String path, {String? id}) {
    widget._state.removeAllAndPush(path, id: id);
  }

  /// Removes all the previous routes until the [predicate] returns true.
  ///
  /// [id] is used to match listeners.
  ///
  /// Process route middlewares before remove.
  void removeUntilAndPush(
    bool Function(PageWrapper pageWrapper) predicate,
    String path, {
    String? id,
  }) {
    widget._state.removeUntilAndPush(predicate, path, id: id);
  }

  /// Returns the [Widget] of the nearest [Page] that is an instance
  /// of the given type `T`.
  T? findWidget<T extends Widget>() {
    return widget._state.findWidget<T>();
  }

  @override
  Widget build(BuildContext context) {
    final pages = widget._state._buildPages(context);

    return Navigator(
      restorationScopeId: 'navigator',
      key: widget._navigatorKey,
      observers: widget._observers(),
      pages: pages,
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }

        widget._state._onPop(result);

        return true;
      },
    );
  }
}

/// Default page builder.
///
/// If widget implements [RouteDialogBehavior] it builds a [DialogPage],
/// in another case it build a [MaterialPage].
Page defaultPageBuilder(
  BuildContext context,
  PageWrapper pageWrapper,
) {
  Widget widget = pageWrapper.buildWidget(context);

  if (widget is RouteDialogBehavior) {
    return DialogPage(
      key: ValueKey(pageWrapper.key),
      restorationId: pageWrapper.restorationId,
      name: pageWrapper.name,
      arguments: {
        'path': pageWrapper.path,
        'parameters': pageWrapper.parameters,
      },
      child: widget,
    );
  }

  return MaterialPage(
    key: ValueKey(pageWrapper.key),
    restorationId: pageWrapper.restorationId,
    name: pageWrapper.name,
    arguments: {
      'path': pageWrapper.path,
      'parameters': pageWrapper.parameters,
    },
    child: widget,
  );
}

/// A route definition.
@immutable
class RouteDefinition {
  /// The path.
  final String _path;

  /// The name.
  final String? name;

  /// The widget builder.
  final RouteWidgetBuilder widgetBuilder;

  /// The page builder.
  final RouterPageBuilder pageBuilder;

  /// The route middlewares.
  final List<Middleware> Function()? _middlewares;

  /// The generated regex to test if a path match.
  late final RegExp _pathRegex;

  /// The route parameters
  late final List<String> _parametersNames;

  /// Creates a [RouteDefinition].
  ///
  /// For a dialog, [isDialog] must be true to work properly.
  RouteDefinition(
    String path,
    this.widgetBuilder, {
    this.name,
    this.pageBuilder = defaultPageBuilder,
    List<Middleware> Function()? middlewares,
  })  : _path = _addTrailingSlash(path),
        _middlewares = middlewares {
    _parametersNames = [];
    _pathRegex = pathToRegExp(
      _path,
      parameters: _parametersNames,
      caseSensitive: false,
    );
  }

  /// Gets the route middlewares.
  List<Middleware> get middlewares =>
      _middlewares != null ? _middlewares!() : [];

  /// Tests if a path match.
  bool match(String path) {
    final preparedPath = _addTrailingSlash(Uri.parse(path).path);
    return _pathRegex.hasMatch(preparedPath);
  }

  /// Extracts the parameters for a path.
  Map<String, String> _parameters(String path) {
    final match =
        _pathRegex.matchAsPrefix(_addTrailingSlash(Uri.parse(path).path));

    if (null == match) {
      return {};
    }

    return extract(_parametersNames, match);
  }
}

/// A [Page] wrapper.
class PageWrapper {
  /// The route definition.
  final RouteDefinition _routeDefinition;

  /// The current page path.
  final String path;

  /// The page index
  final int index;

  /// The page id.
  final String? id;

  /// The page name.
  final String? name;

  /// The path uri
  final Uri _uri;

  /// The built page.
  Page<dynamic>? _page;

  /// Creates a [PageWrapper].
  PageWrapper(
    RouteDefinition routeDefinition,
    this.path,
    this.index, {
    this.id,
  })  : _uri = Uri.parse(path),
        _routeDefinition = routeDefinition,
        name = routeDefinition.name;

  /// The page restoration id.
  String get key => 'pi+$index';

  /// The page restoration id.
  String get restorationId => key;

  /// The page if it's already built.
  Page? get pageOrNull => _page;

  /// Extracts the parameters from the current path.
  Map<String, String> get parameters => _routeDefinition._parameters(path);

  /// Extracts the query from the current path.
  Map<String, String> get query => _uri.queryParameters;

  /// Build the widget.
  Widget buildWidget(BuildContext context) =>
      _routeDefinition.widgetBuilder(context, parameters, query);

  /// Build the page.
  Page<dynamic> getOrBuildPage(BuildContext context) {
    _page ??= _routeDefinition.pageBuilder(context, this);

    return _page!;
  }
}

/// A router event.
class RouterEvent {
  /// Target page.
  final PageWrapper pageWrapper;

  /// Creates a [RouterEvent].
  RouterEvent(this.pageWrapper);
}

/// A router pop event.
class PopEvent<T extends Object?> extends RouterEvent {
  /// The page result.
  final T result;

  /// Creates a [PopEvent].
  PopEvent(PageWrapper pageWrapper, this.result) : super(pageWrapper);
}

/// A router push event.
class PushEvent extends RouterEvent {
  /// Creates a [PushEvent].
  PushEvent(PageWrapper pageWrapper) : super(pageWrapper);
}

/// A router push event.
class ReplaceEvent extends RouterEvent {
  /// Old page.
  final PageWrapper oldPageWrapper;

  /// Creates a [ReplaceEvent].
  ReplaceEvent(PageWrapper pageWrapper, this.oldPageWrapper)
      : super(pageWrapper);
}

/// A router builder.
class RouterBuilder extends StatefulWidget {
  /// The app/router builder.
  final Widget Function(AlbaRouterDelegate routerDelegate,
      AlbaRouteInformationParser routeInformationParser) builder;

  /// The route definitions.
  final List<RouteDefinition> routeDefinitions;

  /// The key used for [Navigator].
  final GlobalKey<NavigatorState> navigatorKey;

  /// The key used for [Router].
  final GlobalKey<RouterWidgetState>? routerKey;

  /// The path when a page is not found.
  final String notFoundPath;

  /// The initial path when there isn't any page.
  final String Function()? initialPath;

  /// The navigator observers.
  final List<NavigatorObserver> Function()? observers;

  /// Creates a [RouterBuilder].
  RouterBuilder({
    required this.builder,
    required this.routeDefinitions,
    GlobalKey<NavigatorState>? navigatorKey,
    this.routerKey,
    this.notFoundPath = '/not-found',
    this.initialPath,
    this.observers,
    Key? key,
  })  : navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>(),
        super(key: key);

  @override
  State<RouterBuilder> createState() => _RouterBuilderState();
}

class _RouterBuilderState extends State<RouterBuilder> {
  late final RouterState _routerState;

  @override
  void initState() {
    super.initState();

    _routerState = RouterState(
      routeDefinitions: widget.routeDefinitions,
      notFoundPath: widget.notFoundPath,
      navigatorKey: widget.navigatorKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      AlbaRouterDelegate(
        routerState: _routerState,
        routerKey: widget.routerKey,
        initialPath: widget.initialPath,
        observers: widget.observers,
      ),
      AlbaRouteInformationParser(),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _routerState.dispose();
  }
}
