import 'package:alba/framework.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'error_handler_test.mocks.dart';

class MyErrorListener extends Mock implements ErrorListener {}

class MockHandler extends Mock implements ErrorHandler {}

class WorkingWidget extends StatelessWidget {
  const WorkingWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Text('Working', textDirection: TextDirection.ltr);
  }
}

class ExceptionWidget extends StatelessWidget {
  const ExceptionWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    throw Exception('Stub exception thrown');
  }
}

@GenerateMocks([MyErrorListener])
void main() {
  group('ErrorHandler', () {
    testWidgets('does not catch any error when body works as expected',
        (WidgetTester tester) async {
      MockMyErrorListener mockMyErrorListener = MockMyErrorListener();
      ErrorHandler errorHandler = ErrorHandler([mockMyErrorListener]);

      await tester.runAsync(() async {
        errorHandler.run(() {
          // do nothing
        });
      });

      verifyZeroInteractions(mockMyErrorListener);
    });

    testWidgets('reports dart unhandled error', (WidgetTester tester) async {
      MockMyErrorListener mockMyErrorListener = MockMyErrorListener();
      ErrorHandler errorHandler = ErrorHandler([mockMyErrorListener]);

      await tester.runAsync(() async {
        errorHandler.run(() {
          throw ArgumentError('test error!');
        });
      });

      verify(mockMyErrorListener.onError(ErrorType.dart, any, any, any))
          .called(1);
    });

    testWidgets('does not catch any error when widgets works as expected',
        (WidgetTester tester) async {
      MockMyErrorListener mockMyErrorListener = MockMyErrorListener();
      ErrorHandler errorHandler = ErrorHandler([mockMyErrorListener]);
      var workingWidget = const WorkingWidget();

      await tester.runAsync(() async {
        errorHandler.run(() => runApp(workingWidget));
      });

      verifyZeroInteractions(mockMyErrorListener);
    });

    testWidgets('reports flutter unhandled error', (WidgetTester tester) async {
      MockMyErrorListener mockMyErrorListener = MockMyErrorListener();
      ErrorHandler errorHandler = ErrorHandler([mockMyErrorListener]);
      var exceptionWidget = const ExceptionWidget();

      await tester.runAsync(() async {
        errorHandler.run(() => runApp(exceptionWidget));
      });

      verify(mockMyErrorListener.onError(ErrorType.flutter, any, any, any))
          .called(1);
    });

    test('reports an error manually', () {
      MockMyErrorListener mockMyErrorListener = MockMyErrorListener();
      ErrorHandler errorHandler = ErrorHandler([mockMyErrorListener]);

      var error = AlbaError('test error');
      errorHandler.report(ErrorType.other, error);

      verify(mockMyErrorListener.onError(ErrorType.other, error, any, any))
          .called(1);
    });
  });
}
