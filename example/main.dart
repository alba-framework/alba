import 'package:alba/framework.dart';
import 'package:alba/routing.dart';
import 'package:flutter/material.dart';

void main() {
  createApp(
    appProviders: [
      ServiceLocatorProvider(),
    ],
    routerRootConfiguration: RouterRootConfiguration(
      routeDefinitions: routes,
    ),
    widget: const MyApp(),
  ).run();
}

class ServiceLocatorProvider implements AppProvider {
  @override
  Future<void> boot(ServiceLocator serviceLocator) async {}
}

var routes = [
  RouteDefinition(
    '/not-found',
    (context, arguments) => const NotFoundScreen(),
  ),
  RouteDefinition(
    '/',
    (context, arguments) => const HomeScreen(),
  ),
];

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      restorationScopeId: 'app',
      routerDelegate: app().pageRouterDelegate!,
      routeInformationParser: app().pageRouteInformationParser!,
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Hello!'),
      ),
    );
  }
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Not found!'),
      ),
    );
  }
}
