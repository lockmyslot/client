import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/booking_details_form.dart';
import '../../groups/providers/groups_provider.dart';
import '../../groups/data/models/group.dart';
import '../../resources/providers/resources_provider.dart';
import '../../resources/data/models/resource.dart';
import '../../../core/ui/ui.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_display.dart';

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
    String? selectedId,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(title).h4(),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = id(item) == selectedId;
                  return ListTile(
                    trailing: isSelected
                        ? const Icon(Icons.check_outlined)
                        : null,
                    title: Text(label(item)),
                    subtitle: subtitle != null
                        ? Text(subtitle(item) ?? '')
                        : null,
                    onTap: () => Navigator.pop(context, item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
          'Capacity ${r.capacity} • ${r.slotDurationMinutes} min slots',
      selectedId: _selectedResourceId,
    );
    if (resource != null) {
      setState(() {
        _selectedResourceId = resource.id;
      });
    }
  }

  Widget _buildToolbarPickerCell({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback? onTap,
    bool enabled = true,
  }) {
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final textColor = enabled ? null : mutedColor;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label).small().muted(),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textColor != null
                        ? TextStyle(color: textColor)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_outlined, size: 18, color: textColor),
          ],
        ),
      ),
    );
  }

  Widget _toolbarDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }

  Widget _buildResourcePickerCell(AsyncValue<List<Resource>>? resourcesAsync) {
    if (_selectedGroupId == null) {
      return _buildToolbarPickerCell(
        label: 'Resource',
        value: 'Select a group first',
        icon: Icons.perm_media_outlined,
        onTap: null,
        enabled: false,
      );
    }
    return resourcesAsync!.when(
      loading: () => _buildToolbarPickerCell(
        label: 'Resource',
        value: 'Loading…',
        icon: Icons.perm_media_outlined,
        onTap: null,
        enabled: false,
      ),
      error: (err, _) => _buildToolbarPickerCell(
        label: 'Resource',
        value: 'Failed to load',
        icon: Icons.perm_media_outlined,
        onTap: null,
        enabled: false,
      ),
      data: (resources) {
        final activeResources = resources.where((r) => r.isActive).toList();
        if (activeResources.isEmpty) {
          return _buildToolbarPickerCell(
            label: 'Resource',
            value: 'No active resources',
            icon: Icons.perm_media_outlined,
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
        return _buildToolbarPickerCell(
          label: 'Resource',
          value: selectedResource?.name ?? 'Select Resource',
          icon: Icons.perm_media_outlined,
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
        final selectedGroup = _selectedGroupId != null
            ? groups.where((g) => g.id == _selectedGroupId).firstOrNull
            : null;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _buildToolbarPickerCell(
                label: 'Group',
                value: selectedGroup?.name ?? 'Select Group',
                icon: Icons.group_outlined,
                onTap: () => _pickGroup(groups),
              ),
            ),
            _toolbarDivider(context),
            Expanded(child: _buildResourcePickerCell(resourcesAsync)),
          ],
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Book'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined),
          onPressed: () => context.pop(),
        ),
        bottom: AppBarToolbar(child: pickerToolbar),
      ),
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
                onPressed: () => context.push('/groups/create'),
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
                  ),
                )
              else
                Expanded(child: _buildHint()),
            ],
          );
        },
      ),
    );
  }
}
