import 'package:flutter/material.dart' show MaterialPage, DialogRoute;
import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';

import '../active_page.dart';
import '../restoration.dart';
import '../router_error.dart';
import '../router_state.dart';

/// A widget that manages routes and pages though the [Navigator].
///
/// [PageRouter.of] operates on the nearest ancestor [PageRouter] from the
/// given [BuildContext]. Be sure to provide a [BuildContext] below the
/// intended [PageRouter].
class PageRouter extends StatefulWidget {
  final RouterState _routerState;

  final void Function() _notifyDelegate;

  /// The key used for [Navigator].
  final GlobalKey<NavigatorState>? _navigatorKey;

  /// Creates a [PageRouter].
  const PageRouter({
    required RouterState routerState,
    required void Function() notifyDelegate,
    GlobalKey<NavigatorState>? navigatorKey,
    Key? key,
  })  : _navigatorKey = navigatorKey,
        _routerState = routerState,
        _notifyDelegate = notifyDelegate,
        super(key: key);

  @override
  PageRouterState createState() => PageRouterState();

  /// The state from the closest instance of this class that encloses the given
  /// context.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// PageRouter.of(context).push('/my/path');
  /// ```
  ///
  /// If there is no [PageRouter] in the give `context`, this function will
  /// throw a [RouterError] in debug mode, and an exception in release mode.
  ///
  /// This method can be expensive (it walks the element tree).
  static PageRouterState of(BuildContext context) {
    var _routerState = context.findRootAncestorStateOfType<PageRouterState>();

    assert(() {
      if (_routerState == null) {
        throw RouterError(
            'Router operation requested with a context that does not include a Router.\n');
      }
      return true;
    }());

    return _routerState!;
  }
}

/// The state for a [PageRouter] widget.
///
/// A reference to this class can be obtained by calling [PageRouter.of].
class PageRouterState extends State<PageRouter> with RestorationMixin {
  final RestorablePageInformationList _restorablePages =
      RestorablePageInformationList();

  @override
  String? get restorationId => 'page_router';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_restorablePages, 'restorable_pages');

    if (_restorablePages.value.isEmpty) {
      _syncRestorablePages();
    } else {
      widget._routerState.restorePages(_restorablePages);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      restorationScopeId: 'navigator',
      key: widget._navigatorKey,
      pages: [
        for (var activePage in widget._routerState.activePages)
          _buildPage(activePage)
      ],
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }

        widget._routerState.pop(route, result);
        _syncRestorablePages();
        widget._notifyDelegate();

        return true;
      },
    );
  }

  void _syncRestorablePages() {
    _restorablePages.value = widget._routerState.activePages
        .map((activePage) => RestorablePageInformation(
              path: activePage.currentPath,
              index: activePage.index,
              id: activePage.id,
            ))
        .toList();
  }

  Page _buildPage(ActivePage activePage) {
    if (activePage.routeDefinition.isDialog) {
      return _DialogPage(
        key: ValueKey(activePage.key),
        restorationId: activePage.restorationId,
        name: activePage.name,
        child:
            activePage.routeDefinition.builder(context, activePage.parameters),
      );
    }

    return MaterialPage(
      key: ValueKey(activePage.key),
      restorationId: activePage.restorationId,
      name: activePage.name,
      child: activePage.routeDefinition.builder(context, activePage.parameters),
    );
  }

  /// Adds new page.
  void push(String path, {String? id}) {
    widget._routerState.push(path, id);
    _syncRestorablePages();
    widget._notifyDelegate();
  }

  /// Router event stream.
  ValueStream<RouterEvent> get eventStream => widget._routerState.eventStream;
}

class _DialogPage<T> extends Page<T> {
  final Widget child;

  const _DialogPage({
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
