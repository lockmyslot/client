import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/booking_rule.dart';
import '../data/models/resource.dart';
import '../data/resources_repository.dart';
import '../providers/booking_rules_provider.dart';
import '../providers/resources_provider.dart';
import '../../../core/ui/ui.dart';
import '../../../shared/widgets/error_display.dart';

class ResourceSettingsScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String resourceId;
  final int initialTab;

  const ResourceSettingsScreen({
    super.key,
    required this.groupId,
    required this.resourceId,
    this.initialTab = 0,
  });

  @override
  ConsumerState<ResourceSettingsScreen> createState() =>
      _ResourceSettingsScreenState();
}

class _RuleFormData {
  bool isEnabled = false;
  final maxBookingsController = TextEditingController();
  final maxHoursController = TextEditingController();
  final cooldownController = TextEditingController();
  final maxAdvanceController = TextEditingController();

  void dispose() {
    maxBookingsController.dispose();
    maxHoursController.dispose();
    cooldownController.dispose();
    maxAdvanceController.dispose();
  }
}

class _ResourceSettingsScreenState extends ConsumerState<ResourceSettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Resource configuration form
  final _configFormKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _capacityController;
  late final TextEditingController _durationController;
  bool _isActive = true;
  bool _isConfigInitialized = false;
  bool _isSavingConfig = false;
  String? _configError;

  // Booking rules form
  static const List<String> _dayScopes = [
    'WEEKDAY',
    'WEEKEND',
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY',
  ];
  String _selectedScope = 'WEEKDAY';
  final Map<String, _RuleFormData> _rulesFormData = {};
  bool _isRulesPopulated = false;
  bool _isSavingRules = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );

    _nameController = TextEditingController();
    _descController = TextEditingController();
    _capacityController = TextEditingController();
    _durationController = TextEditingController();

    for (final scope in _dayScopes) {
      _rulesFormData[scope] = _RuleFormData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _capacityController.dispose();
    _durationController.dispose();
    for (final data in _rulesFormData.values) {
      data.dispose();
    }
    super.dispose();
  }

  void _initConfigFields(Resource resource) {
    if (_isConfigInitialized) return;
    _nameController.text = resource.name;
    _descController.text = resource.description ?? '';
    _capacityController.text = resource.capacity.toString();
    _durationController.text = resource.slotDurationMinutes.toString();
    _isActive = resource.isActive;
    _isConfigInitialized = true;
  }

  void _populateExistingRules(List<BookingRule> rules) {
    if (_isRulesPopulated) return;
    for (final rule in rules) {
      final scope = rule.dayScope.toUpperCase();
      if (_rulesFormData.containsKey(scope)) {
        final form = _rulesFormData[scope]!;
        form.isEnabled = true;
        if (rule.maxBookingsPerDay != null) {
          form.maxBookingsController.text = rule.maxBookingsPerDay.toString();
        }
        if (rule.maxHoursPerDay != null) {
          form.maxHoursController.text = rule.maxHoursPerDay.toString();
        }
        if (rule.cooldownMinutes != null) {
          form.cooldownController.text = rule.cooldownMinutes.toString();
        }
        if (rule.maxAdvanceBookingDays != null) {
          form.maxAdvanceController.text =
              rule.maxAdvanceBookingDays.toString();
        }
      }
    }
    _isRulesPopulated = true;
  }

  Future<void> _handleSaveConfig() async {
    if (!_configFormKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final description = _descController.text.trim();
    final capacity = int.tryParse(_capacityController.text.trim()) ?? 1;
    final duration = int.tryParse(_durationController.text.trim()) ?? 60;

    setState(() {
      _isSavingConfig = true;
      _configError = null;
    });

    try {
      final repo = ref.read(resourcesRepositoryProvider);
      final updated = await repo.updateResource(
        widget.groupId,
        widget.resourceId,
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
          resourceId: widget.resourceId,
        )),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Configuration updated for "${updated.name}"'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _configError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingConfig = false;
        });
      }
    }
  }

  Future<void> _handleSaveRules() async {
    setState(() => _isSavingRules = true);
    try {
      final repo = ref.read(resourcesRepositoryProvider);
      final List<BookingRule> rulesToSave = [];

      for (final scope in _dayScopes) {
        final form = _rulesFormData[scope]!;
        if (form.isEnabled) {
          final maxBookings = int.tryParse(form.maxBookingsController.text);
          final maxHours = int.tryParse(form.maxHoursController.text);
          final cooldown = int.tryParse(form.cooldownController.text);
          final maxAdv = int.tryParse(form.maxAdvanceController.text);

          rulesToSave.add(
            BookingRule(
              id: null,
              dayScope: scope,
              maxBookingsPerDay: maxBookings,
              maxHoursPerDay: maxHours,
              cooldownMinutes: cooldown,
              maxAdvanceBookingDays: maxAdv,
            ),
          );
        }
      }

      await repo.updateBookingRules(
        widget.groupId,
        widget.resourceId,
        rulesToSave,
      );

      ref.invalidate(
        bookingRulesProvider((
          groupId: widget.groupId,
          resourceId: widget.resourceId,
        )),
      );
      ref.invalidate(
        resourceDetailProvider((
          groupId: widget.groupId,
          resourceId: widget.resourceId,
        )),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking rules saved successfully.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save rules: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingRules = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resourceAsync = ref.watch(
      resourceDetailProvider((
        groupId: widget.groupId,
        resourceId: widget.resourceId,
      )),
    );
    final rulesAsync = ref.watch(
      bookingRulesProvider((
        groupId: widget.groupId,
        resourceId: widget.resourceId,
      )),
    );

    return Scaffold(
      appBar: AppBar(
        title: resourceAsync.when(
          data: (res) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Resource Settings'),
              Text(
                res.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          loading: () => const Text('Resource Settings'),
          error: (_, __) => const Text('Settings'),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.tune_outlined, size: 18),
              text: 'Configurations',
            ),
            Tab(
              icon: Icon(Icons.rule_outlined, size: 18),
              text: 'Booking Rules',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Resource Configurations
          resourceAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => ErrorDisplay(
              error: err.toString(),
              onRetry: () => ref.invalidate(
                resourceDetailProvider((
                  groupId: widget.groupId,
                  resourceId: widget.resourceId,
                )),
              ),
            ),
            data: (resource) {
              _initConfigFields(resource);
              return _buildConfigTab(context);
            },
          ),

          // Tab 2: Booking Rules
          rulesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => ErrorDisplay(
              error: err.toString(),
              onRetry: () => ref.invalidate(
                bookingRulesProvider((
                  groupId: widget.groupId,
                  resourceId: widget.resourceId,
                )),
              ),
            ),
            data: (existingRules) {
              _populateExistingRules(existingRules);
              return _buildRulesTab(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConfigTab(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _configFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Resource Properties',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Modify configuration properties set during resource creation.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),

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
            const SizedBox(height: 16),

            TextFormField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Brief details about amenities, location, or access',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              validator: (val) {
                if (val != null && val.trim().length > 500) {
                  return 'Description must be at most 500 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

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
            const SizedBox(height: 16),

            Material(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: SwitchListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                title: const Text(
                  'Active for Bookings',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  _isActive
                      ? 'Resource is active and available for member bookings'
                      : 'Resource is disabled; members cannot book slots',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                value: _isActive,
                onChanged: (val) {
                  setState(() => _isActive = val);
                },
              ),
            ),

            if (_configError != null) ...[
              const SizedBox(height: 12),
              Text(
                _configError!,
                style: TextStyle(color: cs.error),
              ).small(),
            ],

            const SizedBox(height: 24),

            PrimaryButton(
              onPressed: _isSavingConfig ? null : _handleSaveConfig,
              expand: true,
              child: _isSavingConfig
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save Configurations',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),

            const SizedBox(height: 28),

            // Card pointing to Booking Rules
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                _tabController.animateTo(1);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.rule_outlined,
                        color: cs.onPrimaryContainer,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Booking Rules & Policies',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Configure daily limits, maximum hours, cooldowns, and advance windows',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: cs.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRulesTab(BuildContext context) {
    final currentForm = _rulesFormData[_selectedScope]!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Booking Rules').h4(),
              const SizedBox(height: 2),
              const Text(
                'Day-specific rules override broader rules.',
              ).muted().small(),
            ],
          ),
          const SizedBox(height: 16),

          // Day Scope Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _dayScopes.map((scope) {
                final isSelected = scope == _selectedScope;
                final form = _rulesFormData[scope]!;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(scope),
                        if (form.isEnabled) ...[
                          const SizedBox(width: 4),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    onSelected: (_) {
                      setState(() => _selectedScope = scope);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Enable scope toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Enable rules for $_selectedScope',
            ).semiBold(),
            subtitle: const Text(
              'Active rules will restrict booking times for this scope.',
            ).small().muted(),
            value: currentForm.isEnabled,
            onChanged: (val) {
              setState(() => currentForm.isEnabled = val);
            },
          ),
          const SizedBox(height: 16),

          if (currentForm.isEnabled) ...[
            Card(
              elevation: 0,
              color: cs.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Padding(
                padding: kCardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Usage Limits').h4(),
                    const SizedBox(height: 14),
                    TextField(
                      controller: currentForm.maxBookingsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Max Bookings / User / Day',
                        hintText: 'e.g. 2 (leave blank = unlimited)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: currentForm.maxHoursController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Max Hours / User / Day',
                        hintText: 'e.g. 3 (leave blank = unlimited)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: currentForm.cooldownController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cooldown Minutes Between Bookings',
                        hintText: 'e.g. 30 (leave blank = none)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: currentForm.maxAdvanceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Max Advance Booking (Days)',
                        hintText: 'e.g. 7 (leave blank = unlimited)',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          PrimaryButton(
            onPressed: _isSavingRules ? null : _handleSaveRules,
            expand: true,
            child: _isSavingRules
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Save Rules',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}
