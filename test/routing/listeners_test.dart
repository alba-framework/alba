import 'package:alba/routing.dart';
import 'package:flutter/material.dart' hide Router;
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget createApp(WidgetBuilder homeScreenBuilder) {
    return MaterialApp.router(
      restorationScopeId: 'app',
      routerDelegate: AlbaRouterDelegate(
          routerState: RouterState(
        navigatorKey: GlobalKey<NavigatorState>(),
        notFoundPath: '/not-found',
        routeDefinitions: [
          RouteDefinition(
            '/',
            (context, parameters) => homeScreenBuilder(context),
          ),
          RouteDefinition('/screen-1', (context, parameters) => Container()),
          RouteDefinition('/screen-2', (context, parameters) => Container()),
          RouteDefinition('/screen-3', (context, parameters) => Container()),
          RouteDefinition('/screen-4', (context, parameters) => Container()),
          RouteDefinition('/not-found', (context, parameters) => Container()),
        ],
      )),
      routeInformationParser: AlbaRouteInformationParser(),
    );
  }

  group('PathPageListener', () {
    testWidgets('listens to a path', (WidgetTester tester) async {
      PageWrapper? popPageWrapper;
      String? popResult;
      PageWrapper? pushPageWrapper;

      await tester.pumpWidget(createApp((context) {
        return PathRouterListener(
          path: '/screen-1',
          child: Container(),
          onPop: (pageWrapper, result) {
            popPageWrapper = pageWrapper;
            popResult = result as String;
          },
          onPush: (PageWrapper pageWrapper) {
            pushPageWrapper = pageWrapper;
          },
        );
      }));

      tester.state<RouterWidgetState>(find.byType(Router)).push('/screen-1');
      await tester.pumpAndSettle();

      expect(pushPageWrapper!.path, '/screen-1');

      await tester
          .state<RouterWidgetState>(find.byType(Router))
          .pop('screen was popped');
      await tester.pumpAndSettle();

      expect(popPageWrapper!.path, '/screen-1');
      expect(popResult, 'screen was popped');
    });
  });

  group('PathPageListener', () {
    testWidgets('listens to an id', (WidgetTester tester) async {
      PageWrapper? popPageWrapper;
      String? popResult;
      PageWrapper? pushPageWrapper;

      await tester.pumpWidget(createApp((context) {
        return IdRouterListener(
          id: 'my-id',
          child: Container(),
          onPop: (pageWrapper, result) {
            popPageWrapper = pageWrapper;
            popResult = result as String;
          },
          onPush: (PageWrapper pageWrapper) {
            pushPageWrapper = pageWrapper;
          },
        );
      }));

      tester
          .state<RouterWidgetState>(find.byType(Router))
          .push('/screen-1', id: 'my-id');
      await tester.pumpAndSettle();

      expect(pushPageWrapper!.path, '/screen-1');

      await tester
          .state<RouterWidgetState>(find.byType(Router))
          .pop('screen was popped');
      await tester.pumpAndSettle();

      expect(popPageWrapper!.path, '/screen-1');
      expect(popResult, 'screen was popped');
    });
  });

  group('PathPageListener', () {
    testWidgets('listens to multiple ids and paths',
        (WidgetTester tester) async {
      PageWrapper? popPageWrapper;
      String? popResult;
      PageWrapper? pushPageWrapper;

      await tester.pumpWidget(createApp((context) {
        return MultipleRouterListener(
          ids: const ['id-1', 'id-2'],
          paths: const ['/screen-3', '/screen-4'],
          child: Container(),
          onPop: (pageWrapper, result) {
            popPageWrapper = pageWrapper;
            popResult = result as String;
          },
          onPush: (PageWrapper pageWrapper) {
            pushPageWrapper = pageWrapper;
          },
        );
      }));

      tester
          .state<RouterWidgetState>(find.byType(Router))
          .push('/screen-1', id: 'id-1');
      await tester.pumpAndSettle();

      expect(pushPageWrapper!.path, '/screen-1');

      tester
          .state<RouterWidgetState>(find.byType(Router))
          .push('/screen-2', id: 'id-2');
      await tester.pumpAndSettle();

      expect(pushPageWrapper!.path, '/screen-2');

      tester.state<RouterWidgetState>(find.byType(Router)).push('/screen-3');
      await tester.pumpAndSettle();

      expect(pushPageWrapper!.path, '/screen-3');

      tester.state<RouterWidgetState>(find.byType(Router)).push('/screen-4');
      await tester.pumpAndSettle();

      expect(pushPageWrapper!.path, '/screen-4');

      await tester
          .state<RouterWidgetState>(find.byType(Router))
          .pop('screen 4 was popped');
      await tester.pumpAndSettle();

      expect(popPageWrapper!.path, '/screen-4');
      expect(popResult, 'screen 4 was popped');

      await tester
          .state<RouterWidgetState>(find.byType(Router))
          .pop('screen 3 was popped');
      await tester.pumpAndSettle();

      expect(popPageWrapper!.path, '/screen-3');
      expect(popResult, 'screen 3 was popped');

      await tester
          .state<RouterWidgetState>(find.byType(Router))
          .pop('screen 2 was popped');
      await tester.pumpAndSettle();

      expect(popPageWrapper!.path, '/screen-2');
      expect(popResult, 'screen 2 was popped');

      await tester
          .state<RouterWidgetState>(find.byType(Router))
          .pop('screen 1 was popped');
      await tester.pumpAndSettle();

      expect(popPageWrapper!.path, '/screen-1');
      expect(popResult, 'screen 1 was popped');
    });
  });
}
