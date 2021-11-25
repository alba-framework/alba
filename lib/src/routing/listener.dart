import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'active_page.dart';

/// A pop event callback.
///
/// The type argument `T` is the page's result type.
typedef PopEventCallback<T> = void Function(ActivePage activePage, T? result);

/// The base for page listener definitions.
@immutable
abstract class PageListenerDefinition<T> {
  final PopEventCallback<T> _onPop;

  /// Creates a [PageListenerDefinition]
  const PageListenerDefinition({
    required PopEventCallback<T> onPop,
  }) : _onPop = onPop;

  /// Notify pop event to the defined callback.
  void notifyPop(ActivePage pageInfo, T result) => _onPop(pageInfo, result);

  /// Test if the page matches.
  bool isMatch(ActivePage pageInfo);
}

/// Page listener definition that mach against a path.
class PathPageListenerDefinition<T> extends PageListenerDefinition<T> {
  final String _path;

  /// Creates a [PathPageListenerDefinition].
  const PathPageListenerDefinition({
    required String path,
    required PopEventCallback<T> onPop,
  })  : _path = path,
        super(onPop: onPop);

  @override
  bool isMatch(ActivePage pageInfo) => _path == pageInfo.currentPath;
}

/// Page listener definition that mach against an id.
class IdPageListenerDefinition<T> extends PageListenerDefinition<T> {
  final String _id;

  /// Creates a [IdPageListenerDefinition].
  const IdPageListenerDefinition({
    required String id,
    required PopEventCallback<T> onPop,
  })  : _id = id,
        super(onPop: onPop);

  @override
  bool isMatch(ActivePage pageInfo) => _id == pageInfo.id;
}

/// Page listener definition that mach against several paths and ids.
class MultiPageListenerDefinition<T> extends PageListenerDefinition<T> {
  final List<String>? _paths;
  final List<String>? _ids;

  /// Creates a [MultiPageListenerDefinition].
  const MultiPageListenerDefinition({
    required List<String>? paths,
    required List<String>? ids,
    required PopEventCallback<T> onPop,
  })  : _paths = paths,
        _ids = ids,
        super(onPop: onPop);

  @override
  bool isMatch(ActivePage pageInfo) =>
      (null != _paths && _paths!.any((path) => path == pageInfo.currentPath)) ||
      (null != _ids && _ids!.any((id) => id == pageInfo.id));
}
