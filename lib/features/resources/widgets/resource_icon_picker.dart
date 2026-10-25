import 'package:flutter/material.dart';
import 'resource_avatar.dart';

/// Interactive modal bottom sheet to pick from the list of common items icons
/// or choose to leave alone (use initials).
class ResourceIconPickerSheet extends StatefulWidget {
  final String? initialIconKey;
  final String resourceName;
  final ValueChanged<String?> onSelect;

  const ResourceIconPickerSheet({
    super.key,
    this.initialIconKey,
    required this.resourceName,
    required this.onSelect,
  });

  static Future<String?> show(
    BuildContext context, {
    String? currentIconKey,
    required String resourceName,
  }) {
    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ResourceIconPickerSheet(
        initialIconKey: currentIconKey,
        resourceName: resourceName,
        onSelect: (selectedKey) => Navigator.of(ctx).pop(selectedKey),
      ),
    );
  }

  @override
  State<ResourceIconPickerSheet> createState() =>
      _ResourceIconPickerSheetState();
}

class _ResourceIconPickerSheetState extends State<ResourceIconPickerSheet> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final initials = getResourceInitials(widget.resourceName);

    final filteredIcons = kCommonResourceIcons.where((item) {
      if (_searchQuery.trim().isEmpty) return true;
      return item.label.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.key.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Resource Icon',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Choose an item icon, or leave alone to use name initials',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search icons (e.g., washing machine, room, computer)...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),

          const Divider(height: 1),

          // Icon Options Grid & Initials Default Tile
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                // Option 1: Leave alone / Use Initials
                Material(
                  color: widget.initialIconKey == null
                      ? cs.primaryContainer.withValues(alpha: 0.4)
                      : cs.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: widget.initialIconKey == null
                          ? cs.primary
                          : cs.outlineVariant.withValues(alpha: 0.5),
                      width: widget.initialIconKey == null ? 1.5 : 1.0,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => widget.onSelect(null),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              initials,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Use Initials ("$initials")',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Default for left alone (no specific icon)',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.initialIconKey == null)
                            Icon(Icons.check_circle, color: cs.primary),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'COMMON RESOURCE ICONS',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                if (filteredIcons.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No icons matching "$_searchQuery"',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: filteredIcons.length,
                    itemBuilder: (context, index) {
                      final item = filteredIcons[index];
                      final isSelected = widget.initialIconKey == item.key;

                      return InkWell(
                        onTap: () => widget.onSelect(item.key),
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? cs.primaryContainer
                                : cs.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? cs.primary
                                  : cs.outlineVariant.withValues(alpha: 0.5),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                item.icon,
                                size: 30,
                                color: isSelected
                                    ? cs.onPrimaryContainer
                                    : cs.onSurface,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.label,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? cs.onPrimaryContainer
                                      : cs.onSurface,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A comprehensive form selector widget with live preview, quick-select chips,
/// and bottom sheet dialog launcher.
class ResourceIconSelector extends StatelessWidget {
  final String? selectedIconKey;
  final String resourceName;
  final ValueChanged<String?> onChanged;

  const ResourceIconSelector({
    super.key,
    required this.selectedIconKey,
    required this.resourceName,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final iconLabel = getResourceIconLabel(selectedIconKey);
    final initials = getResourceInitials(resourceName);

    // Prominent quick items: washing machine, room, computer, laptop, desk, tv
    final quickItems = kCommonResourceIcons.take(6).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Preview Avatar and Status
          Row(
            children: [
              ResourceAvatar(
                iconKey: selectedIconKey,
                name: resourceName,
                size: 48,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resource Icon',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selectedIconKey != null && iconLabel != null
                          ? '$iconLabel (selected)'
                          : 'Initials: "$initials" (left alone)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: selectedIconKey != null
                            ? cs.primary
                            : cs.onSurfaceVariant,
                        fontWeight: selectedIconKey != null
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final chosen = await ResourceIconPickerSheet.show(
                    context,
                    currentIconKey: selectedIconKey,
                    resourceName: resourceName,
                  );
                  if (chosen != selectedIconKey) {
                    onChanged(chosen);
                  }
                },
                icon: const Icon(Icons.grid_view, size: 16),
                label: const Text('Browse'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Row 2: Quick selector chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                // Left alone / Initials Chip
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: selectedIconKey == null
                            ? cs.onPrimary
                            : cs.primary,
                      ),
                    ),
                    label: const Text('Initials'),
                    selected: selectedIconKey == null,
                    onSelected: (selected) {
                      if (selected) onChanged(null);
                    },
                  ),
                ),

                // Quick item chips
                ...quickItems.map((item) {
                  final isSelected = selectedIconKey == item.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: Icon(
                        item.icon,
                        size: 16,
                        color: isSelected ? cs.onPrimary : cs.onSurface,
                      ),
                      label: Text(item.label),
                      selected: isSelected,
                      onSelected: (selected) {
                        onChanged(selected ? item.key : null);
                      },
                    ),
                  );
                }),

                // More... chip
                ActionChip(
                  avatar: const Icon(Icons.more_horiz, size: 16),
                  label: const Text('More...'),
                  onPressed: () async {
                    final chosen = await ResourceIconPickerSheet.show(
                      context,
                      currentIconKey: selectedIconKey,
                      resourceName: resourceName,
                    );
                    if (chosen != selectedIconKey) {
                      onChanged(chosen);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
