import 'package:shadcn_flutter/shadcn_flutter.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
            ).h3(),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
            ).muted().p(),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
