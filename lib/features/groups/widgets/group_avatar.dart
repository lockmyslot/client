import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/item_color_provider.dart';
import '../../../core/theme/item_color_utils.dart';
import '../../resources/widgets/resource_avatar.dart';

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

/// A standard avatar widget displaying either a group's selected icon or initials,
/// with support for custom color coding or theme fallback based on user preference.
class GroupAvatar extends ConsumerWidget {
  final String name;
  final String? iconKey;
  final String? colorHex;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final BorderRadius? borderRadius;
  final bool? useItemColors;

  const GroupAvatar({
    super.key,
    required this.name,
    this.iconKey,
    this.colorHex,
    this.size = 40,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.useItemColors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    bool shouldShowColor = useItemColors ?? true;
    if (useItemColors == null) {
      try {
        shouldShowColor = ref.watch(itemColorPreferenceProvider);
      } catch (_) {
        shouldShowColor = true;
      }
    }

    final parsedColor = parseHexColor(colorHex);
    final style = getItemColorStyle(
      itemColor: parsedColor,
      useItemColors: shouldShowColor,
      colorScheme: cs,
      isDark: isDark,
    );

    final bg = backgroundColor ?? style.background;
    final fg = foregroundColor ?? style.foreground;
    final border = (backgroundColor == null && foregroundColor == null)
        ? style.border
        : cs.outlineVariant.withValues(alpha: 0.35);
    final radius = borderRadius ?? BorderRadius.circular(size * 0.25);
    final iconData = getResourceIcon(iconKey);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border.all(color: border),
      ),
      alignment: Alignment.center,
      child: iconData != null
          ? Icon(
              iconData,
              size: size * 0.52,
              color: fg,
            )
          : Text(
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
