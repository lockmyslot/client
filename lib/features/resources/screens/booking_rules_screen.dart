import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/booking_rule.dart';
import '../providers/booking_rules_provider.dart';
import '../data/resources_repository.dart';
import '../../bookings/providers/availability_provider.dart';
import '../../../core/ui/ui.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/error_display.dart';

class BookingRulesScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String resourceId;

  const BookingRulesScreen({
    super.key,
    required this.groupId,
    required this.resourceId,
  });

  @override
  ConsumerState<BookingRulesScreen> createState() =>
      _BookingRulesScreenState();
}

class _RuleFormData {
  bool isEnabled = false;
  bool hasCustomHours = false;
  String? availableFrom;
  String? availableUntil;

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

class _BookingRulesScreenState extends ConsumerState<BookingRulesScreen> {
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
  final Map<String, _RuleFormData> _formData = {};
  bool _isLoading = false;
  bool _isPopulated = false;

  @override
  void initState() {
    super.initState();
    for (final scope in _dayScopes) {
      _formData[scope] = _RuleFormData();
    }
  }

  @override
  void dispose() {
    for (final data in _formData.values) {
      data.dispose();
    }
    super.dispose();
  }

  void _populateExistingRules(List<BookingRule> rules) {
    if (_isPopulated) return;
    for (final rule in rules) {
      final scope = rule.dayScope.toUpperCase();
      if (_formData.containsKey(scope)) {
        final form = _formData[scope]!;
        form.isEnabled = true;
        if (rule.availableFrom != null || rule.availableUntil != null) {
          form.hasCustomHours = true;
          form.availableFrom = rule.availableFrom;
          form.availableUntil = rule.availableUntil;
        }
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
    _isPopulated = true;
  }

  Future<void> _handleSaveAll() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(resourcesRepositoryProvider);
      final List<BookingRule> rulesToSave = [];

      for (final scope in _dayScopes) {
        final form = _formData[scope]!;
        if (form.isEnabled) {
          String? from;
          String? until;

          if (form.hasCustomHours) {
            from = form.availableFrom ?? '08:00';
            until = form.availableUntil ?? '22:00';

            final fromH = int.tryParse(from.split(':')[0]) ?? 0;
            final fromM = int.tryParse(from.split(':')[1]) ?? 0;
            final untilH = until == '24:00'
                ? 24
                : (int.tryParse(until.split(':')[0]) ?? 0);
            final untilM = int.tryParse(until.split(':')[1]) ?? 0;

            if (fromH * 60 + fromM >= untilH * 60 + untilM) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Invalid working hours for $scope: Closing time must be after opening time.',
                    ),
                    backgroundColor: Theme.of(context).colorScheme.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
              setState(() => _isLoading = false);
              return;
            }
          }

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
              availableFrom: from,
              availableUntil: until,
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
      ref.invalidate(availabilityProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking rules saved successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save rules: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rulesAsync = ref.watch(
      bookingRulesProvider((
        groupId: widget.groupId,
        resourceId: widget.resourceId,
      )),
    );

    return Scaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            title: const Text('Booking Rules'),
            pinned: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: PrimaryButton(
                  onPressed: _isLoading ? null : _handleSaveAll,
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Rules'),
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: rulesAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => SliverFillRemaining(
                child: ErrorDisplay(
                  error: err.toString(),
                  onRetry: () => ref.invalidate(
                    bookingRulesProvider((
                      groupId: widget.groupId,
                      resourceId: widget.resourceId,
                    )),
                  ),
                ),
              ),
              data: (existingRules) {
                _populateExistingRules(existingRules);
                final currentForm = _formData[_selectedScope]!;

                return SliverList(
                  delegate: SliverChildListDelegate([
                    const Text('Rule Scope').h4(),
                    const SizedBox(height: 4),
                    const Text(
                      'Day-specific rules (e.g. FRIDAY) override broader rules (e.g. WEEKDAY).',
                    ).muted().small(),
                    const SizedBox(height: 16),

                    // Day Scope Chips Horizontal Bar
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _dayScopes.map((scope) {
                          final isSelected = scope == _selectedScope;
                          final form = _formData[scope]!;
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
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
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

                    const SizedBox(height: 24),

                    // Enable / Disable Scope Toggle
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
                      // Working Hours Card
                      Card(
                        elevation: 0,
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.outlineVariant.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Padding(
                          padding: kCardPadding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule_outlined,
                                    size: 20,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('Working Hours').h4(),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Control operating hours when members are allowed to book this resource.',
                              ).small().muted(),
                              const SizedBox(height: 12),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  'Restrict Working Hours',
                                ).semiBold(),
                                subtitle: Text(
                                  currentForm.hasCustomHours
                                      ? 'Bookings restricted to operating window (${AppDateUtils.formatTimeString(currentForm.availableFrom ?? '08:00')} – ${AppDateUtils.formatTimeString(currentForm.availableUntil ?? '22:00')})'
                                      : 'Open 24 hours (all-day availability)',
                                ).small().muted(),
                                value: currentForm.hasCustomHours,
                                onChanged: (val) {
                                  setState(() {
                                    currentForm.hasCustomHours = val;
                                    if (val) {
                                      currentForm.availableFrom ??= '08:00';
                                      currentForm.availableUntil ??= '22:00';
                                    }
                                  });
                                },
                              ),
                              if (currentForm.hasCustomHours) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTimePickerTile(
                                        context: context,
                                        label: 'Opening Time',
                                        timeStr:
                                            currentForm.availableFrom ?? '08:00',
                                        onPickTime: () async {
                                          final newTime = await _pickTime(
                                            context,
                                            currentForm.availableFrom ?? '08:00',
                                          );
                                          if (newTime != null) {
                                            setState(
                                              () => currentForm.availableFrom =
                                                  newTime,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildTimePickerTile(
                                        context: context,
                                        label: 'Closing Time',
                                        timeStr:
                                            currentForm.availableUntil ?? '22:00',
                                        onPickTime: () async {
                                          final newTime = await _pickTime(
                                            context,
                                            currentForm.availableUntil ?? '22:00',
                                          );
                                          if (newTime != null) {
                                            setState(
                                              () => currentForm.availableUntil =
                                                  newTime,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    _buildPresetChip(
                                      context: context,
                                      label: '9 AM – 5 PM',
                                      from: '09:00',
                                      until: '17:00',
                                      currentForm: currentForm,
                                    ),
                                    _buildPresetChip(
                                      context: context,
                                      label: '8 AM – 10 PM',
                                      from: '08:00',
                                      until: '22:00',
                                      currentForm: currentForm,
                                    ),
                                    _buildPresetChip(
                                      context: context,
                                      label: '7 AM – 11 PM',
                                      from: '07:00',
                                      until: '23:00',
                                      currentForm: currentForm,
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Limits
                      Card(
                        elevation: 0,
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLow,
                        child: Padding(
                          padding: kCardPadding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Booking Limits').h4(),
                              const SizedBox(height: 12),
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
                                  labelText:
                                      'Cooldown Minutes Between Bookings',
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
                  ]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _pickTime(BuildContext context, String currentTimeStr) async {
    final parts = currentTimeStr.split(':');
    int hour = int.tryParse(parts[0]) ?? 8;
    int minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    if (hour >= 24) hour = 0;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );
    if (picked == null) return null;

    final h = picked.hour.toString().padLeft(2, '0');
    final m = picked.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _buildTimePickerTile({
    required BuildContext context,
    required String label,
    required String timeStr,
    required VoidCallback onPickTime,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onPickTime,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label).small().muted(),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time_outlined, size: 16, color: cs.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    AppDateUtils.formatTimeString(timeStr),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip({
    required BuildContext context,
    required String label,
    required String from,
    required String until,
    required _RuleFormData currentForm,
  }) {
    final isSelected =
        currentForm.availableFrom == from && currentForm.availableUntil == until;
    final cs = Theme.of(context).colorScheme;
    return ActionChip(
      avatar: isSelected
          ? Icon(Icons.check, size: 14, color: cs.primary)
          : null,
      label: Text(label),
      onPressed: () {
        setState(() {
          currentForm.availableFrom = from;
          currentForm.availableUntil = until;
        });
      },
      backgroundColor: isSelected
          ? cs.primaryContainer.withValues(alpha: 0.6)
          : cs.surfaceContainerHighest.withValues(alpha: 0.35),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        color: isSelected ? cs.primary : cs.onSurfaceVariant,
      ),
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
