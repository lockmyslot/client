import 'package:flutter/material.dart';

/// Material 3 Collapsing App Bar inspired by Android Settings.
///
/// Features:
/// - Prominent large title in the flexible space that smoothly fades out as the user scrolls up.
/// - Pinned toolbar title that seamlessly fades in and translates/slides upward into place as the large title disappears.
/// - Tonal circular back button when navigation back is available.
/// - Zero clipping or awkward jump between expanded and collapsed states.
class M3CollapsingAppBar extends StatelessWidget {
  const M3CollapsingAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.pinned = true,
    this.floating = false,
    this.expandedHeight = 152.0,
    this.collapsedHeight,
    this.bottom,
    this.backgroundColor,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final bool pinned;
  final bool floating;
  final double expandedHeight;
  final double? collapsedHeight;
  final PreferredSizeWidget? bottom;
  final Color? backgroundColor;

  Widget? _buildLeading(BuildContext context) {
    if (leading != null) return leading;
    if (!automaticallyImplyLeading) return null;

    final ScaffoldState? scaffold = Scaffold.maybeOf(context);
    if (scaffold?.hasDrawer ?? false) {
      return IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => scaffold!.openDrawer(),
      );
    }

    final ModalRoute<dynamic>? parentRoute = ModalRoute.of(context);
    final bool canPop = parentRoute?.canPop ?? false;
    if (!canPop) return null;

    final theme = Theme.of(context);
    return Center(
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
          shape: BoxShape.circle,
        ),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          icon: const Icon(Icons.arrow_back),
          iconSize: 20,
          padding: EdgeInsets.zero,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBg = backgroundColor ?? theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface;

    return SliverAppBar(
      pinned: pinned,
      floating: floating,
      expandedHeight: expandedHeight,
      collapsedHeight: collapsedHeight,
      automaticallyImplyLeading: false,
      leading: _buildLeading(context),
      actions: actions,
      bottom: bottom,
      backgroundColor: effectiveBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: _M3ToolbarTitle(title: title),
      flexibleSpace: _M3FlexibleSpace(
        title: title,
        subtitle: subtitle,
        expandedHeight: expandedHeight,
      ),
    );
  }
}

class _M3ToolbarTitle extends StatelessWidget {
  const _M3ToolbarTitle({required this.title});

  final Widget title;

  @override
  Widget build(BuildContext context) {
    final settings = context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    final theme = Theme.of(context);

    double progress = 1.0;
    if (settings != null) {
      final double deltaExtent = settings.maxExtent - settings.minExtent;
      if (deltaExtent > 0) {
        progress = (1.0 - (settings.currentExtent - settings.minExtent) / deltaExtent).clamp(0.0, 1.0);
      }
    }

    // Title fades in and slides up subtly between progress 0.48 and 1.0
    final double titleProgress = ((progress - 0.48) / 0.52).clamp(0.0, 1.0);
    final double curve = Curves.easeOutCubic.transform(titleProgress);
    final double opacity = curve;
    final double slideY = (1.0 - curve) * 8.0;

    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(0, slideY),
        child: DefaultTextStyle.merge(
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ) ?? TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          child: title,
        ),
      ),
    );
  }
}

class _M3FlexibleSpace extends StatelessWidget {
  const _M3FlexibleSpace({
    required this.title,
    this.subtitle,
    required this.expandedHeight,
  });

  final Widget title;
  final Widget? subtitle;
  final double expandedHeight;

  @override
  Widget build(BuildContext context) {
    final settings = context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    final theme = Theme.of(context);

    double progress = 0.0;
    if (settings != null) {
      final double deltaExtent = settings.maxExtent - settings.minExtent;
      if (deltaExtent > 0) {
        progress = (1.0 - (settings.currentExtent - settings.minExtent) / deltaExtent).clamp(0.0, 1.0);
      }
    }

    // Large title fades out smoothly between progress 0.0 and 0.55
    final double fadeOutProgress = (progress / 0.55).clamp(0.0, 1.0);
    final double opacity = 1.0 - Curves.easeInOut.transform(fadeOutProgress);

    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRect(
          child: Container(
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Opacity(
              opacity: opacity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultTextStyle.merge(
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ) ?? TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    child: title,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 6),
                    DefaultTextStyle.merge(
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ) ?? TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      child: subtitle!,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
