import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/booking_details_form.dart';
import '../../groups/providers/groups_provider.dart';
import '../../groups/screens/create_group_sheet.dart';
import '../../groups/data/models/group.dart';
import '../../groups/widgets/group_avatar.dart';
import '../../resources/providers/resources_provider.dart';
import '../../resources/data/models/resource.dart';
import '../../resources/widgets/resource_avatar.dart';
import '../../../core/ui/ui.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_display.dart';
import '../../../shared/widgets/m3_collapsing_app_bar.dart';

class QuickBookingScreen extends ConsumerStatefulWidget {
  final String? initialGroupId;

  const QuickBookingScreen({super.key, this.initialGroupId});

  @override
  ConsumerState<QuickBookingScreen> createState() => _QuickBookingScreenState();
}

class _QuickBookingScreenState extends ConsumerState<QuickBookingScreen> {
  String? _selectedGroupId;
  String? _selectedResourceId;
  bool _autoOpenedGroupPicker = false;
  bool _autoOpenResourcePicker = false;

  @override
  void initState() {
    super.initState();
    final initialGroupId = widget.initialGroupId;
    if (initialGroupId != null) {
      _selectedGroupId = initialGroupId;
      _autoOpenResourcePicker = true;
    }
  }

  Future<T?> _showPickerSheet<T>({
    required String title,
    required List<T> items,
    required String Function(T) label,
    required String Function(T) id,
    String? Function(T)? subtitle,
    Widget Function(T)? leading,
    String? selectedId,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(title).h4(),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isSelected = id(item) == selectedId;
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      selected: isSelected,
                      selectedTileColor:
                          cs.primaryContainer.withValues(alpha: 0.25),
                      leading: leading?.call(item),
                      trailing: isSelected
                          ? Icon(Icons.check_rounded, color: cs.primary)
                          : null,
                      title: Text(
                        label(item),
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? cs.primary : cs.onSurface,
                        ),
                      ),
                      subtitle: subtitle != null && subtitle(item) != null
                          ? Text(
                              subtitle(item)!,
                              style: TextStyle(
                                color: isSelected
                                    ? cs.primary.withValues(alpha: 0.8)
                                    : cs.onSurfaceVariant,
                              ),
                            )
                          : null,
                      onTap: () => Navigator.pop(context, item),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickGroup(List<Group> groups) async {
    final group = await _showPickerSheet<Group>(
      title: 'Select Group',
      items: groups,
      id: (g) => g.id,
      label: (g) => g.name,
      subtitle: (g) =>
          '${g.memberCount} member${g.memberCount == 1 ? '' : 's'}',
      leading: (g) => GroupAvatar(
        name: g.name,
        iconKey: g.icon,
        colorHex: g.color,
      ),
      selectedId: _selectedGroupId,
    );
    if (group != null && group.id != _selectedGroupId) {
      setState(() {
        _selectedGroupId = group.id;
        _selectedResourceId = null;
        _autoOpenResourcePicker = true;
      });
    }
  }

  Future<void> _pickResource(List<Resource> resources) async {
    final resource = await _showPickerSheet<Resource>(
      title: 'Select Resource',
      items: resources,
      id: (r) => r.id,
      label: (r) => r.name,
      subtitle: (r) =>
          'Capacity ${r.capacity} • ${AppDateUtils.formatSlotDuration(r.slotDurationMinutes)} slots',
      leading: (r) => ResourceAvatar(
        iconKey: r.icon,
        colorHex: r.color,
        name: r.name,
      ),
      selectedId: _selectedResourceId,
    );
    if (resource != null) {
      setState(() {
        _selectedResourceId = resource.id;
      });
    }
  }

  Widget _buildM3SelectorCard({
    required String label,
    required String value,
    required Widget leading,
    required VoidCallback? onTap,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Material(
      color: enabled
          ? cs.surfaceContainerLow
          : cs.surfaceContainerLowest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: enabled
              ? cs.outlineVariant.withValues(alpha: 0.6)
              : cs.outlineVariant.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: enabled
                            ? cs.onSurfaceVariant
                            : cs.onSurfaceVariant.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: enabled
                            ? cs.onSurface
                            : cs.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: enabled
                    ? cs.onSurfaceVariant
                    : cs.outline.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupPickerCell(List<Group> groups) {
    final cs = Theme.of(context).colorScheme;
    final selectedGroup = _selectedGroupId != null
        ? groups.where((g) => g.id == _selectedGroupId).firstOrNull
        : null;

    final Widget leading;
    if (selectedGroup != null) {
      leading = GroupAvatar(
        name: selectedGroup.name,
        iconKey: selectedGroup.icon,
        colorHex: selectedGroup.color,
        size: 28,
      );
    } else {
      leading = Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.groups_outlined, size: 16, color: cs.primary),
      );
    }

    return _buildM3SelectorCard(
      label: 'Group',
      value: selectedGroup?.name ?? 'Select Group',
      leading: leading,
      onTap: () => _pickGroup(groups),
    );
  }

  Widget _buildResourcePickerCell(AsyncValue<List<Resource>>? resourcesAsync) {
    final cs = Theme.of(context).colorScheme;

    if (_selectedGroupId == null) {
      return _buildM3SelectorCard(
        label: 'Resource',
        value: 'Select group first',
        leading: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.category_outlined,
            size: 16,
            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
          ),
        ),
        onTap: null,
        enabled: false,
      );
    }
    return resourcesAsync!.when(
      loading: () => _buildM3SelectorCard(
        label: 'Resource',
        value: 'Loading…',
        leading: const SizedBox(
          width: 28,
          height: 28,
          child: Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        onTap: null,
        enabled: false,
      ),
      error: (err, _) => _buildM3SelectorCard(
        label: 'Resource',
        value: 'Failed to load',
        leading: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: cs.errorContainer.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.error_outline, size: 16, color: cs.error),
        ),
        onTap: null,
        enabled: false,
      ),
      data: (resources) {
        final activeResources = resources.where((r) => r.isActive).toList();
        if (activeResources.isEmpty) {
          return _buildM3SelectorCard(
            label: 'Resource',
            value: 'No active resources',
            leading: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.category_outlined,
                size: 16,
                color: cs.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ),
            onTap: null,
            enabled: false,
          );
        }
        if (_autoOpenResourcePicker && _selectedResourceId == null) {
          _autoOpenResourcePicker = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _selectedResourceId == null) {
              _pickResource(activeResources);
            }
          });
        }
        final selectedResource = activeResources
            .where((r) => r.id == _selectedResourceId)
            .firstOrNull;

        final Widget leading;
        if (selectedResource != null) {
          leading = ResourceAvatar(
            iconKey: selectedResource.icon,
            colorHex: selectedResource.color,
            name: selectedResource.name,
            size: 28,
          );
        } else {
          leading = Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.category_outlined, size: 16, color: cs.primary),
          );
        }

        return _buildM3SelectorCard(
          label: 'Resource',
          value: selectedResource?.name ?? 'Select Resource',
          leading: leading,
          onTap: () => _pickResource(activeResources),
        );
      },
    );
  }

  Widget _buildHint() {
    return Entrance(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Entrance(
                delay: const Duration(milliseconds: 80),
                curve: Curves.elasticOut,
                child: Icon(
                  Icons.bolt_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Entrance(
                delay: const Duration(milliseconds: 160),
                child: const Text(
                  'Select a group and resource to start booking.',
                ).muted().p(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(myGroupsProvider);
    final selectedGroupId = _selectedGroupId;
    final resourcesAsync = selectedGroupId != null
        ? ref.watch(groupResourcesProvider(selectedGroupId))
        : null;

    final pickerToolbar = groupsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (groups) {
        if (groups.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildGroupPickerCell(groups)),
              const SizedBox(width: 8),
              Expanded(child: _buildResourcePickerCell(resourcesAsync)),
            ],
          ),
        );
      },
    );

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          M3CollapsingAppBar(
            title: const Text('Quick Book'),
            pinned: true,
            bottom: AppBarToolbar(
              height: 64,
              child: pickerToolbar,
            ),
          ),
        ],
        body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => ErrorDisplay(
          error: err.toString(),
          onRetry: () => ref.read(myGroupsProvider.notifier).refresh(),
        ),
        data: (groups) {
          final hasValidInitialGroup =
              _selectedGroupId != null &&
              groups.any((g) => g.id == _selectedGroupId);
          if (_selectedGroupId != null && !hasValidInitialGroup) {
            _selectedGroupId = null;
            _autoOpenResourcePicker = false;
          }

          if (!_autoOpenedGroupPicker && _selectedGroupId == null) {
            _autoOpenedGroupPicker = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _selectedGroupId == null) _pickGroup(groups);
            });
          }

          if (groups.isEmpty) {
            return EmptyState(
              icon: Icons.bolt_outlined,
              title: 'No Groups Yet',
              description:
                  'Create or join a group before you can book resources.',
              action: PrimaryButton(
                onPressed: () => CreateGroupSheet.show(context),
                child: const Text('Create Your First Group'),
              ),
            );
          }

          return Column(
            children: [
              if (_selectedGroupId != null && _selectedResourceId != null)
                Expanded(
                  child: BookingDetailsForm(
                    groupId: _selectedGroupId!,
                    resourceId: _selectedResourceId!,
                    onBookingSuccess: (_) {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/bookings');
                      }
                    },
                  ),
                )
              else
                Expanded(child: _buildHint()),
            ],
          );
        },
      ),
    ),
  );
}
}
