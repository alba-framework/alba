import 'package:flutter/material.dart' show MaterialPage, DialogRoute;
import 'package:flutter/widgets.dart';
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
  ActivePage activePage,
);

/// A route definition for [PageRouter].
@immutable
class RouteDefinition {
  /// The path.
  final String path;

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
    this.path,
    this.widgetBuilder, {
    this.pageBuilder = defaultPageBuilder,
  }) {
    _parametersNames = [];
    _pathRegex = pathToRegExp(
      path,
      parameters: _parametersNames,
      caseSensitive: false,
    );
  }

  /// Tests if a path match.
  bool match(String path) {
    return _pathRegex.hasMatch(path);
  }

  /// Extracts the parameters for a path.
  Map<String, String> parameters(String path) {
    final match = _pathRegex.matchAsPrefix(path);

    if (null == match) {
      return {};
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
  ActivePage activePage,
) {
  Widget widget = activePage.buildWidget(context, activePage.parameters);

  if (widget is RouteDialogBehavior) {
    return DialogPage(
      key: ValueKey(activePage.key),
      restorationId: activePage.restorationId,
      name: activePage.name,
      child: widget,
    );
  }

  return MaterialPage(
    key: ValueKey(activePage.key),
    restorationId: activePage.restorationId,
    name: activePage.name,
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
