import 'package:alba/routing.dart';
import 'package:flutter/material.dart' hide Router;
import 'package:flutter_test/flutter_test.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class NonConstScreen extends StatelessWidget {
  // ignore: prefer_const_constructors_in_immutables
  NonConstScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class FirstScreen extends StatelessWidget {
  const FirstScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class SecondScreen extends StatelessWidget {
  const SecondScreen({Key? key}) : super(key: key);

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

class PassMiddleware extends Middleware {
  @override
  void handle(RouteDefinition subject, next) {
    next(subject);
  }
}

class AbortMiddleware extends Middleware {
  @override
  void handle(RouteDefinition subject, next) {
    // This middleware doesn't call next.
  }
}

class LogObserver extends NavigatorObserver {
  String log = '';

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    log += 'push: ${_extractPath(route)}\n';
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    log += 'replace: ${_extractPath(newRoute!)}\n';
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    log += 'pop: ${_extractPath(previousRoute!)}\n';
  }

  String? _extractPath(Route<dynamic> route) {
    return route.settings.name?.replaceFirst(RegExp('^[^/]+'), '');
  }
}

RouterRoot createRouter({
  String Function()? initialPath,
  GlobalKey<NavigatorState>? navigatorKey,
  List<NavigatorObserver> Function()? observers,
}) {
  return RouterRoot(
    configuration: RouterRootConfiguration(
      routeDefinitions: [
        RouteDefinition('/', (context, parameters) => const HomeScreen()),
        RouteDefinition(
            '/first-screen', (context, parameters) => const FirstScreen()),
        RouteDefinition(
            '/second-screen', (context, parameters) => const FirstScreen()),
        RouteDefinition(
          '/pass-middleware',
          (context, parameters) => const FirstScreen(),
          middlewares: () => [PassMiddleware()],
        ),
        RouteDefinition(
          '/abort-middleware',
          (context, parameters) => const FirstScreen(),
          middlewares: () => [AbortMiddleware()],
        ),
        RouteDefinition(
            '/non-const', (context, parameters) => NonConstScreen()),
        RouteDefinition(
            '/not-found', (context, parameters) => const NotFoundScreen()),
      ],
      initialPath: initialPath,
      navigatorKey: navigatorKey,
      observers: observers,
    ),
    builder: (
      BuildContext context,
      AlbaRouterDelegate pageRouterDelegate,
      AlbaRouteInformationParser pageRouteInformationParser,
    ) {
      return MaterialApp.router(
        restorationScopeId: 'app',
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

    testWidgets('shows the initial custom route', (WidgetTester tester) async {
      await tester.pumpWidget(createRouter(initialPath: () => '/first-screen'));

      expect(find.byType(FirstScreen), findsOneWidget);
    });

    testWidgets('pushes a route', (WidgetTester tester) async {
      await tester.pumpWidget(createRouter());

      tester.state<RouterState>(find.byType(Router)).push('/first-screen');
      await tester.pumpAndSettle();

      expect(find.byType(FirstScreen), findsOneWidget);
    });

    testWidgets('pushes an undefined route', (WidgetTester tester) async {
      await tester.pumpWidget(createRouter());

      tester.state<RouterState>(find.byType(Router)).push('/non-exist-route');
      await tester.pumpAndSettle();

      expect(find.byType(NotFoundScreen), findsOneWidget);
    });

    testWidgets('pushes a route with a middleware',
        (WidgetTester tester) async {
      await tester.pumpWidget(createRouter());

      tester.state<RouterState>(find.byType(Router)).push('/pass-middleware');
      await tester.pumpAndSettle();

      expect(find.byType(FirstScreen), findsOneWidget);
    });

    testWidgets('pushes a route with a middleware that abort the navigation',
        (WidgetTester tester) async {
      await tester.pumpWidget(createRouter());

      tester.state<RouterState>(find.byType(Router)).push('/abort-middleware');
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('sets the navigator key', (WidgetTester tester) async {
      var navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(createRouter(navigatorKey: navigatorKey));

      expect(navigatorKey.currentState, isA<NavigatorState>());
    });

    testWidgets('pops a route', (WidgetTester tester) async {
      await tester.pumpWidget(createRouter());

      tester.state<RouterState>(find.byType(Router)).push('/first-screen');
      await tester.pumpAndSettle();

      tester.state<RouterState>(find.byType(Router)).pop();
      await tester.pumpAndSettle();

      expect(find.byType(FirstScreen), findsNothing);
    });

    testWidgets('pops a route (using Navigator)', (WidgetTester tester) async {
      await tester.pumpWidget(createRouter());

      tester.state<RouterState>(find.byType(Router)).push('/first-screen');
      await tester.pumpAndSettle();

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();

      expect(find.byType(FirstScreen), findsNothing);
    });

    testWidgets('removes a route', (WidgetTester tester) async {
      await tester.pumpWidget(createRouter());

      tester.state<RouterState>(find.byType(Router)).push('/first-screen');
      await tester.pumpAndSettle();

      tester.state<RouterState>(find.byType(Router)).push('/second-screen');
      await tester.pumpAndSettle();

      tester
          .state<RouterState>(find.byType(Router))
          .removeRoute('/first-screen');
      await tester.pumpAndSettle();

      tester.state<RouterState>(find.byType(Router)).pop();
      await tester.pumpAndSettle();

      expect(find.byType(FirstScreen), findsNothing);
    });

    testWidgets('restores routes', (WidgetTester tester) async {
      await tester.pumpWidget(createRouter());

      tester.state<RouterState>(find.byType(Router)).push('/first-screen');
      await tester.pumpAndSettle();

      expect(find.byType(FirstScreen), findsOneWidget);

      await tester.restartAndRestore();

      expect(find.byType(FirstScreen), findsOneWidget);

      tester.state<RouterState>(find.byType(Router)).pop();
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('removes all routes and push a new one',
        (WidgetTester tester) async {
      await tester.pumpWidget(createRouter());

      tester.state<RouterState>(find.byType(Router)).push('/first-screen');
      await tester.pumpAndSettle();

      tester.state<RouterState>(find.byType(Router)).push('/second-screen');
      await tester.pumpAndSettle();

      tester.state<RouterState>(find.byType(Router)).removeAllAndPush('/');
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('gets the current path', (WidgetTester tester) async {
      await tester.pumpWidget(createRouter());

      tester.state<RouterState>(find.byType(Router)).push('/first-screen');
      await tester.pumpAndSettle();

      var currentPath =
          tester.state<RouterState>(find.byType(Router)).currentPath;

      expect(currentPath, '/first-screen');
    });

    testWidgets('observe route changes', (WidgetTester tester) async {
      var logObserver = LogObserver();
      await tester.pumpWidget(createRouter(observers: () => [logObserver]));

      tester.state<RouterState>(find.byType(Router)).push('/first-screen');
      await tester.pumpAndSettle();

      tester.state<RouterState>(find.byType(Router)).push('/second-screen');
      await tester.pumpAndSettle();

      tester.state<RouterState>(find.byType(Router)).pop();
      await tester.pumpAndSettle();

      tester.state<RouterState>(find.byType(Router)).pop();
      await tester.pumpAndSettle();

      expect(
        logObserver.log,
        '''
push: /
push: /first-screen
push: /second-screen
pop: /first-screen
pop: /
''',
      );
    });

    testWidgets('cache pages', (WidgetTester tester) async {
      await tester.pumpWidget(createRouter(initialPath: () => '/non-const'));

      final nonConstScreenA = find
          .byType(NonConstScreen)
          .evaluate()
          .single
          .widget as NonConstScreen;

      tester.state<RouterState>(find.byType(Router)).push('/first-screen');
      tester.state<RouterState>(find.byType(Router)).pop();
      await tester.pumpAndSettle();

      final nonConstScreenB = find
          .byType(NonConstScreen)
          .evaluate()
          .single
          .widget as NonConstScreen;

      expect(
          identityHashCode(nonConstScreenA), identityHashCode(nonConstScreenB));

      tester.state<RouterState>(find.byType(Router)).push('/non-const');
      await tester.pumpAndSettle();

      final nonConstScreenC = find
          .byType(NonConstScreen)
          .evaluate()
          .single
          .widget as NonConstScreen;

      expect(identityHashCode(nonConstScreenA),
          isNot(identityHashCode(nonConstScreenC)));
    });
  });
}
