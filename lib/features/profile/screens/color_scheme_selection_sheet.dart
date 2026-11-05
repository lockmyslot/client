import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/color_scheme_provider.dart';
import '../../../core/ui/ui.dart';

class ColorSchemeSelectionSheet extends ConsumerWidget {
  const ColorSchemeSelectionSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ColorSchemeSelectionSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final colorSchemeState = ref.watch(appColorSchemeProvider);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cs.outlineVariant.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Color Scheme',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Choose between Material You or your preferred color scheme',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Option 1: Material You
          Material(
            color: colorSchemeState.isMaterialYou
                ? cs.primaryContainer.withValues(alpha: 0.25)
                : cs.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: colorSchemeState.isMaterialYou
                    ? cs.primary
                    : cs.outlineVariant.withValues(alpha: 0.4),
                width: colorSchemeState.isMaterialYou ? 2 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                ref.read(appColorSchemeProvider.notifier).setMaterialYou();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorSchemeState.isMaterialYou
                            ? cs.primary.withValues(alpha: 0.12)
                            : cs.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.auto_awesome_outlined,
                        size: 22,
                        color: colorSchemeState.isMaterialYou
                            ? cs.primary
                            : cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Material You',
                            style: TextStyle(
                              fontWeight: colorSchemeState.isMaterialYou
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              fontSize: 15,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Material You color based on your device wallpaper',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      colorSchemeState.isMaterialYou
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: colorSchemeState.isMaterialYou
                          ? cs.primary
                          : cs.outline,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Option 2: Preferred color scheme
          Material(
            color: !colorSchemeState.isMaterialYou
                ? cs.primaryContainer.withValues(alpha: 0.25)
                : cs.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: !colorSchemeState.isMaterialYou
                    ? cs.primary
                    : cs.outlineVariant.withValues(alpha: 0.4),
                width: !colorSchemeState.isMaterialYou ? 2 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                ref
                    .read(appColorSchemeProvider.notifier)
                    .setSource(ColorSchemeSource.preferred);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: !colorSchemeState.isMaterialYou
                                ? cs.primary.withValues(alpha: 0.12)
                                : cs.surfaceContainerHighest.withValues(
                                    alpha: 0.5,
                                  ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.palette_outlined,
                            size: 22,
                            color: !colorSchemeState.isMaterialYou
                                ? cs.primary
                                : cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Preferred color scheme',
                                style: TextStyle(
                                  fontWeight: !colorSchemeState.isMaterialYou
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  fontSize: 15,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'User\'s preferred color scheme (${colorSchemeState.preferredColorName})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          !colorSchemeState.isMaterialYou
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: !colorSchemeState.isMaterialYou
                              ? cs.primary
                              : cs.outline,
                          size: 22,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Select color palette',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Palette choices
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: kPreferredColorOptions.map((option) {
                        final isColorSelected = !colorSchemeState.isMaterialYou &&
                            colorSchemeState.preferredColor.toARGB32() ==
                                option.color.toARGB32();

                        return Tooltip(
                          message: option.label,
                          child: InkWell(
                            onTap: () {
                              ref
                                  .read(appColorSchemeProvider.notifier)
                                  .setPreferredColor(
                                    option.color,
                                    option.label,
                                  );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: option.color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isColorSelected
                                      ? cs.onSurface
                                      : cs.outlineVariant.withValues(alpha: 0.5),
                                  width: isColorSelected ? 2.5 : 1,
                                ),
                                boxShadow: isColorSelected
                                    ? [
                                        BoxShadow(
                                          color: option.color.withValues(
                                            alpha: 0.45,
                                          ),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: isColorSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 18,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          PrimaryButton(
            onPressed: () => Navigator.of(context).maybePop(),
            expand: true,
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
