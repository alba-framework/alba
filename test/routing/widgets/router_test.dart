import 'package:alba/routing.dart';
import 'package:flutter/material.dart' hide Router;
import 'package:flutter/widgets.dart' hide Router;
import 'package:flutter_test/flutter_test.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class MyOtherScreen extends StatelessWidget {
  const MyOtherScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

RouterRoot createRouter({
  GlobalKey<NavigatorState>? navigatorKey
}) {
  return RouterRoot(
    configuration: RouterRootConfiguration(
      routeDefinitions: [
        RouteDefinition('/', (context, parameters) => const HomeScreen()),
        RouteDefinition(
            '/my-page', (context, parameters) => const MyOtherScreen()),
        RouteDefinition(
            '/not-found', (context, parameters) => const NotFoundScreen()),
      ],
      navigatorKey: navigatorKey,
    ),
    builder: (BuildContext context,
        AlbaRouterDelegate pageRouterDelegate,
        AlbaRouteInformationParser pageRouteInformationParser,) {
      return MaterialApp.router(
        routerDelegate: pageRouterDelegate,
        routeInformationParser: pageRouteInformationParser,
      );
    },
  );
}

void main() {
  group('Router', () {
    testWidgets('shows the initial route', (WidgetTester tester) async {
      await tester.pumpWidget(createRouter());

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('pushes a route', (WidgetTester tester) async {
      await tester.pumpWidget(createRouter());

      tester.state<RouterState>(find.byType(Router)).push('/my-page');
      await tester.pumpAndSettle();

      expect(find.byType(MyOtherScreen), findsOneWidget);
    });

    testWidgets('pushes a not found route', (WidgetTester tester) async {
      await tester.pumpWidget(createRouter());

      tester.state<RouterState>(find.byType(Router)).push('/non-exist-route');
      await tester.pumpAndSettle();

      expect(find.byType(NotFoundScreen), findsOneWidget);
    });

    testWidgets('sets the navigator key', (WidgetTester tester) async {
      var navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(createRouter(navigatorKey: navigatorKey));

      expect(navigatorKey.currentState, isA<NavigatorState>());
    });

    testWidgets('pops a route', (WidgetTester tester) async {
      await tester.pumpWidget(createRouter());

      tester.state<RouterState>(find.byType(Router)).push('/my-page');
      await tester.pumpAndSettle();

      tester.state<NavigatorState>(find.byType(Navigator)).pop('result');
      await tester.pumpAndSettle();

      expect(find.byType(MyOtherScreen), findsNothing);
    });
  });
}
