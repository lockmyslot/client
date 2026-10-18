import 'package:flutter/material.dart';

class FloatingBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onFabPressed;
  final IconData? fabIcon;
  final String? fabTooltip;

  const FloatingBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onFabPressed,
    this.fabIcon,
    this.fabTooltip,
  });

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

    final hasFab = onFabPressed != null && fabIcon != null;

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
                  // 1. Navigation Tabs Floating Pill
                  Material(
                    elevation: 3,
                    shadowColor: colorScheme.shadow.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(32),
                    color: colorScheme.surfaceContainerHigh,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withOpacity(0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(items.length, (index) {
                          final item = items[index];
                          final isSelected = index == currentIndex;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Tooltip(
                              message: item.label,
                              child: Material(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(24),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () => onTap(index),
                                  borderRadius: BorderRadius.circular(24),
                                  splashColor:
                                      colorScheme.primary.withOpacity(0.12),
                                  highlightColor: Colors.transparent,
                                  child: AnimatedContainer(
                                    duration: const Duration(
                                      milliseconds: 200,
                                    ),
                                    curve: Curves.easeInOutCubic,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? colorScheme.secondaryContainer
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isSelected
                                              ? item.activeIcon
                                              : item.icon,
                                          size: 20,
                                          color: isSelected
                                              ? colorScheme.onSecondaryContainer
                                              : colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          item.label,
                                          style: (textTheme.labelMedium ??
                                                  const TextStyle())
                                              .copyWith(
                                            color: isSelected
                                                ? colorScheme.onSecondaryContainer
                                                : colorScheme.onSurfaceVariant,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
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
                              const SizedBox(width: 8),
                              Tooltip(
                                message: fabTooltip ?? 'Action',
                                child: Material(
                                  elevation: 3,
                                  shadowColor:
                                      colorScheme.shadow.withOpacity(0.14),
                                  color: colorScheme.surfaceContainerHigh,
                                  shape: const CircleBorder(),
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    onTap: onFabPressed,
                                    customBorder: const CircleBorder(),
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: colorScheme.outlineVariant
                                              .withOpacity(0.35),
                                          width: 1,
                                        ),
                                      ),
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
                                          size: 20,
                                          color: colorScheme.primary,
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
