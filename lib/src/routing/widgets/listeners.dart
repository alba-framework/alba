import 'package:flutter/widgets.dart';

import '../listener.dart';
import 'page_router.dart';

/// A listener for router events.
///
/// The type argument `T` is the page's result type, as used by [PopEventCallback].
/// The type `void` may be used if the route does not return a value.
abstract class PageListener<T> extends StatefulWidget {
  /// The callback which is called when a page is popped.
  final PopEventCallback<T> onPop;

  /// The widget below this widget in the tree.
  final Widget child;

  /// Creates a [PageListener].
  const PageListener({
    required this.onPop,
    required this.child,
    Key? key,
  }) : super(key: key);

  @override
  _PageListenerState<T> createState() => _PageListenerState<T>();

  /// Creates a page listener definition.
  PageListenerDefinition<T> createPageListenerDefinition();
}

class _PageListenerState<T> extends State<PageListener<T>> {
  late PageRouterState _pageRouterState;
  late final PageListenerDefinition<T> _listener =
      widget.createPageListenerDefinition();

  @override
  void initState() {
    super.initState();

    _pageRouterState = PageRouter.of(context)..addListener(_listener);
  }

  @override
  void dispose() {
    super.dispose();

    _pageRouterState.removeListener(_listener);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// A router listener for a specific page path.
class PathPageListener<T> extends PageListener<T> {
  final String _path;

  /// Creates a [PathPageListener].
  const PathPageListener({
    required PopEventCallback<T> onPop,
    required Widget child,
    required String path,
    Key? key,
  })  : _path = path,
        super(onPop: onPop, child: child, key: key);

  @override
  PageListenerDefinition<T> createPageListenerDefinition() {
    return PathPageListenerDefinition(
      path: _path,
      onPop: onPop,
    );
  }
}

/// A router listener for a specific page id.
class IdPageListener<T> extends PageListener<T> {
  final String _id;

  /// Creates a [IdPageListener].
  const IdPageListener({
    required PopEventCallback<T> onPop,
    required Widget child,
    required String id,
    Key? key,
  })  : _id = id,
        super(onPop: onPop, child: child, key: key);

  @override
  PageListenerDefinition<T> createPageListenerDefinition() {
    return IdPageListenerDefinition(
      id: _id,
      onPop: onPop,
    );
  }
}

/// A router listener for several page paths or page ids.
class MultiPageListener<T> extends PageListener<T> {
  final List<String>? _paths;
  final List<String>? _ids;

  /// Creates a [MultiPageListener].
  const MultiPageListener({
    required PopEventCallback<T> onPop,
    required Widget child,
    List<String>? paths,
    List<String>? ids,
    Key? key,
  })  : _paths = paths,
        _ids = ids,
        super(onPop: onPop, child: child, key: key);

  @override
  PageListenerDefinition<T> createPageListenerDefinition() {
    return MultiPageListenerDefinition(
      paths: _paths,
      ids: _ids,
      onPop: onPop,
    );
  }
}
