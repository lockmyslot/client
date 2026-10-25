import 'package:flutter/material.dart';

class ResourceIconOption {
  final String key;
  final String label;
  final IconData icon;

  const ResourceIconOption({
    required this.key,
    required this.label,
    required this.icon,
  });
}

/// List of common resource items icons.
/// Definitely includes: washing machine, room, computer.
const List<ResourceIconOption> kCommonResourceIcons = [
  ResourceIconOption(
    key: 'washing_machine',
    label: 'Washing Machine',
    icon: Icons.local_laundry_service,
  ),
  ResourceIconOption(
    key: 'room',
    label: 'Room',
    icon: Icons.meeting_room,
  ),
  ResourceIconOption(
    key: 'computer',
    label: 'Computer',
    icon: Icons.computer,
  ),
  ResourceIconOption(
    key: 'laptop',
    label: 'Laptop',
    icon: Icons.laptop,
  ),
  ResourceIconOption(
    key: 'tv',
    label: 'TV / Display',
    icon: Icons.tv,
  ),
  ResourceIconOption(
    key: 'projector',
    label: 'Projector',
    icon: Icons.videocam,
  ),
  ResourceIconOption(
    key: 'printer',
    label: 'Printer',
    icon: Icons.print,
  ),
  ResourceIconOption(
    key: 'desk',
    label: 'Desk',
    icon: Icons.desk,
  ),
  ResourceIconOption(
    key: 'conference_room',
    label: 'Conference Room',
    icon: Icons.co_present,
  ),
  ResourceIconOption(
    key: 'gym',
    label: 'Gym & Fitness',
    icon: Icons.fitness_center,
  ),
  ResourceIconOption(
    key: 'sports',
    label: 'Sports / Court',
    icon: Icons.sports_tennis,
  ),
  ResourceIconOption(
    key: 'game',
    label: 'Gaming',
    icon: Icons.sports_esports,
  ),
  ResourceIconOption(
    key: 'kitchen',
    label: 'Kitchen',
    icon: Icons.kitchen,
  ),
  ResourceIconOption(
    key: 'coffee',
    label: 'Coffee Machine',
    icon: Icons.coffee,
  ),
  ResourceIconOption(
    key: 'car',
    label: 'Car / Vehicle',
    icon: Icons.directions_car,
  ),
  ResourceIconOption(
    key: 'bike',
    label: 'Bicycle',
    icon: Icons.pedal_bike,
  ),
  ResourceIconOption(
    key: 'tools',
    label: 'Tools & Workshop',
    icon: Icons.handyman,
  ),
  ResourceIconOption(
    key: 'music',
    label: 'Music / Studio',
    icon: Icons.piano,
  ),
  ResourceIconOption(
    key: 'book',
    label: 'Library / Books',
    icon: Icons.menu_book,
  ),
  ResourceIconOption(
    key: 'pool',
    label: 'Swimming Pool',
    icon: Icons.pool,
  ),
];

/// Returns the IconData matching [iconKey], or null if not found.
IconData? getResourceIcon(String? iconKey) {
  if (iconKey == null || iconKey.trim().isEmpty) return null;
  final match = kCommonResourceIcons.where((item) => item.key == iconKey.trim());
  if (match.isNotEmpty) {
    return match.first.icon;
  }
  return null;
}

/// Returns the label matching [iconKey], or null if not found.
String? getResourceIconLabel(String? iconKey) {
  if (iconKey == null || iconKey.trim().isEmpty) return null;
  final match = kCommonResourceIcons.where((item) => item.key == iconKey.trim());
  if (match.isNotEmpty) {
    return match.first.label;
  }
  return null;
}

/// Extracts initials from resource [name].
/// If name has multiple words: first letters of first 2 words (e.g. "Washing Machine" -> "WM").
/// If name has 1 word: first 2 characters (e.g. "Room" -> "RO", "Computer" -> "CO").
/// If left alone / empty: "?".
String getResourceInitials(String? name) {
  if (name == null || name.trim().isEmpty) return '?';
  final parts =
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.length >= 2) {
    final first = parts[0].isNotEmpty ? parts[0][0] : '';
    final second = parts[1].isNotEmpty ? parts[1][0] : '';
    final res = '$first$second'.toUpperCase();
    return res.isNotEmpty ? res : '?';
  } else {
    final word = parts[0];
    if (word.length >= 2) {
      return word.substring(0, 2).toUpperCase();
    }
    return word.toUpperCase();
  }
}

/// A standard avatar widget displaying either the resource's selected icon
/// or initials if left alone.
class ResourceAvatar extends StatelessWidget {
  final String? iconKey;
  final String name;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final BorderRadius? borderRadius;

  const ResourceAvatar({
    super.key,
    this.iconKey,
    required this.name,
    this.size = 40,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bg = backgroundColor ?? cs.primaryContainer;
    final fg = foregroundColor ?? cs.onPrimaryContainer;
    final radius = borderRadius ?? BorderRadius.circular(size * 0.28);
    final iconData = getResourceIcon(iconKey);

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
      child: iconData != null
          ? Icon(
              iconData,
              size: size * 0.52,
              color: fg,
            )
          : Text(
              getResourceInitials(name),
              style: TextStyle(
                fontSize: size * 0.38,
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
