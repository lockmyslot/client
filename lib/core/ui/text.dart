import 'package:flutter/material.dart';

/// A fluent text-styling API that mirrors the shadcn text modifiers used
/// throughout the app, implemented on top of Material [DefaultTextStyle].
extension LockMySlotText on Widget {
  Widget _styled({
    TextStyle? Function(TextTheme textTheme, ColorScheme colorScheme)? style,
    TextAlign? textAlign,
    Widget Function(BuildContext context, Widget child)? wrapper,
  }) {
    Widget child = this;
    if (wrapper != null) {
      child = Builder(builder: (context) => wrapper(context, this));
    }
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return DefaultTextStyle.merge(
          child: child,
          style: style?.call(theme.textTheme, theme.colorScheme),
          textAlign: textAlign,
        );
      },
    );
  }

  /// Display / large heading.
  Widget h1() => _styled(
        style: (tt, _) => tt.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
      );

  /// Heading 2, with a bottom border (mirrors shadcn's h2).
  Widget h2() => _styled(
        style: (tt, _) => tt.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
        wrapper: (context, child) => Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: child,
            ),
          ),
        ),
      );

  /// Heading 3.
  Widget h3() => _styled(
        style: (tt, _) => tt.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
      );

  /// Heading 4.
  Widget h4() => _styled(
        style: (tt, _) => tt.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      );

  /// Paragraph with top spacing (mirrors shadcn's p).
  Widget p() => _styled(
        style: (tt, _) => tt.bodyMedium?.copyWith(height: 1.4),
        wrapper: (context, child) => Padding(
          padding: const EdgeInsets.only(top: 24),
          child: child,
        ),
      );

  /// Lead paragraph, muted color (mirrors shadcn's lead).
  Widget lead() => _styled(
        style: (tt, cs) => tt.bodyLarge?.copyWith(
              height: 1.4,
              color: cs.onSurfaceVariant,
            ),
      );

  /// Small text.
  Widget small() => _styled(
        style: (tt, _) => tt.bodySmall,
      );

  /// Small text (alias of [small]).
  Widget textSmall() => _styled(
        style: (tt, _) => tt.bodySmall,
      );

  /// Large text.
  Widget textLarge() => _styled(
        style: (tt, _) => tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      );

  /// Muted (secondary) foreground color.
  Widget muted() => _styled(
        style: (_, cs) => TextStyle(color: cs.onSurfaceVariant),
      );

  /// Monospace font family.
  Widget mono() => _styled(
        style: (_, __) => TextStyle(
          fontFamily: 'monospace',
          fontFamilyFallback: const ['Roboto Mono', 'Courier New'],
        ),
      );

  /// Semi-bold weight.
  Widget semiBold() => _styled(
        style: (_, __) => const TextStyle(fontWeight: FontWeight.w600),
      );

  /// Bold weight.
  Widget bold() => _styled(
        style: (_, __) => const TextStyle(fontWeight: FontWeight.bold),
      );

  /// Italic style.
  Widget italic() => _styled(
        style: (_, __) => const TextStyle(fontStyle: FontStyle.italic),
      );
}
