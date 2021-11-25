import 'package:flutter/foundation.dart';

import 'route_definition.dart';

/// An information about an active page.
@immutable
class ActivePage {
  /// The route definition.
  final RouteDefinition routeDefinition;

  /// The current page path.
  final String currentPath;

  /// The developer-defined id.
  final String? id;

  /// The page index
  final int index;

  /// Creates a [ActivePage]
  const ActivePage(this.routeDefinition, this.currentPath, this.index,
      {this.id});

  /// The page restoration id.
  String get key => 'pi+$index';

  /// The page restoration id.
  String get restorationId => key;

  /// The page name.
  String get name => '$key+$currentPath';

  /// Extracts the parameters for the current path.
  Map<String, String> get parameters => routeDefinition.parameters(currentPath);
}
