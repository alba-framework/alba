import 'package:alba/routing.dart';
import 'package:flutter/material.dart' hide Router;
import 'package:flutter/widgets.dart' hide Router;
import 'package:flutter_test/flutter_test.dart';

RouterRoot createRouter(WidgetBuilder homeScreenBuilder) {
  return RouterRoot(
    configuration: RouterRootConfiguration(
      routeDefinitions: [
        RouteDefinition(
          '/',
          (context, parameters) => homeScreenBuilder(context),
        ),
        RouteDefinition(
            '/screen-1', (context, parameters) => Container()),
        RouteDefinition(
            '/screen-2', (context, parameters) => Container()),
        RouteDefinition(
            '/screen-3', (context, parameters) => Container()),
        RouteDefinition(
            '/screen-4', (context, parameters) => Container()),
        RouteDefinition('/not-found', (context, parameters) => Container()),
      ],
    ),
    builder: (
      BuildContext context,
      AlbaRouterDelegate pageRouterDelegate,
      AlbaRouteInformationParser pageRouteInformationParser,
    ) {
      return MaterialApp.router(
        routerDelegate: pageRouterDelegate,
        routeInformationParser: pageRouteInformationParser,
      );
    },
  );
}

void main() {
  group('PathPageListener', () {
    testWidgets('listens to a path', (WidgetTester tester) async {
      ActiveRoute? popActiveRoute;
      String? popResult;
      ActiveRoute? pushActiveRoute;

      await tester.pumpWidget(createRouter((context) {
        return PathRouterListener(
          path: '/screen-1',
          child: Container(),
          onPop: (activeRoute, result) {
            popActiveRoute = activeRoute;
            popResult = result as String;
          },
          onPush: (ActiveRoute activeRoute) {
            pushActiveRoute = activeRoute;
          },
        );
      }));

      tester.state<RouterState>(find.byType(Router)).push('/screen-1');
      await tester.pumpAndSettle();

      expect(pushActiveRoute!.path, '/screen-1');

      tester.state<NavigatorState>(find.byType(Navigator)).pop('screen was popped');
      await tester.pumpAndSettle();

      expect(popActiveRoute!.path, '/screen-1');
      expect(popResult, 'screen was popped');
    });
  });

  group('PathPageListener', () {
    testWidgets('listens to an id', (WidgetTester tester) async {
      ActiveRoute? popActiveRoute;
      String? popResult;
      ActiveRoute? pushActiveRoute;

      await tester.pumpWidget(createRouter((context) {
        return IdRouterListener(
          id: 'my-id',
          child: Container(),
          onPop: (activeRoute, result) {
            popActiveRoute = activeRoute;
            popResult = result as String;
          },
          onPush: (ActiveRoute activeRoute) {
            pushActiveRoute = activeRoute;
          },
        );
      }));

      tester.state<RouterState>(find.byType(Router)).push('/screen-1', id: 'my-id');
      await tester.pumpAndSettle();

      expect(pushActiveRoute!.path, '/screen-1');

      tester.state<NavigatorState>(find.byType(Navigator)).pop('screen was popped');
      await tester.pumpAndSettle();

      expect(popActiveRoute!.path, '/screen-1');
      expect(popResult, 'screen was popped');
    });
  });

  group('PathPageListener', () {
    testWidgets('listens to multiple ids and paths', (WidgetTester tester) async {
      ActiveRoute? popActiveRoute;
      String? popResult;
      ActiveRoute? pushActiveRoute;

      await tester.pumpWidget(createRouter((context) {
        return MultipleRouterListener(
          ids: const ['id-1', 'id-2'],
          paths: const ['/screen-3', '/screen-4'],
          child: Container(),
          onPop: (activeRoute, result) {
            popActiveRoute = activeRoute;
            popResult = result as String;
          },
          onPush: (ActiveRoute activeRoute) {
            pushActiveRoute = activeRoute;
          },
        );
      }));

      tester.state<RouterState>(find.byType(Router)).push('/screen-1', id: 'id-1');
      await tester.pumpAndSettle();

      expect(pushActiveRoute!.path, '/screen-1');

      tester.state<RouterState>(find.byType(Router)).push('/screen-2', id: 'id-2');
      await tester.pumpAndSettle();

      expect(pushActiveRoute!.path, '/screen-2');

      tester.state<RouterState>(find.byType(Router)).push('/screen-3');
      await tester.pumpAndSettle();

      expect(pushActiveRoute!.path, '/screen-3');

      tester.state<RouterState>(find.byType(Router)).push('/screen-4');
      await tester.pumpAndSettle();

      expect(pushActiveRoute!.path, '/screen-4');

      tester.state<NavigatorState>(find.byType(Navigator)).pop('screen 4 was popped');
      await tester.pumpAndSettle();

      expect(popActiveRoute!.path, '/screen-4');
      expect(popResult, 'screen 4 was popped');

      tester.state<NavigatorState>(find.byType(Navigator)).pop('screen 3 was popped');
      await tester.pumpAndSettle();

      expect(popActiveRoute!.path, '/screen-3');
      expect(popResult, 'screen 3 was popped');

      tester.state<NavigatorState>(find.byType(Navigator)).pop('screen 2 was popped');
      await tester.pumpAndSettle();

      expect(popActiveRoute!.path, '/screen-2');
      expect(popResult, 'screen 2 was popped');

      tester.state<NavigatorState>(find.byType(Navigator)).pop('screen 1 was popped');
      await tester.pumpAndSettle();

      expect(popActiveRoute!.path, '/screen-1');
      expect(popResult, 'screen 1 was popped');
    });
  });
}
