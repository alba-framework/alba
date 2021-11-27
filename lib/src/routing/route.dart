import 'package:alba/framework.dart';
import 'package:flutter/material.dart' show MaterialPage, DialogRoute;
import 'package:flutter/widgets.dart' hide Router;
import 'package:path_to_regexp/path_to_regexp.dart';

import '../../routing.dart';

/// A signature for a function that creates a route [Widget].
typedef RouteWidgetBuilder = Widget Function(
  BuildContext context,
  Map<String, String> parameters,
);

/// A signature for a function that creates a router [Page].
typedef RouterPageBuilder = Page Function(
  BuildContext context,
  ActiveRoute activeRoute,
);

String _addTrailingSlash(String path) {
  if ('/' == path[path.length - 1]) {
    return path;
  }

  return '$path/';
}

/// A route definition for [Router].
@immutable
class RouteDefinition {
  /// The path.
  final String _path;

  /// The builder.
  final RouteWidgetBuilder widgetBuilder;

  /// The builder.
  final RouterPageBuilder pageBuilder;

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
    this.pageBuilder = defaultPageBuilder,
  }) : _path = _addTrailingSlash(path) {
    _parametersNames = [];
    _pathRegex = pathToRegExp(
      _path,
      parameters: _parametersNames,
      caseSensitive: false,
    );
  }

  /// Tests if a path match.
  bool match(String path) {
    return _pathRegex.hasMatch(_addTrailingSlash(path));
  }

  /// Extracts the parameters for a path.
  Map<String, String> parameters(String path) {
    final match = _pathRegex.matchAsPrefix(_addTrailingSlash(path));

    if (null == match) {
      throw AlbaError('Route does not match.');
    }

    return extract(_parametersNames, match); // => {'id': '12'}
  }
}

/// Default page builder.
///
/// If widget implements [RouteDialogBehavior] it builds a [DialogPage],
/// in another case it build a [MaterialPage].
Page defaultPageBuilder(
  BuildContext context,
  ActiveRoute activeRoute,
) {
  Widget widget = activeRoute.buildWidget(context, activeRoute.parameters);

  if (widget is RouteDialogBehavior) {
    return DialogPage(
      key: ValueKey(activeRoute.key),
      restorationId: activeRoute.restorationId,
      name: activeRoute.name,
      child: widget,
    );
  }

  return MaterialPage(
    key: ValueKey(activeRoute.key),
    restorationId: activeRoute.restorationId,
    name: activeRoute.name,
    child: widget,
  );
}

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

/// A route that should behave like a dialog.
abstract class RouteDialogBehavior {}

/// An information about an active route.
@immutable
class ActiveRoute {
  /// The route definition.
  final RouteDefinition _definition;

  /// The current page path.
  final String path;

  /// The page index
  final int index;

  /// The developer-defined id.
  final String? id;

  /// Creates an [ActiveRoute].
  const ActiveRoute(RouteDefinition routeDefinition, this.path, this.index,
      {this.id})
      : _definition = routeDefinition;

  /// The page restoration id.
  String get key => 'pi+$index';

  /// The page restoration id.
  String get restorationId => key;

  /// The page name.
  String get name => '$key+$path';

  /// Extracts the parameters for the current path.
  Map<String, String> get parameters => _definition.parameters(path);

  /// Build the widget.
  Widget buildWidget(BuildContext context, Map<String, String> parameters) =>
      _definition.widgetBuilder(context, parameters);

  /// Build the page.
  Page buildPage(BuildContext context) =>
      _definition.pageBuilder(context, this);
}
