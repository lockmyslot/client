import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_logger.dart';

/// Observer to monitor and log Riverpod state failures and lifecycle events.
class AppProviderObserver extends ProviderObserver {
  const AppProviderObserver({this.logUpdates = false});

  /// Set to true if fine-grained state mutations should be logged in debug mode.
  final bool logUpdates;

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    AppLogger.error(
      'Provider failure in "${provider.name ?? provider.runtimeType}"',
      tag: 'Riverpod',
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (logUpdates) {
      AppLogger.debug(
        'Provider "${provider.name ?? provider.runtimeType}" updated',
        tag: 'Riverpod',
      );
    }
  }
}
