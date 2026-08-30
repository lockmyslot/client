import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';

class ErrorDisplay extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const ErrorDisplay({super.key, required this.error, this.onRetry});

  bool get _isOffline =>
      error.toLowerCase().contains('offline') ||
      error.toLowerCase().contains('network') ||
      error.toLowerCase().contains('connection');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = _isOffline ? Icons.wifi_off_outlined : Icons.error_outline;
    final iconColor = _isOffline
        ? theme.colorScheme.tertiary
        : theme.colorScheme.error;

    return Entrance(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Entrance(
                delay: const Duration(milliseconds: 60),
                curve: Curves.elasticOut,
                child: Icon(
                  icon,
                  size: 48,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 16),
              if (_isOffline) ...[
                Entrance(
                  delay: const Duration(milliseconds: 100),
                  child: const Text('Offline Mode').h3(),
                ),
                const SizedBox(height: 6),
              ],
              Entrance(
                delay: const Duration(milliseconds: 140),
                child: Text(error, textAlign: TextAlign.center).p().muted(),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 20),
                Entrance(
                  delay: const Duration(milliseconds: 220),
                  child: OutlineButton(
                    onPressed: onRetry,
                    child: const Text('Try Again'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

