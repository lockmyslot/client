import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';

class ErrorDisplay extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const ErrorDisplay({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
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
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 16),
              Entrance(
                delay: const Duration(milliseconds: 140),
                child: Text(error, textAlign: TextAlign.center).p(),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
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
