import 'package:alba/framework.dart';
import 'package:alba/routing.dart';
import 'package:flutter/material.dart';

void main() {
  App.create(
    appProviders: [
      ServiceLocatorProvider(),
    ],
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
    (context, parameters, query) => const NotFoundScreen(),
  ),
  RouteDefinition(
    '/',
    (context, parameters, query) => const HomeScreen(),
  ),
];

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RouterBuilder(
      routeDefinitions: routes,
      builder: (routerDelegate, routeInformationParser) {
        return MaterialApp.router(
          restorationScopeId: 'app',
          routerDelegate: routerDelegate,
          routeInformationParser: routeInformationParser,
        );
      },
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
