import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';

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
    final cs = Theme.of(context).colorScheme;
    return Entrance(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Entrance(
                delay: const Duration(milliseconds: 60),
                curve: Curves.elasticOut,
                child: Icon(icon, size: 56, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Entrance(
                delay: const Duration(milliseconds: 140),
                child: Text(title, textAlign: TextAlign.center).h3(),
              ),
              const SizedBox(height: 8),
              Entrance(
                delay: const Duration(milliseconds: 220),
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                ).muted().p(),
              ),
              if (action != null) ...[
                const SizedBox(height: 24),
                Entrance(
                  delay: const Duration(milliseconds: 300),
                  child: action!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
