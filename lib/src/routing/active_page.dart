import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Page;
import 'package:flutter/widgets.dart';

import 'route.dart';

/// An information about an active page.
@immutable
class ActivePage {
  /// The route definition.
  final RouteDefinition _routeDefinition;

  /// The current page path.
  final String currentPath;

  /// The page index
  final int index;

  /// The developer-defined id.
  final String? id;

  /// Creates a [ActivePage].
  const ActivePage(
      RouteDefinition routeDefinition, this.currentPath, this.index,
      {this.id})
      : _routeDefinition = routeDefinition;

  /// The page restoration id.
  String get key => 'pi+$index';

  /// The page restoration id.
  String get restorationId => key;

  /// The page name.
  String get name => '$key+$currentPath';

  /// Extracts the parameters for the current path.
  Map<String, String> get parameters =>
      _routeDefinition.parameters(currentPath);

  /// Build the widget.
  Widget buildWidget(BuildContext context, Map<String, String> parameters) =>
      _routeDefinition.widgetBuilder(context, parameters);

  /// Build the page.
  Page buildPage(BuildContext context) =>
      _routeDefinition.pageBuilder(context, this);
}
