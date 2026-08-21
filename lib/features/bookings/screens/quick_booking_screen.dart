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
                    trailing: isSelected ? const Icon(Icons.check_outlined) : null,
                    title: Text(label(item)),
                    subtitle: subtitle != null ? Text(subtitle(item) ?? '') : null,
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
      subtitle: (g) => '${g.memberCount} member${g.memberCount == 1 ? '' : 's'}',
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
      subtitle: (r) => 'Capacity ${r.capacity} • ${r.slotDurationMinutes} min slots',
      selectedId: _selectedResourceId,
    );
    if (resource != null) {
      setState(() {
        _selectedResourceId = resource.id;
      });
    }
  }

  Widget _buildPickerCard({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback? onTap,
    bool enabled = true,
  }) {
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final textColor = enabled ? null : mutedColor;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 14, color: textColor),
                        const SizedBox(width: 4),
                        Text(label).small().muted(),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textColor != null ? TextStyle(color: textColor) : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_outlined, size: 20, color: textColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHint() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_outlined, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            const Text('Select a group and resource to start booking.').muted().p(),
          ],
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Book'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined),
          onPressed: () => context.pop(),
        ),
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => ErrorDisplay(
          error: err.toString(),
          onRetry: () => ref.read(myGroupsProvider.notifier).refresh(),
        ),
        data: (groups) {
          final hasValidInitialGroup = _selectedGroupId != null &&
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
              description: 'Create or join a group before you can book resources.',
              action: PrimaryButton(
                onPressed: () => context.push('/groups/create'),
                child: const Text('Create Your First Group'),
              ),
            );
          }

          final selectedGroup = _selectedGroupId != null
              ? groups.where((g) => g.id == _selectedGroupId).firstOrNull
              : null;
          final activeResources = (resourcesAsync?.value ?? const <Resource>[])
              .where((r) => r.isActive)
              .toList();

          final Widget resourcePicker;
          if (selectedGroupId == null) {
            resourcePicker = _buildPickerCard(
              label: 'Resource',
              value: 'Select a group first',
              icon: Icons.perm_media_outlined,
              onTap: null,
              enabled: false,
            );
          } else {
            resourcePicker = resourcesAsync!.when(
              loading: () => _buildPickerCard(
                label: 'Resource',
                value: 'Loading…',
                icon: Icons.perm_media_outlined,
                onTap: null,
                enabled: false,
              ),
              error: (err, _) => _buildPickerCard(
                label: 'Resource',
                value: 'Failed to load',
                icon: Icons.perm_media_outlined,
                onTap: null,
                enabled: false,
              ),
              data: (resources) {
                if (activeResources.isEmpty) {
                  return _buildPickerCard(
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
                return _buildPickerCard(
                  label: 'Resource',
                  value: selectedResource?.name ?? 'Select Resource',
                  icon: Icons.perm_media_outlined,
                  onTap: () => _pickResource(activeResources),
                );
              },
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildPickerCard(
                        label: 'Group',
                        value: selectedGroup?.name ?? 'Select Group',
                        icon: Icons.group_outlined,
                        onTap: () => _pickGroup(groups),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: resourcePicker),
                  ],
                ),
              ),
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