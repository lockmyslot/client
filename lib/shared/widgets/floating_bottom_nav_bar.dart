import 'dart:ui';
import 'package:flutter/material.dart';

class FloatingBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final double? pageProgress;
  final ValueChanged<int> onTap;
  final VoidCallback? onFabPressed;
  final IconData? fabIcon;
  final String? fabTooltip;

  const FloatingBottomNavBar({
    super.key,
    required this.currentIndex,
    this.pageProgress,
    required this.onTap,
    this.onFabPressed,
    this.fabIcon,
    this.fabTooltip,
  });

  double _getTabWidth(BuildContext context, String label) {
    final textTheme = Theme.of(context).textTheme;
    final style = (textTheme.labelSmall ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w600,
      fontSize: 11,
      letterSpacing: 0.1,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: label, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    // Horizontal padding + textPainter width (minimum width 64.0)
    const minWidth = 64.0;
    final widthWithPadding = textPainter.size.width + 24.0;
    return widthWithPadding < minWidth ? minWidth : widthWithPadding;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    final isRouteCurrent = ModalRoute.of(context)?.isCurrent ?? true;

    // Automatically hide floating tab bar when keyboard or modal elements (bottom sheets, dialogs) appear
    final isHidden = viewInsetsBottom > 0 || !isRouteCurrent;

    final items = const [
      _NavItemData(
        label: 'Groups',
        icon: Icons.group_outlined,
        activeIcon: Icons.group,
      ),
      _NavItemData(
        label: 'Bookings',
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_today,
      ),
      _NavItemData(
        label: 'Me',
        icon: Icons.person_outline,
        activeIcon: Icons.person,
      ),
    ];

    final currentProgress =
        (pageProgress ?? currentIndex.toDouble()).clamp(0.0, 2.0);
    final hasFab = onFabPressed != null && fabIcon != null;

    final blurGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        colorScheme.surfaceContainerHigh.withValues(alpha: 0.78),
        colorScheme.surfaceContainer.withValues(alpha: 0.58),
      ],
    );

    // Dynamic width and left offset calculations for each tab
    const double itemMargin = 4.0;
    final double maxTabWidth = items
        .map((item) => _getTabWidth(context, item.label))
        .reduce((a, b) => a > b ? a : b);
    final List<double> tabWidths = List.filled(items.length, maxTabWidth);

    final List<double> tabLefts = [];
    double currentLeftOffset = 0.0;
    for (int i = 0; i < tabWidths.length; i++) {
      tabLefts.add(currentLeftOffset);
      currentLeftOffset += tabWidths[i] + itemMargin;
    }

    final double totalTabsWidth =
        tabWidths.reduce((a, b) => a + b) + (itemMargin * (items.length - 1));

    // Interpolate current highlight pill width and left position
    double slidingLeft;
    double slidingWidth;

    if (currentProgress <= 1.0) {
      final t = currentProgress;
      slidingLeft = lerpDouble(tabLefts[0], tabLefts[1], t)!;
      slidingWidth = lerpDouble(tabWidths[0], tabWidths[1], t)!;
    } else {
      final t = currentProgress - 1.0;
      slidingLeft = lerpDouble(tabLefts[1], tabLefts[2], t)!;
      slidingWidth = lerpDouble(tabWidths[1], tabWidths[2], t)!;
    }

    return AnimatedSlide(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOutCubic,
      offset: isHidden ? const Offset(0, 1.8) : Offset.zero,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: isHidden ? 0.0 : 1.0,
        child: SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Navigation Tabs Floating Pill with Sliding Highlight
                  Material(
                    elevation: 3,
                    shadowColor: colorScheme.shadow.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(26),
                    color: Colors.transparent,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(26),
                            gradient: blurGradient,
                            border: Border.all(
                              color: colorScheme.outlineVariant
                                  .withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: SizedBox(
                            width: totalTabsWidth,
                            height: 44,
                            child: Stack(
                              children: [
                                // Sliding Highlight Pill Background
                                Positioned(
                                  left: slidingLeft,
                                  top: 0,
                                  width: slidingWidth,
                                  height: 44,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: colorScheme.secondaryContainer,
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                  ),
                                ),

                                // Tab Items Row (Vertical Icon + Label)
                                Row(
                                  children: List.generate(items.length, (index) {
                                    final item = items[index];
                                    final itemWidth = tabWidths[index];
                                    final distance =
                                        (currentProgress - index).abs();
                                    final selectionAmount =
                                        (1.0 - distance).clamp(0.0, 1.0);

                                    final contentColor = Color.lerp(
                                      colorScheme.onSurfaceVariant,
                                      colorScheme.onSecondaryContainer,
                                      selectionAmount,
                                    )!;

                                    return Padding(
                                      padding: EdgeInsets.only(
                                        right: index < items.length - 1
                                            ? itemMargin
                                            : 0,
                                      ),
                                      child: SizedBox(
                                        width: itemWidth,
                                        height: 44,
                                        child: Tooltip(
                                          message: item.label,
                                          child: Material(
                                            color: Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(22),
                                            clipBehavior: Clip.antiAlias,
                                            child: InkWell(
                                              onTap: () => onTap(index),
                                              borderRadius:
                                                  BorderRadius.circular(22),
                                              splashColor: colorScheme.primary
                                                  .withValues(alpha: 0.12),
                                              highlightColor:
                                                  Colors.transparent,
                                              child: Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      selectionAmount > 0.5
                                                          ? item.activeIcon
                                                          : item.icon,
                                                      size: 20,
                                                      color: contentColor,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      item.label,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: (textTheme
                                                                  .labelSmall ??
                                                              const TextStyle())
                                                          .copyWith(
                                                        color: contentColor,
                                                        fontWeight:
                                                            selectionAmount >
                                                                    0.5
                                                                ? FontWeight
                                                                    .w600
                                                                : FontWeight
                                                                    .w500,
                                                        fontSize: 11,
                                                        letterSpacing: 0.1,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 2. Separate Circle Action Button
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOutCubic,
                    child: hasFab
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 10),
                              Tooltip(
                                message: fabTooltip ?? 'Action',
                                child: Material(
                                  elevation: 3,
                                  shadowColor: colorScheme.shadow
                                      .withValues(alpha: 0.12),
                                  color: Colors.transparent,
                                  shape: const CircleBorder(),
                                  clipBehavior: Clip.antiAlias,
                                  child: ClipOval(
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 12,
                                        sigmaY: 12,
                                      ),
                                      child: Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: blurGradient,
                                          border: Border.all(
                                            color: colorScheme.outlineVariant
                                                .withValues(alpha: 0.35),
                                            width: 1,
                                          ),
                                        ),
                                        child: InkWell(
                                          onTap: onFabPressed,
                                          customBorder: const CircleBorder(),
                                          child: Center(
                                            child: AnimatedSwitcher(
                                              duration: const Duration(
                                                milliseconds: 150,
                                              ),
                                              transitionBuilder:
                                                  (child, animation) =>
                                                      FadeTransition(
                                                opacity: animation,
                                                child: ScaleTransition(
                                                  scale: animation,
                                                  child: child,
                                                ),
                                              ),
                                              child: Icon(
                                                fabIcon,
                                                key: ValueKey(fabIcon),
                                                size: 22,
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItemData({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
