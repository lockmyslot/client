import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/booking_rule.dart';
import '../providers/booking_rules_provider.dart';
import '../data/resources_repository.dart';
import '../../../core/ui/ui.dart';
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
}
