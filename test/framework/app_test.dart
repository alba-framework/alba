import 'package:alba/framework.dart';
import 'package:alba/routing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

class ProviderTest implements AppProvider {
  final Spy spy;

  ProviderTest(this.spy);

  @override
  Future<void> boot(ServiceLocator serviceLocator) {
    spy();

    return SynchronousFuture(null);
  }
}

class AppWithRouterTest extends StatelessWidget {
  const AppWithRouterTest({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerDelegate: app().pageRouterDelegate!,
      routeInformationParser: app().pageRouteInformationParser!,
    );
  }
}

void main() {
  group('App', () {
    setUp(() async {
      clearApp();
    });

    test('creates the app', () {
      var app = createApp(widget: Container());

      expect(app, isA<App>());
    });

    test('only one can be instantiated', () {
      createApp(widget: Container());

      expect(() => createApp(widget: Container()), throwsA(isA<AlbaError>()));
    });

    test('gets the instance', () {
      var app1 = createApp(widget: Container());
      var app2 = app();

      expect(app1, app2);
    });

    test('gets the service locator', () {
      var app = createApp(widget: Container());

      expect(app.serviceLocator, isA<ServiceLocator>());
    });

    testWidgets('boots providers', (WidgetTester tester) async {
      var spy = Spy();
      var app = createApp(
        appProviders: [ProviderTest(spy)],
        widget: Container(),
      );
      await app.run();

      expect(spy.called, isTrue);
    });

    testWidgets('runs app', (WidgetTester tester) async {
      var key = UniqueKey();
      var app = createApp(
        widget: Container(key: key),
      );
      await app.run();

      expect(find.byType(RootRestorationScope), findsNothing);
      expect(find.byType(RouterRoot), findsNothing);
      expect(find.byKey(key), findsOneWidget);
      expect(app.pageRouterDelegate, null);
      expect(app.pageRouteInformationParser, null);
    });

    testWidgets('runs app with restoration scope', (WidgetTester tester) async {
      var key = UniqueKey();
      var app = createApp(
        restorationScopeId: 'root',
        widget: Container(key: key),
      );
      await app.run();

      var rootRestorationScopeFinder = find.byType(RootRestorationScope);
      expect(rootRestorationScopeFinder, findsOneWidget);
      expect(
          tester
              .widget<RootRestorationScope>(rootRestorationScopeFinder)
              .restorationId,
          'root');
      expect(find.byKey(key), findsOneWidget);
    });

    testWidgets('runs app with the router', (WidgetTester tester) async {
      var key = UniqueKey();
      var app = createApp(
        routerRootConfiguration: RouterRootConfiguration(routeDefinitions: [
          RouteDefinition('/', (context, parameters) => Container()),
          RouteDefinition('/not-found', (context, parameters) => Container()),
        ]),
        widget: AppWithRouterTest(key: key),
      );
      await app.run();

      expect(find.byType(RouterRoot), findsOneWidget);
      expect(find.byKey(key), findsOneWidget);
      expect(app.pageRouterDelegate, isNot(null));
      expect(app.pageRouteInformationParser, isNot(null));
    });

    testWidgets('gets navigator context', (WidgetTester tester) async {
      var app = createApp(
        routerRootConfiguration: RouterRootConfiguration(routeDefinitions: [
          RouteDefinition('/', (context, parameters) => Container()),
          RouteDefinition('/not-found', (context, parameters) => Container()),
        ]),
        widget: const AppWithRouterTest(),
      );
      await app.run();
      await tester.pumpAndSettle();

      expect(app.navigatorContext, isA<BuildContext>());
    });
  });
}
