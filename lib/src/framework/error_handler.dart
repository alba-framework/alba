import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// A error type.
enum ErrorType {
  /// Dart error.
  dart,

  /// Flutter error.
  flutter,

  /// Other error.
  other,
}

/// An error listener.
abstract class ErrorListener {
  /// The callback which is called when an error occurs.
  void onError(
    ErrorType type,
    Object error,
    StackTrace? stackTrace,
    FlutterErrorDetails? flutterErrorDetails,
  );
}

/// An error handler.
class ErrorHandler {
  final List<ErrorListener> _errorListeners;

  /// Creates an [ErrorHandler].
  ErrorHandler(this._errorListeners);

  /// Setups error handler and runs [body].
  void run(void Function() body) async {
    // Run body in a guarded zone to capture all uncaught errors.
    runZonedGuarded(() {
      WidgetsFlutterBinding.ensureInitialized();

      // Capture Flutter uncaught errors.
      FlutterError.onError = _onFlutterError;

      body();
    }, (Object error, StackTrace stackTrace) async {
      report(ErrorType.dart, error, stackTrace: stackTrace);
    });
  }

  void _onFlutterError(FlutterErrorDetails details) {
    report(
      ErrorType.flutter,
      details.exception,
      stackTrace: details.stack,
      flutterErrorDetails: details,
    );
  }

  /// Reports an error.
  void report(
    ErrorType type,
    dynamic error, {
    StackTrace? stackTrace,
    FlutterErrorDetails? flutterErrorDetails,
  }) {
    for (var listener in _errorListeners) {
      listener.onError(
        type,
        error,
        stackTrace,
        flutterErrorDetails,
      );
    }
  }
}

/// A simple error handler.
class DebugErrorListener implements ErrorListener {
  @override
  void onError(
    ErrorType type,
    Object error,
    StackTrace? stackTrace,
    FlutterErrorDetails? flutterErrorDetails,
  ) {
    if (kDebugMode) {
      if (ErrorType.flutter == type && null != flutterErrorDetails) {
        FlutterError.presentError(flutterErrorDetails);

        return;
      }

      debugPrint(
        '=================== CAUGHT ${type.toString().split('.').last.toUpperCase()} ERROR',
      );

      debugPrint(error.toString());

      if (null != stackTrace) {
        debugPrint(stackTrace.toString());
      }
    }
  }
}
