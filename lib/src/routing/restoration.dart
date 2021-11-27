import 'package:flutter/widgets.dart';

import '../../routing.dart';

/// An list of information for restoring pages.
class RestorablePageInformationList
    extends RestorableValue<List<RestorablePageInformation>> {
  @override
  List<RestorablePageInformation> createDefaultValue() => [];

  @override
  void didUpdateValue(List<RestorablePageInformation>? oldValue) {
    notifyListeners();
  }

  @override
  List<RestorablePageInformation> fromPrimitives(Object? data) {
    return List<RestorablePageInformation>.from(
      (data as List).map(
            (primitive) =>
            RestorablePageInformation.fromPrimitives(
              List<String?>.from(primitive as List),
            ),
      ),
    ).toList();
  }

  @override
  Object? toPrimitives() =>
      value
          .map((restorablePageInformation) =>
          restorablePageInformation.toPrimitives())
          .toList();
}

/// An information for restoring a page.
class RestorablePageInformation {
  /// The page path.
  String path;

  /// The page index.
  int index;

  /// The page id.
  String? id;

  /// Creates a [RestorablePageInformation].
  RestorablePageInformation({
    required this.path,
    required this.index,
    this.id,
  });

  /// Restore information from primitive types.
  factory RestorablePageInformation.fromActivePage(ActiveRoute activeRoute) =>
      RestorablePageInformation(
        path: activeRoute.path,
        index: activeRoute.index,
        id: activeRoute.id,
      );

  /// Restore information from primitive types.
  factory RestorablePageInformation.fromPrimitives(Object? data) {
    var list = List<String?>.from(data as List);

    return RestorablePageInformation(
      path: list[0]!,
      index: int.parse(list[1]!),
      id: list[2],
    );
  }

  /// Transform information into primitive types.
  List<String?> toPrimitives() => [path, index.toString(), id];
}
