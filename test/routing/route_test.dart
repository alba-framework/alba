import 'package:alba/routing.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RouteDefinition', () {
    test('matches a path', () {
      var routeDefinition =
          RouteDefinition('/my/route', (context, parameters) => Container());

      expect(routeDefinition.match('/my/route'), true);
      expect(routeDefinition.match('/my/route/'), true);
      expect(routeDefinition.match('/MY/ROUTE'), true);
      expect(routeDefinition.match('/my/route/something-more'), false);
      expect(routeDefinition.match('/other_path'), false);
    });

    test('matches a path with parameters', () {
      var routeDefinition = RouteDefinition(
          '/user/:user/details', (context, parameters) => Container());

      expect(routeDefinition.match('/user/1234/details'), true);
      expect(routeDefinition.match('/user/abcd/details'), true);
      expect(routeDefinition.match('/user//details'), false);
    });
  });

  group('ActiveRoute', () {
    test('gets parameters', () {
      var activeRoute = ActiveRoute(
        RouteDefinition(
            '/info/:user/:article', (context, parameters) => Container()),
        '/info/1234/abcd',
        1,
      );

      expect(activeRoute.parameters, {'user': '1234', 'article': 'abcd'});
    });
  });
}
