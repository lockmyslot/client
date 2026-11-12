import 'package:flutter/material.dart';

/// Calculates the morphing border radius for an item in a connected M3 list.
///
/// - Single item: rounded on all 4 corners (`large`, default 16dp).
/// - First item: rounded on top (`large`), subtle on bottom (`small`, default 4dp).
/// - Middle items: subtle rounding on all corners (`small`).
/// - Last item: subtle on top (`small`), rounded on bottom (`large`).
BorderRadius getConnectedItemRadius(
  int index,
  int totalCount, {
  double large = 16.0,
  double small = 4.0,
}) {
  if (totalCount <= 1) {
    return BorderRadius.circular(large);
  }
  if (index == 0) {
    return BorderRadius.only(
      topLeft: Radius.circular(large),
      topRight: Radius.circular(large),
      bottomLeft: Radius.circular(small),
      bottomRight: Radius.circular(small),
    );
  }
  if (index == totalCount - 1) {
    return BorderRadius.only(
      topLeft: Radius.circular(small),
      topRight: Radius.circular(small),
      bottomLeft: Radius.circular(large),
      bottomRight: Radius.circular(large),
    );
  }
  return BorderRadius.all(Radius.circular(small));
}

/// Helper that builds a list of widgets with connected hairline gaps.
///
/// Ideal for passing directly to [SliverChildListDelegate] or [Column.children].
List<Widget> buildConnectedItems({
  required int itemCount,
  required Widget Function(int index, BorderRadius borderRadius) builder,
  double gap = 2.0,
}) {
  final items = <Widget>[];
  for (int i = 0; i < itemCount; i++) {
    if (i > 0) items.add(SizedBox(height: gap));
    items.add(builder(i, getConnectedItemRadius(i, itemCount)));
  }
  return items;
}

/// A Material 3 connected card that adapts its corner radii based on its
/// position in a list and maintains hairline separation.
class ConnectedCard extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;
  final int? index;
  final int? totalCount;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final BorderSide? borderSide;
  final double largeRadius;
  final double smallRadius;
  final EdgeInsetsGeometry? padding;

  const ConnectedCard({
    super.key,
    required this.child,
    this.borderRadius,
    this.index,
    this.totalCount,
    this.onTap,
    this.onLongPress,
    this.color,
    this.borderSide,
    this.largeRadius = 16.0,
    this.smallRadius = 4.0,
    this.padding,
  }) : assert(
          borderRadius != null || (index != null && totalCount != null),
          'Either borderRadius or both index and totalCount must be provided',
        );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveRadius = borderRadius ??
        getConnectedItemRadius(
          index!,
          totalCount!,
          large: largeRadius,
          small: smallRadius,
        );

    final effectiveBorderSide = borderSide ??
        BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        );

    Widget content = padding != null ? Padding(padding: padding!, child: child) : child;

    if (onTap != null || onLongPress != null) {
      content = InkWell(
        borderRadius: effectiveRadius,
        onTap: onTap,
        onLongPress: onLongPress,
        child: content,
      );
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: color ?? colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: effectiveRadius,
        side: effectiveBorderSide,
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }
}

/// A connected list section rendering items in a [Column] separated by hairline spacing.
class ConnectedListSection extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index, BorderRadius borderRadius) itemBuilder;
  final double gap;

  const ConnectedListSection({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.gap = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < itemCount; i++) ...[
          if (i > 0) SizedBox(height: gap),
          itemBuilder(context, i, getConnectedItemRadius(i, itemCount)),
        ],
      ],
    );
  }
}
