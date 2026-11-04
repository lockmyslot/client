import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/resources_repository.dart';
import '../data/models/resource.dart';
import '../data/models/slot_duration_unit.dart';
import '../providers/resources_provider.dart';
import '../widgets/resource_icon_picker.dart';
import '../../../core/ui/ui.dart';

class CreateResourceSheet extends ConsumerStatefulWidget {
  final String groupId;
  final String? groupName;
  final void Function(Resource resource)? onSuccess;
  final VoidCallback? onClose;

  const CreateResourceSheet({
    super.key,
    required this.groupId,
    this.groupName,
    this.onSuccess,
    this.onClose,
  });

  static Future<Resource?> show(
    BuildContext context, {
    required String groupId,
    String? groupName,
  }) {
    return showModalBottomSheet<Resource>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateResourceSheet(
        groupId: groupId,
        groupName: groupName,
      ),
    );
  }

  @override
  ConsumerState<CreateResourceSheet> createState() =>
      _CreateResourceSheetState();
}

class _CreateResourceSheetState extends ConsumerState<CreateResourceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _capacityController = TextEditingController(text: '1');
  final _durationController = TextEditingController(text: '60');
  SlotDurationUnit _selectedUnit = SlotDurationUnit.minutes;
  String? _selectedIcon;
  String? _selectedColor;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    if (mounted) setState(() {});
  }

  void _onUnitChanged(SlotDurationUnit newUnit) {
    final currentVal = int.tryParse(_durationController.text.trim());
    if (currentVal != null && currentVal > 0) {
      final newVal = SlotDurationUnit.convertValue(
        currentVal,
        _selectedUnit,
        newUnit,
      );
      _durationController.text = newVal.toString();
    }
    setState(() => _selectedUnit = newUnit);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _descController.dispose();
    _capacityController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final capacity = int.tryParse(_capacityController.text.trim()) ?? 1;
    final rawDuration = int.tryParse(_durationController.text.trim()) ?? 60;
    final duration = SlotDurationUnit.toMinutes(rawDuration, _selectedUnit);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(resourcesRepositoryProvider);
      final newResource = await repo.createResource(
        widget.groupId,
        name: name,
        description: _descController.text.trim(),
        icon: _selectedIcon,
        color: _selectedColor,
        capacity: capacity,
        slotDurationMinutes: duration,
      );
      ref.invalidate(groupResourcesProvider(widget.groupId));

      if (mounted) {
        setState(() => _isLoading = false);
        if (widget.onSuccess != null) {
          widget.onSuccess!(newResource);
        } else {
          Navigator.of(context).pop(newResource);
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

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Resource',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.groupName != null && widget.groupName!.isNotEmpty
                            ? widget.groupName!
                            : 'Define a bookable resource like a room or court',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
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
                autofocus: true,
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
                  return null;
                },
              ),
              const SizedBox(height: 14),

              ResourceIconSelector(
                selectedIconKey: _selectedIcon,
                selectedColor: _selectedColor,
                resourceName: _nameController.text.trim(),
                onChanged: (newIcon) {
                  setState(() => _selectedIcon = newIcon);
                },
                onColorChanged: (newColor) {
                  setState(() => _selectedColor = newColor);
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
              ),
              const SizedBox(height: 14),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
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
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Slot Duration',
                        hintText: _selectedUnit == SlotDurationUnit.hours
                            ? '1'
                            : (_selectedUnit == SlotDurationUnit.days ? '1' : '60'),
                        prefixIcon: const Icon(Icons.schedule_outlined),
                      ),
                      validator: (val) =>
                          SlotDurationUnit.validate(val, _selectedUnit),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<SlotDurationUnit>(
                      key: ValueKey(_selectedUnit),
                      initialValue: _selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: SlotDurationUnit.minutes,
                          child: Text('Minutes'),
                        ),
                        DropdownMenuItem(
                          value: SlotDurationUnit.hours,
                          child: Text('Hours'),
                        ),
                        DropdownMenuItem(
                          value: SlotDurationUnit.days,
                          child: Text('Days'),
                        ),
                      ],
                      onChanged: (newUnit) {
                        if (newUnit != null && newUnit != _selectedUnit) {
                          _onUnitChanged(newUnit);
                        }
                      },
                    ),
                  ),
                ],
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
                onPressed: _isLoading ? null : () => _handleCreate(),
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
                        'Create Resource',
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
