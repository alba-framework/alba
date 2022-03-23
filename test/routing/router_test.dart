import 'package:alba/src/routing/router.dart';
import 'package:flutter/material.dart' hide Router;
import 'package:flutter_test/flutter_test.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class FirstScreen extends StatelessWidget {
  const FirstScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(), body: Container());
  }
}

class SecondScreen extends StatelessWidget {
  const SecondScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class WihParamScreen extends StatelessWidget {
  final String message;

  const WihParamScreen(this.message, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(message);
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

void main() {
  Widget createApp({
    String Function()? initialPath,
    GlobalKey<NavigatorState>? navigatorKey,
    List<NavigatorObserver> Function()? observers,
  }) {
    return MaterialApp.router(
      restorationScopeId: 'app',
      routerDelegate: AlbaRouterDelegate(
        routerState: RouterState(
          navigatorKey: navigatorKey ?? GlobalKey<NavigatorState>(),
          notFoundPath: '/not-found',
          routeDefinitions: [
            RouteDefinition(
              '/',
              (context, parameters) => const HomeScreen(),
            ),
            RouteDefinition(
              '/first-screen',
              (context, parameters) => const FirstScreen(),
            ),
            RouteDefinition('/second-screen',
                (context, parameters) => const SecondScreen()),
            RouteDefinition(
                '/with-param/:message',
                (context, parameters) =>
                    WihParamScreen(parameters['message']!)),
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
        ),
        observers: observers,
        initialPath: initialPath,
      ),
      routeInformationParser: AlbaRouteInformationParser(),
    );
  }

  testWidgets('custom navigator key', (WidgetTester tester) async {
    var navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(createApp(navigatorKey: navigatorKey));

    expect(navigatorKey.currentState, isA<NavigatorState>());
  });

  testWidgets('shows the initial route', (WidgetTester tester) async {
    await tester.pumpWidget(createApp());

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('shows the initial custom route', (WidgetTester tester) async {
    await tester.pumpWidget(createApp(initialPath: () => '/first-screen'));

    expect(find.byType(FirstScreen), findsOneWidget);
  });

  testWidgets('pushes routes', (WidgetTester tester) async {
    await tester.pumpWidget(createApp());

    tester.state<RouterWidgetState>(find.byType(Router)).push('/first-screen');
    await tester.pumpAndSettle();

    expect(find.byType(FirstScreen), findsOneWidget);

    tester.state<RouterWidgetState>(find.byType(Router)).push('/second-screen');
    await tester.pumpAndSettle();

    expect(find.byType(SecondScreen), findsOneWidget);
  });

  testWidgets('pushes an undefined route', (WidgetTester tester) async {
    await tester.pumpWidget(createApp());

    tester
        .state<RouterWidgetState>(find.byType(Router))
        .push('/non-exist-route');
    await tester.pumpAndSettle();

    expect(find.byType(NotFoundScreen), findsOneWidget);
  });

  testWidgets('pushes a route with a middleware', (WidgetTester tester) async {
    await tester.pumpWidget(createApp());

    tester
        .state<RouterWidgetState>(find.byType(Router))
        .push('/pass-middleware');
    await tester.pumpAndSettle();

    expect(find.byType(FirstScreen), findsOneWidget);
  });

  testWidgets('pushes a route with a middleware that abort the navigation',
      (WidgetTester tester) async {
    await tester.pumpWidget(createApp());

    tester
        .state<RouterWidgetState>(find.byType(Router))
        .push('/abort-middleware');
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('pops routes', (WidgetTester tester) async {
    await tester.pumpWidget(createApp());

    tester.state<RouterWidgetState>(find.byType(Router)).push('/first-screen');
    await tester.pumpAndSettle();

    tester.state<RouterWidgetState>(find.byType(Router)).push('/second-screen');
    await tester.pumpAndSettle();

    await tester.state<RouterWidgetState>(find.byType(Router)).pop();
    await tester.pumpAndSettle();

    await tester.state<RouterWidgetState>(find.byType(Router)).pop();
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(FirstScreen), findsNothing);
    expect(find.byType(SecondScreen), findsNothing);
  });

  testWidgets('pops routes (using Navigator)', (WidgetTester tester) async {
    await tester.pumpWidget(createApp());

    tester.state<RouterWidgetState>(find.byType(Router)).push('/first-screen');
    await tester.pumpAndSettle();

    tester.state<RouterWidgetState>(find.byType(Router)).push('/second-screen');
    await tester.pumpAndSettle();

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(FirstScreen), findsNothing);
    expect(find.byType(SecondScreen), findsNothing);
  });

  testWidgets('pushes an undefined route', (WidgetTester tester) async {
    await tester.pumpWidget(createApp());

    tester
        .state<RouterWidgetState>(find.byType(Router))
        .push('/non-exist-route');
    await tester.pumpAndSettle();

    expect(find.byType(NotFoundScreen), findsOneWidget);
  });

  testWidgets('replaces a route', (WidgetTester tester) async {
    await tester.pumpWidget(createApp());

    tester.state<RouterWidgetState>(find.byType(Router)).push('/first-screen');
    await tester.pumpAndSettle();

    tester
        .state<RouterWidgetState>(find.byType(Router))
        .replace('/second-screen');
    await tester.pumpAndSettle();

    expect(find.byType(SecondScreen), findsOneWidget);

    await tester.state<RouterWidgetState>(find.byType(Router)).pop();
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('replaces a route with a middleware',
      (WidgetTester tester) async {
    await tester.pumpWidget(createApp());

    tester
        .state<RouterWidgetState>(find.byType(Router))
        .replace('/pass-middleware');
    await tester.pumpAndSettle();

    expect(find.byType(FirstScreen), findsOneWidget);
  });

  testWidgets('replaces a route with a middleware that abort the navigation',
      (WidgetTester tester) async {
    await tester.pumpWidget(createApp());

    tester
        .state<RouterWidgetState>(find.byType(Router))
        .replace('/abort-middleware');
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('removes a route', (WidgetTester tester) async {
    await tester.pumpWidget(createApp());

    tester.state<RouterWidgetState>(find.byType(Router)).push('/first-screen');
    await tester.pumpAndSettle();

    tester.state<RouterWidgetState>(find.byType(Router)).push('/second-screen');
    await tester.pumpAndSettle();

    tester
        .state<RouterWidgetState>(find.byType(Router))
        .remove('/first-screen');
    await tester.pumpAndSettle();

    await tester.state<RouterWidgetState>(find.byType(Router)).pop();
    await tester.pumpAndSettle();

    expect(find.byType(FirstScreen), findsNothing);
  });

  testWidgets('removes all routes and push a new one',
      (WidgetTester tester) async {
    await tester.pumpWidget(createApp());

    tester.state<RouterWidgetState>(find.byType(Router)).push('/first-screen');
    await tester.pumpAndSettle();

    tester.state<RouterWidgetState>(find.byType(Router)).push('/second-screen');
    await tester.pumpAndSettle();

    tester.state<RouterWidgetState>(find.byType(Router)).removeAllAndPush('/');
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('removes until and push a new one', (WidgetTester tester) async {
    await tester.pumpWidget(createApp());

    tester.state<RouterWidgetState>(find.byType(Router)).push('/first-screen');
    await tester.pumpAndSettle();

    tester.state<RouterWidgetState>(find.byType(Router)).push('/second-screen');
    await tester.pumpAndSettle();

    tester.state<RouterWidgetState>(find.byType(Router)).removeUntilAndPush(
        (activeRoute) => activeRoute.path == '/', '/second-screen');
    await tester.pumpAndSettle();

    expect(find.byType(SecondScreen), findsOneWidget);

    await tester.state<RouterWidgetState>(find.byType(Router)).pop();
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('restores routes', (WidgetTester tester) async {
    await tester.pumpWidget(createApp());

    tester.state<RouterWidgetState>(find.byType(Router)).push('/first-screen');
    await tester.pumpAndSettle();

    expect(find.byType(FirstScreen), findsOneWidget);

    tester.state<RouterWidgetState>(find.byType(Router)).push('/second-screen');
    await tester.pumpAndSettle();

    expect(find.byType(SecondScreen), findsOneWidget);

    await tester.restartAndRestore();

    expect(find.byType(SecondScreen), findsOneWidget);

    await tester.state<RouterWidgetState>(find.byType(Router)).pop();
    await tester.pumpAndSettle();

    expect(find.byType(FirstScreen), findsOneWidget);

    await tester.state<RouterWidgetState>(find.byType(Router)).pop();
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('gets the current path', (WidgetTester tester) async {
    await tester.pumpWidget(createApp());

    tester.state<RouterWidgetState>(find.byType(Router)).push('/first-screen');
    await tester.pumpAndSettle();

    var currentPath =
        tester.state<RouterWidgetState>(find.byType(Router)).currentPath;

    expect(currentPath, '/first-screen');
  });

  testWidgets('pages are not recreated', (WidgetTester tester) async {
    await tester.pumpWidget(createApp());

    tester.state<RouterWidgetState>(find.byType(Router)).push('/non-const');
    await tester.pumpAndSettle();

    final nonConstScreenA =
        find.byType(NonConstScreen).evaluate().single.widget as NonConstScreen;

    tester.state<RouterWidgetState>(find.byType(Router)).push('/first-screen');
    await tester.state<RouterWidgetState>(find.byType(Router)).pop();
    await tester.pumpAndSettle();

    final nonConstScreenB =
        find.byType(NonConstScreen).evaluate().single.widget as NonConstScreen;

    expect(
        identityHashCode(nonConstScreenA), identityHashCode(nonConstScreenB));

    tester.state<RouterWidgetState>(find.byType(Router)).push('/non-const');
    await tester.pumpAndSettle();

    final nonConstScreenC =
        find.byType(NonConstScreen).evaluate().single.widget as NonConstScreen;

    expect(identityHashCode(nonConstScreenA),
        isNot(identityHashCode(nonConstScreenC)));
  });

  testWidgets('route with params', (WidgetTester tester) async {
    await tester.pumpWidget(createApp());

    tester
        .state<RouterWidgetState>(find.byType(Router))
        .push('/with-param/my-message');
    await tester.pumpAndSettle();

    expect(find.text('my-message'), findsOneWidget);

    tester
        .state<RouterWidgetState>(find.byType(Router))
        .push('/with-param/my-other-message');
    await tester.pumpAndSettle();

    expect(find.text('my-other-message'), findsOneWidget);

    expect(tester.state<RouterWidgetState>(find.byType(Router)).currentPath,
        '/with-param/my-other-message');

    await tester.restartAndRestore();

    expect(find.text('my-other-message'), findsOneWidget);

    await tester.state<RouterWidgetState>(find.byType(Router)).pop();
    await tester.pumpAndSettle();

    expect(find.text('my-message'), findsOneWidget);
  });

  testWidgets('observe route changes', (WidgetTester tester) async {
    var logObserver = LogObserver();
    await tester.pumpWidget(createApp(observers: () => [logObserver]));

    tester.state<RouterWidgetState>(find.byType(Router)).push('/first-screen');
    await tester.pumpAndSettle();

    tester.state<RouterWidgetState>(find.byType(Router)).push('/second-screen');
    await tester.pumpAndSettle();

    // Replace is detected as a push event.
    tester
        .state<RouterWidgetState>(find.byType(Router))
        .replace('/first-screen');
    await tester.pumpAndSettle();

    // Remove isn't detected.
    // tester.state<Router2State>(find.byType(Router2)).remove('/first-screen');
    // await tester.pumpAndSettle();

    await tester.state<RouterWidgetState>(find.byType(Router)).pop();
    await tester.pumpAndSettle();

    await tester.state<RouterWidgetState>(find.byType(Router)).pop();
    await tester.pumpAndSettle();

    expect(
      logObserver.log,
      '''
push: /
push: /first-screen
push: /second-screen
push: /first-screen
pop: /first-screen
pop: /
''',
    );
  });
}
