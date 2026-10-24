import 'package:flutter/material.dart';

/// Standard padding used across all content list cards.
const EdgeInsets kCardPadding = EdgeInsets.fromLTRB(16, 14, 16, 14);

/// Primary action button (maps shadcn [PrimaryButton] to Material [FilledButton]).
class PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool expand;

  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(padding: padding),
      child: child,
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Secondary action button (maps shadcn [SecondaryButton] to Material [OutlinedButton]).
class SecondaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool expand;

  const SecondaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final button = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(padding: padding),
      child: child,
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Outline action button (maps shadcn [OutlineButton] to Material [TextButton]).
class OutlineButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final ButtonStyle? style;

  const OutlineButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(padding: padding).merge(style),
      child: child,
    );
  }
}

/// Attaches action content to the bottom of an [AppBar] so it reads as part
/// of the top bar. Pass to `AppBar(bottom: ...)`.
class AppBarToolbar extends StatelessWidget implements PreferredSizeWidget {
  final Widget child;
  final double height;

  const AppBarToolbar({super.key, required this.child, this.height = 48});

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: child,
      ),
    );
  }
}

/// A small status pill (maps shadcn [PrimaryBadge]).
class PrimaryBadge extends StatelessWidget {
  final Widget child;

  const PrimaryBadge({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(
          color: cs.onPrimaryContainer,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        child: child,
      ),
    );
  }
}

/// A modern pill chip displaying a KPI metric with an icon, value, optional label, and optional tap action.
class KpiStatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String? label;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? backgroundColor;
  final bool isMonospace;
  final Widget? trailing;

  const KpiStatChip({
    super.key,
    required this.icon,
    required this.value,
    this.label,
    this.onTap,
    this.iconColor,
    this.backgroundColor,
    this.isMonospace = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final chipShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: cs.outlineVariant.withValues(alpha: 0.5),
        width: 1,
      ),
    );

    return Material(
      color: backgroundColor ?? cs.surfaceContainerLow,
      shape: chipShape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: iconColor ?? cs.primary,
              ),
              const SizedBox(width: 8),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: value,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        fontFamily: isMonospace ? 'monospace' : null,
                        color: cs.onSurface,
                      ),
                    ),
                    if (label != null && label!.isNotEmpty) ...[
                      const TextSpan(text: ' '),
                      TextSpan(
                        text: label,
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 6),
                trailing!,
              ] else if (onTap != null) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
