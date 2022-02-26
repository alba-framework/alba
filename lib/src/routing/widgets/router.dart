import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';

import '../../../routing.dart';
import '../../framework/error.dart';
import '../restoration.dart';
import '../router.dart';

/// A widget that manages routes and pages though the [Navigator].
///
/// [Router.of] operates on the nearest ancestor [Router] from the
/// given [BuildContext]. Be sure to provide a [BuildContext] below the
/// intended [Router].
class Router extends StatefulWidget {
  final AlbaRouter _albaRouter;

  final void Function() _notifyDelegate;

  /// The key used for [Navigator].
  final GlobalKey<NavigatorState>? _navigatorKey;

  /// A list of observers for this [Router].
  ///
  /// [NavigatorObserver.didRemove] and [NavigatorObserver.didReplace]
  /// are not fired.
  final List<NavigatorObserver> Function()? _observers;

  /// Creates a [Router].
  const Router({
    required AlbaRouter albaRouter,
    required void Function() notifyDelegate,
    GlobalKey<NavigatorState>? navigatorKey,
    List<NavigatorObserver> Function()? observers,
    Key? key,
  })  : _navigatorKey = navigatorKey,
        _observers = observers,
        _albaRouter = albaRouter,
        _notifyDelegate = notifyDelegate,
        super(key: key);

  @override
  RouterState createState() => RouterState();

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
  /// throw a [RouterError] in debug mode, and an exception in release mode.
  ///
  /// This method can be expensive (it walks the element tree).
  static RouterState of(BuildContext context) {
    var _routerState = context.findRootAncestorStateOfType<RouterState>();

    assert(() {
      if (_routerState == null) {
        throw AlbaError(
            'Router operation requested with a context that does not include a Router.\n');
      }
      return true;
    }());

    return _routerState!;
  }
}

/// The state for a [Router] widget.
///
/// A reference to this class can be obtained by calling [Router.of].
class RouterState extends State<Router> with RestorationMixin {
  final RestorablePageInformationList _restorablePages =
      RestorablePageInformationList();

  final Map<String, Page> _pagesCache = {};

  Map<String, Page> _pages = {};

  @override
  String? get restorationId => 'page_router';

  @override
  void initState() {
    super.initState();
    _syncPages();

    widget._albaRouter.addListener(() {
      setState(() {
        _syncPages();
        _syncRestorablePages();
      });
    });
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_restorablePages, 'restorable_pages');

    if (_restorablePages.value.isEmpty) {
      _syncRestorablePages();
    } else {
      widget._albaRouter.restorePages(_restorablePages);
      _syncPages();
    }
  }

  /// The current path.
  String get currentPath {
    return widget._albaRouter.currentPath;
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      restorationScopeId: 'navigator',
      key: widget._navigatorKey,
      observers: widget._observers != null ? widget._observers!() : [],
      pages: _pages.values.toList(),
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }

        widget._albaRouter.popByRoute(route, result);
        widget._notifyDelegate();

        return true;
      },
    );
  }

  /// Pushes a new route.
  void push(String path, {String? id}) {
    widget._albaRouter.push(path, id);
    widget._notifyDelegate();
  }

  /// Removes all and pushes a new route.
  void removeAllAndPush(String path, {String? id}) {
    widget._albaRouter.removeAllAndPush(path, id);
    widget._notifyDelegate();
  }

  /// Removes all the previous routes until the [predicate] returns true.
  void removeUntilAndPush(
    bool Function(ActiveRoute activeRoute) predicate,
    String path, {
    String? id,
  }) {
    widget._albaRouter.removeUntilAndPush(predicate, path, id);
    widget._notifyDelegate();
  }

  /// Replace the current route by a new one.
  void replace(String path, {String? id}) {
    widget._albaRouter.replace(path, id);
    widget._notifyDelegate();
  }

  /// Pops the current route.
  void pop<T extends Object?>([T? result]) {
    widget._albaRouter.pop(result);
    widget._notifyDelegate();
  }

  /// Removes a route.
  void removeRoute(String path) {
    widget._albaRouter.removeRoute(path);
  }

  void _syncPages() {
    Map<String, Page> newPages = {};

    for (var activePage in widget._albaRouter.activeRoutes) {
      if (!_pagesCache.containsKey(activePage.key)) {
        _pagesCache[activePage.key] = activePage.buildPage(context);
      }

      newPages[activePage.key] = _pagesCache[activePage.key]!;
    }

    _pages = newPages;
  }

  void _syncRestorablePages() {
    _restorablePages.value = widget._albaRouter.activeRoutes
        .map((activePage) =>
            RestorablePageInformation.fromActivePage(activePage))
        .toList();
  }

  /// Router event stream.
  ValueStream<RouterEvent> get eventStream => widget._albaRouter.eventStream;
}
