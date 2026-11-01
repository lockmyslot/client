import 'package:flutter/material.dart';

/// Extracts up to two initials from a group [name].
/// Words may be separated by spaces, hyphens, or underscores.
String getGroupInitials(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'G';

  final words = trimmed
      .split(RegExp(r'[\s\-_]+'))
      .where((w) => RegExp(r'[a-zA-Z0-9]').hasMatch(w))
      .toList();

  if (words.length >= 2) {
    final first = words[0].characters.firstWhere(
          (c) => RegExp(r'[a-zA-Z0-9]').hasMatch(c),
          orElse: () => words[0].characters.first,
        );
    final second = words[1].characters.firstWhere(
          (c) => RegExp(r'[a-zA-Z0-9]').hasMatch(c),
          orElse: () => words[1].characters.first,
        );
    return '$first$second'.toUpperCase();
  }

  if (words.isNotEmpty) {
    final word = words[0];
    if (word.length <= 2) {
      return word.toUpperCase();
    }
    return word.characters.first.toUpperCase();
  }

  return trimmed.characters.first.toUpperCase();
}

/// A standard avatar widget displaying a group's initials.
class GroupAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final BorderRadius? borderRadius;

  const GroupAvatar({
    super.key,
    required this.name,
    this.size = 40,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = backgroundColor ?? cs.primaryContainer;
    final fg = foregroundColor ?? cs.onPrimaryContainer;
    final radius = borderRadius ?? BorderRadius.circular(size * 0.25);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        getGroupInitials(name),
        style: TextStyle(
          fontSize: size * 0.34,
          fontWeight: FontWeight.bold,
          color: fg,
          letterSpacing: 0.5,
        ),
        maxLines: 1,
        overflow: TextOverflow.clip,
      ),
    );
  }
}
