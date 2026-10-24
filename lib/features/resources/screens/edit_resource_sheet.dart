import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/resources_repository.dart';
import '../data/models/resource.dart';
import '../providers/resources_provider.dart';
import '../../../core/ui/ui.dart';

class EditResourceSheet extends ConsumerStatefulWidget {
  final String groupId;
  final Resource resource;
  final void Function(Resource resource)? onSuccess;
  final VoidCallback? onClose;

  const EditResourceSheet({
    super.key,
    required this.groupId,
    required this.resource,
    this.onSuccess,
    this.onClose,
  });

  static Future<Resource?> show(
    BuildContext context, {
    required String groupId,
    required Resource resource,
  }) {
    return showModalBottomSheet<Resource>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditResourceSheet(
        groupId: groupId,
        resource: resource,
      ),
    );
  }

  @override
  ConsumerState<EditResourceSheet> createState() => _EditResourceSheetState();
}

class _EditResourceSheetState extends ConsumerState<EditResourceSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _capacityController;
  late final TextEditingController _durationController;
  late bool _isActive;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.resource.name);
    _descController =
        TextEditingController(text: widget.resource.description ?? '');
    _capacityController =
        TextEditingController(text: widget.resource.capacity.toString());
    _durationController = TextEditingController(
      text: widget.resource.slotDurationMinutes.toString(),
    );
    _isActive = widget.resource.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _capacityController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final description = _descController.text.trim();
    final capacity =
        int.tryParse(_capacityController.text.trim()) ?? widget.resource.capacity;
    final duration =
        int.tryParse(_durationController.text.trim()) ??
        widget.resource.slotDurationMinutes;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(resourcesRepositoryProvider);
      final updatedResource = await repo.updateResource(
        widget.groupId,
        widget.resource.id,
        name: name,
        description: description,
        capacity: capacity,
        slotDurationMinutes: duration,
        isActive: _isActive,
      );

      ref.invalidate(groupResourcesProvider(widget.groupId));
      ref.invalidate(
        resourceDetailProvider((
          groupId: widget.groupId,
          resourceId: widget.resource.id,
        )),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Resource "${updatedResource.name}" updated'),
            behavior: SnackBarBehavior.floating,
          ),
        );

        if (widget.onSuccess != null) {
          widget.onSuccess!(updatedResource);
        } else {
          Navigator.of(context).pop(updatedResource);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Resource',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Update configuration for ${widget.resource.name}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      if (widget.onClose != null) {
                        widget.onClose!();
                      } else {
                        Navigator.of(context).maybePop();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),

              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Resource Name *',
                  hintText: 'e.g., Conference Room A, Tennis Court 1',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Resource name is required';
                  }
                  if (val.trim().length < 2) {
                    return 'Resource name must be at least 2 characters';
                  }
                  if (val.trim().length > 100) {
                    return 'Resource name must be at most 100 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Brief details about availability or amenities',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
                validator: (val) {
                  if (val != null && val.trim().length > 500) {
                    return 'Description must be at most 500 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _capacityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Capacity',
                        hintText: '1',
                        prefixIcon: Icon(Icons.people_outline),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Required';
                        }
                        final num = int.tryParse(val.trim());
                        if (num == null || num <= 0) {
                          return 'Must be > 0';
                        }
                        if (num > 100) {
                          return 'Max 100';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Slot Duration (m)',
                        hintText: '60',
                        prefixIcon: Icon(Icons.schedule_outlined),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Required';
                        }
                        final num = int.tryParse(val.trim());
                        if (num == null || num <= 0) {
                          return 'Must be > 0';
                        }
                        if (num < 15 || num > 1080) {
                          return '15 to 1080 mins';
                        }
                        if (num % 15 != 0) {
                          return 'Multiple of 15';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Material(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: const Text(
                    'Active for Bookings',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    _isActive
                        ? 'Resource is available for booking'
                        : 'Resource is disabled; new bookings cannot be placed',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  value: _isActive,
                  onChanged: (val) {
                    setState(() {
                      _isActive = val;
                    });
                  },
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: cs.error),
                ).small(),
              ],

              const SizedBox(height: 20),

              PrimaryButton(
                onPressed: _isLoading ? null : () => _handleUpdate(),
                expand: true,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
