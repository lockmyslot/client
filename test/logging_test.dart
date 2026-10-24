import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockmyslot_app/core/utils/app_logger.dart';
import 'package:lockmyslot_app/core/utils/provider_logger.dart';

void main() {
  group('AppLogger', () {
    final capturedLogs = <Map<String, dynamic>>[];

    setUp(() {
      capturedLogs.clear();
      AppLogger.customHandler = (
        level,
        message, {
        required tag,
        error,
        stackTrace,
      }) {
        capturedLogs.add({
          'level': level,
          'message': message,
          'tag': tag,
          'error': error,
          'stackTrace': stackTrace,
        });
      };
    });

    tearDown(() {
      AppLogger.customHandler = null;
    });

    test('logs debug, info, warning and error messages correctly', () {
      AppLogger.debug('Debug message', tag: 'Test');
      AppLogger.info('Info message', tag: 'Test');
      AppLogger.warning('Warning message', tag: 'Test');
      final error = Exception('Failed');
      AppLogger.error('Error message', tag: 'Test', error: error);

      expect(capturedLogs.length, 4);
      expect(capturedLogs[0]['level'], LogLevel.debug);
      expect(capturedLogs[0]['message'], 'Debug message');

      expect(capturedLogs[1]['level'], LogLevel.info);
      expect(capturedLogs[1]['message'], 'Info message');

      expect(capturedLogs[2]['level'], LogLevel.warning);
      expect(capturedLogs[2]['message'], 'Warning message');

      expect(capturedLogs[3]['level'], LogLevel.error);
      expect(capturedLogs[3]['message'], 'Error message');
      expect(capturedLogs[3]['error'], error);
    });
  });

  group('AppProviderObserver', () {
    final capturedLogs = <Map<String, dynamic>>[];

    setUp(() {
      capturedLogs.clear();
      AppLogger.customHandler = (
        level,
        message, {
        required tag,
        error,
        stackTrace,
      }) {
        capturedLogs.add({
          'level': level,
          'message': message,
          'tag': tag,
          'error': error,
          'stackTrace': stackTrace,
        });
      };
    });

    tearDown(() {
      AppLogger.customHandler = null;
    });

    test('captures and logs provider failures', () {
      final failingProvider = Provider<String>((ref) {
        throw StateError('Provider initialization failure');
      });

      final container = ProviderContainer(
        observers: [const AppProviderObserver()],
      );

      try {
        container.read(failingProvider);
      } catch (_) {}

      expect(capturedLogs.isNotEmpty, isTrue);
      final errorLog = capturedLogs.firstWhere(
        (log) => log['level'] == LogLevel.error,
      );
      expect(errorLog['tag'], 'Riverpod');
      expect(errorLog['message'], contains('Provider failure'));
      expect(errorLog['error'], isA<StateError>());

      container.dispose();
    });

    test('logs state updates when logUpdates is enabled', () {
      final countProvider = StateProvider<int>((ref) => 0);
      final container = ProviderContainer(
        observers: [const AppProviderObserver(logUpdates: true)],
      );

      container.read(countProvider.notifier).state = 42;

      expect(
        capturedLogs.any(
          (log) =>
              log['level'] == LogLevel.debug &&
              log['tag'] == 'Riverpod' &&
              log['message'].toString().contains('updated'),
        ),
        isTrue,
      );

      container.dispose();
    });
  });
}
