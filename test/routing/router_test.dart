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

class WithQueryScreen extends StatelessWidget {
  final String message;
  final String emptyParam;
  final String? optionalParam;

  const WithQueryScreen(
    this.message,
    this.emptyParam,
    this.optionalParam, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(message),
        Text(emptyParam.isEmpty ? 'is empty' : emptyParam),
        Text(optionalParam == null ? 'is null' : optionalParam!),
      ],
    );
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
    log += 'push: ${route.settings.name} - ${_extractPath(route)}\n';
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    log += 'replace: ${newRoute?.settings.name} - ${_extractPath(newRoute!)}\n';
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    log += 'pop: ${route.settings.name} - ${_extractPath(route)}\n';
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    log += 'remove: ${route.settings.name} - ${_extractPath(route)}\n';
  }

  String? _extractPath(Route<dynamic> route) {
    final arguments =
        Map<String, dynamic>.from(route.settings.arguments as Map);
    return arguments['path'];
  }
}

void main() {
  Widget createApp({
    String Function()? initialPath,
    GlobalKey<NavigatorState>? navigatorKey,
    GlobalKey<RouterWidgetState>? routerKey,
    List<NavigatorObserver> Function()? observers,
    RouteInformationProvider? routeInformationProvider,
  }) {
    return MaterialApp.router(
      restorationScopeId: 'app',
      routerDelegate: AlbaRouterDelegate(
        routerKey: routerKey,
        routerState: RouterState(
          navigatorKey: navigatorKey ?? GlobalKey<NavigatorState>(),
          notFoundPath: '/not-found',
          routeDefinitions: [
            RouteDefinition(
              '/',
              (context, parameters, query) => const HomeScreen(),
              name: 'Home Screen',
            ),
            RouteDefinition(
              '/first-screen',
              (context, parameters, query) => const FirstScreen(),
              name: 'First Screen',
            ),
            RouteDefinition(
              '/second-screen',
              (context, parameters, query) => const SecondScreen(),
              name: 'Second Screen',
            ),
            RouteDefinition(
              '/with-param/:message',
              (context, parameters, query) =>
                  WihParamScreen(parameters['message']!),
            ),
            RouteDefinition(
              '/with-query',
              (context, parameters, query) => WithQueryScreen(
                query['message']!,
                query['empty-param']!,
                query['optional-param'],
              ),
            ),
            RouteDefinition(
              '/pass-middleware',
              (context, parameters, query) => const FirstScreen(),
              middlewares: () => [PassMiddleware()],
            ),
            RouteDefinition(
              '/abort-middleware',
              (context, parameters, query) => const FirstScreen(),
              middlewares: () => [AbortMiddleware()],
            ),
            RouteDefinition(
              '/non-const',
              (context, parameters, query) => NonConstScreen(),
            ),
            RouteDefinition(
              '/not-found',
              (context, parameters, query) => const NotFoundScreen(),
            ),
          ],
        ),
        observers: observers,
        initialPath: initialPath,
      ),
      routeInformationParser: AlbaRouteInformationParser(),
      routeInformationProvider: routeInformationProvider,
    );
  }

  testWidgets('custom navigator key', (WidgetTester tester) async {
    var navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(createApp(navigatorKey: navigatorKey));

    expect(navigatorKey.currentState, isA<NavigatorState>());
  });

  testWidgets('custom router key', (WidgetTester tester) async {
    var routerKey = GlobalKey<RouterWidgetState>();
    await tester.pumpWidget(createApp(routerKey: routerKey));

    expect(routerKey.currentState, isA<RouterWidgetState>());
  });

  testWidgets('shows the initial route', (WidgetTester tester) async {
    await tester.pumpWidget(createApp());

    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('shows the initial custom route', (WidgetTester tester) async {
    await tester.pumpWidget(createApp(initialPath: () => '/first-screen'));

    expect(find.byType(FirstScreen), findsOneWidget);
  });

  testWidgets('initial custom route respects current location',
      (WidgetTester tester) async {
    await tester.pumpWidget(createApp(
      initialPath: () => '/first-screen',
      routeInformationProvider: PlatformRouteInformationProvider(
        initialRouteInformation:
            const RouteInformation(location: '/second-screen'),
      ),
    ));

    expect(find.byType(SecondScreen), findsOneWidget);
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

  testWidgets('pops routes until', (WidgetTester tester) async {
    await tester.pumpWidget(createApp());

    tester.state<RouterWidgetState>(find.byType(Router)).push('/first-screen');
    await tester.pumpAndSettle();

    tester.state<RouterWidgetState>(find.byType(Router)).push('/second-screen');
    await tester.pumpAndSettle();

    tester.state<RouterWidgetState>(find.byType(Router)).push('/first-screen');
    await tester.pumpAndSettle();

    tester
        .state<RouterWidgetState>(find.byType(Router))
        .popUntil((activeRoute) => activeRoute.path == '/');
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

  testWidgets('route with query', (WidgetTester tester) async {
    await tester.pumpWidget(createApp());

    tester
        .state<RouterWidgetState>(find.byType(Router))
        .push('/with-query?message=my-message&empty-param');
    await tester.pumpAndSettle();

    expect(find.text('my-message'), findsOneWidget);
    expect(find.text('is empty'), findsOneWidget);
    expect(find.text('is null'), findsOneWidget);
  });

  testWidgets('observe route changes', (WidgetTester tester) async {
    var logObserver = LogObserver();
    await tester.pumpWidget(createApp(observers: () => [logObserver]));

    tester.state<RouterWidgetState>(find.byType(Router)).push('/first-screen');
    await tester.pumpAndSettle();

    await tester.state<RouterWidgetState>(find.byType(Router)).pop();
    await tester.pumpAndSettle();

    tester.state<RouterWidgetState>(find.byType(Router)).push('/second-screen');
    await tester.pumpAndSettle();

    tester.state<RouterWidgetState>(find.byType(Router)).remove('/');
    await tester.pumpAndSettle();

    // `replace` is detected as a push and remove event.
    tester
        .state<RouterWidgetState>(find.byType(Router))
        .replace('/first-screen');
    await tester.pumpAndSettle();

    tester.state<RouterWidgetState>(find.byType(Router)).push('/second-screen');
    await tester.pumpAndSettle();

    // `removeAllAndPush` is detected as a push and several remove events.
    tester
        .state<RouterWidgetState>(find.byType(Router))
        .removeAllAndPush('/first-screen');
    await tester.pumpAndSettle();

    tester.state<RouterWidgetState>(find.byType(Router)).push('/second-screen');
    await tester.pumpAndSettle();

    await tester.state<RouterWidgetState>(find.byType(Router)).pop();
    await tester.pumpAndSettle();

    expect(
      logObserver.log,
      '''
push: Home Screen - /
push: First Screen - /first-screen
pop: First Screen - /first-screen
push: Second Screen - /second-screen
remove: Home Screen - /
push: First Screen - /first-screen
remove: Second Screen - /second-screen
push: Second Screen - /second-screen
push: First Screen - /first-screen
remove: Second Screen - /second-screen
remove: First Screen - /first-screen
push: Second Screen - /second-screen
pop: Second Screen - /second-screen
''',
    );
  });

  testWidgets('find a widget', (WidgetTester tester) async {
    await tester.pumpWidget(createApp());

    tester.state<RouterWidgetState>(find.byType(Router)).push('/first-screen');
    await tester.pumpAndSettle();

    tester.state<RouterWidgetState>(find.byType(Router)).push('/second-screen');
    await tester.pumpAndSettle();

    final firstScreen = tester
        .state<RouterWidgetState>(find.byType(Router))
        .findWidget<FirstScreen>();

    expect(firstScreen, isA<FirstScreen>());
  });
}
