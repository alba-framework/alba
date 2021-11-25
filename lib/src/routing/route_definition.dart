import 'package:flutter/widgets.dart';
import 'package:path_to_regexp/path_to_regexp.dart';

/// A signature for a function that creates a page.
typedef PageBuilder = Widget Function(
  BuildContext context,
  Map<String, String> parameters,
);

/// A route definition for [PageRouter].
@immutable
class RouteDefinition {
  /// The path.
  final String path;

  /// The builder.
  final PageBuilder builder;

  /// True when route is a dialog.
  final bool isDialog;

  /// The generated regex to test if a path match.
  late final RegExp _pathRegex;

  /// The route parameters
  late final List<String> _parametersNames;

  /// Creates a [RouteDefinition].
  ///
  /// For a dialog, [isDialog] must be true to work properly.
  RouteDefinition(this.path, this.builder, {this.isDialog = false}) {
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
