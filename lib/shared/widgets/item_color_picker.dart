import 'package:flutter/material.dart';
import '../../core/theme/item_color_utils.dart';

/// An interactive horizontal row of color swatches for selecting an item's color.
/// Includes an option to choose "Theme Default" (null).
class ItemColorPickerRow extends StatelessWidget {
  final String? selectedHex;
  final ValueChanged<String?> onChanged;
  final String title;

  const ItemColorPickerRow({
    super.key,
    required this.selectedHex,
    required this.onChanged,
    this.title = 'Item Color',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isNoneSelected = selectedHex == null || selectedHex!.trim().isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
              if (!isNoneSelected)
                GestureDetector(
                  onTap: () => onChanged(null),
                  child: Text(
                    'Reset to theme',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              // Default Theme Swatch
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Tooltip(
                  message: 'Theme Default',
                  child: InkWell(
                    onTap: () => onChanged(null),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isNoneSelected
                            ? cs.primaryContainer
                            : cs.surfaceContainerHighest.withValues(alpha: 0.5),
                        border: Border.all(
                          color: isNoneSelected
                              ? cs.primary
                              : cs.outlineVariant.withValues(alpha: 0.5),
                          width: isNoneSelected ? 2.5 : 1,
                        ),
                      ),
                      child: Icon(
                        isNoneSelected ? Icons.check : Icons.palette_outlined,
                        size: 18,
                        color: isNoneSelected
                            ? cs.onPrimaryContainer
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),

              // Curated Color Swatches
              ...kItemColorPalette.map((option) {
                final isSelected = selectedHex != null &&
                    selectedHex!.toLowerCase() == option.hex.toLowerCase();

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Tooltip(
                    message: option.label,
                    child: InkWell(
                      onTap: () => onChanged(isSelected ? null : option.hex),
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: option.color,
                          border: Border.all(
                            color: isSelected
                                ? cs.onSurface
                                : Colors.transparent,
                            width: isSelected ? 2.5 : 0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: option.color.withValues(alpha: 0.4),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 18,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
