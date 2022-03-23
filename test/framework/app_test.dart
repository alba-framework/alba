import 'package:alba/framework.dart';
import 'package:alba/src/routing/router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Router;
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
      routerDelegate: AlbaRouterDelegate(
        routerState: RouterState(
          navigatorKey: app().navigatorKey,
          notFoundPath: '/not-found',
          routeDefinitions: [
            RouteDefinition('/', (context, parameters) => Container()),
            RouteDefinition('/not-found', (context, parameters) => Container()),
          ],
        ),
      ),
      routeInformationParser: AlbaRouteInformationParser(),
    );
  }
}

void main() {
  group('App', () {
    setUp(() {
      App.clear();
      App.setTesting();
    });

    test('creates the app', () {
      var app = App.create(widget: Container());

      expect(app, isA<App>());
    });

    test('only one can be instantiated', () {
      App.create(widget: Container());

      expect(() => App.create(widget: Container()), throwsA(isA<AlbaError>()));
    });

    test('gets the instance', () {
      var app1 = App.create(widget: Container());
      var app2 = app();

      expect(app1, app2);
    });

    test('gets the service locator', () {
      var app = App.create(widget: Container());

      expect(app.serviceLocator, isA<ServiceLocator>());
    });

    testWidgets('boots providers', (WidgetTester tester) async {
      var spy = Spy();
      var app = App.create(
        appProviders: [ProviderTest(spy)],
        widget: Container(),
      );
      await app.run();

      expect(spy.called, isTrue);
    });

    testWidgets('runs boot testing', (WidgetTester tester) async {
      var spy = Spy();
      App.bootTesting((app) async {
        spy();
      });
      var app = App.create(
        widget: Container(),
      );
      await app.run();

      expect(spy.called, isTrue);
    });

    testWidgets('runs app', (WidgetTester tester) async {
      var key = UniqueKey();
      var app = App.create(
        widget: Container(key: key),
      );
      await app.run();

      expect(find.byType(RootRestorationScope), findsNothing);
      expect(find.byKey(key), findsOneWidget);
    });

    testWidgets('runs app with the router', (WidgetTester tester) async {
      var key = UniqueKey();
      var app = App.create(
        widget: AppWithRouterTest(key: key),
      );
      await app.run();

      expect(find.byType(Router), findsOneWidget);
      expect(find.byKey(key), findsOneWidget);
    });

    testWidgets('gets navigator key', (WidgetTester tester) async {
      var navigatorKey = GlobalKey<NavigatorState>();
      var app = App.create(
        navigatorKey: navigatorKey,
        widget: const AppWithRouterTest(),
      );
      await app.run();
      await tester.pumpAndSettle();

      expect(app.navigatorKey, navigatorKey);
    });

    testWidgets('gets navigator context', (WidgetTester tester) async {
      var app = App.create(
        widget: const AppWithRouterTest(),
      );
      await app.run();
      await tester.pumpAndSettle();

      expect(app.navigatorContext, isA<BuildContext>());
    });

    testWidgets('gets router', (WidgetTester tester) async {
      var app = App.create(
        widget: const AppWithRouterTest(),
      );
      await app.run();
      await tester.pumpAndSettle();

      expect(app.router, isA<RouterWidgetState>());
    });

    test('get isTesting', () {
      var app = App.create(widget: Container());

      expect(app.isTesting, true);
    });
  });
}
