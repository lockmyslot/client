import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/utils/app_logger.dart';
import 'core/utils/provider_logger.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch and log uncaught Flutter framework errors (widget tree, rendering errors)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    AppLogger.error(
      'Flutter error: ${details.exceptionAsString()}',
      tag: 'FlutterError',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  // Catch and log uncaught asynchronous errors (Futures, isolates, native platform calls)
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    AppLogger.error(
      'Uncaught async error',
      tag: 'PlatformDispatcher',
      error: error,
      stackTrace: stack,
    );
    return true;
  };

  runApp(
    const ProviderScope(
      observers: [AppProviderObserver()],
      child: LockMySlotApp(),
    ),
  );
}
