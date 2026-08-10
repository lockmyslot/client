import 'package:shadcn_flutter/shadcn_flutter.dart';

class ErrorDisplay extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const ErrorDisplay({
    super.key,
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
            ).p(),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlineButton(
                onPressed: onRetry,
                child: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
