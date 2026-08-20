import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/models/booking_rule.dart';
import '../data/resources_repository.dart';
import '../providers/booking_rules_provider.dart';
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
  ConsumerState<BookingRulesScreen> createState() => _BookingRulesScreenState();
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
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    for (final scope in _dayScopes) {
      _formData[scope] = _RuleFormData(scope);
    }
  }

  void _populateExistingRules(List<BookingRule> rules) {
    for (final rule in rules) {
      if (_formData.containsKey(rule.dayScope)) {
        _formData[rule.dayScope]!.populate(rule);
      }
    }
  }

  Future<void> _handleSaveAll() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<BookingRule> rulesToSave = [];
      for (final form in _formData.values) {
        if (form.isEnabled) {
          rulesToSave.add(form.toBookingRule());
        }
      }

      final repo = ref.read(resourcesRepositoryProvider);
      await repo.updateBookingRules(widget.groupId, widget.resourceId, rulesToSave);

      ref.invalidate(bookingRulesProvider((groupId: widget.groupId, resourceId: widget.resourceId)));

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rulesAsync = ref.watch(bookingRulesProvider((groupId: widget.groupId, resourceId: widget.resourceId)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configure Booking Rules'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          PrimaryButton(
            onPressed: _isLoading ? null : _handleSaveAll,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save Rules'),
          ),
        ],
      ),
      body: rulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorDisplay(
          error: err.toString(),
          onRetry: () => ref.invalidate(bookingRulesProvider((groupId: widget.groupId, resourceId: widget.resourceId))),
        ),
        data: (existingRules) {
          _populateExistingRules(existingRules);
          final currentForm = _formData[_selectedScope]!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rule Priority').h4(),
                const SizedBox(height: 4),
                const Text('Day-specific rules (e.g. FRIDAY) override broader rules (e.g. WEEKDAY).')
                    .muted()
                    .small(),
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
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedScope = scope);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  scope,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.onPrimary
                                        : null,
                                  ),
                                ).small(),
                                if (form.isEnabled) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.check_circle,
                                    size: 12,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.onPrimary
                                        : Colors.green,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 24),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text('Rule for $_selectedScope').h3()),
                            Checkbox(
                              value: currentForm.isEnabled,
                              onChanged: (val) {
                                setState(() {
                                  currentForm.isEnabled = val == true;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            const Text('Enable Rule for Scope').small(),
                          ],
                        ),
                        if (!currentForm.isEnabled) ...[
                          const SizedBox(height: 12),
                          const Text('Rule disabled for this scope. Default settings apply.')
                              .muted()
                              .small(),
                        ] else ...[
                          const SizedBox(height: 20),

                          // Form controls
                          Row(
                            children: [
                              Expanded(
                                child: _buildNumberField('Max Bookings / Day', currentForm.maxBookingsController, 'No limit'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildNumberField('Max Hours / Day', currentForm.maxHoursController, 'No limit'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: _buildNumberField('Cooldown (Minutes)', currentForm.cooldownController, 'None'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildNumberField('Max Advance (Days)', currentForm.maxAdvanceController, 'No limit'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: _buildNumberField('Min Duration (Min)', currentForm.minDurationController, '1 slot'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildNumberField('Max Duration (Min)', currentForm.maxDurationController, 'No limit'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: _buildTimeField('Available From', currentForm.availableFromController, '00:00'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTimeField('Available Until', currentForm.availableUntilController, '24:00'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ).small(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNumberField(String label, TextEditingController controller, String placeholder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label).small().semiBold(),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(hintText: placeholder),
        ),
      ],
    );
  }

  Widget _buildTimeField(String label, TextEditingController controller, String placeholder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label).small().semiBold(),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(hintText: placeholder),
        ),
      ],
    );
  }
}

class _RuleFormData {
  final String dayScope;
  bool isEnabled = false;
  final TextEditingController maxBookingsController = TextEditingController();
  final TextEditingController maxHoursController = TextEditingController();
  final TextEditingController cooldownController = TextEditingController();
  final TextEditingController minDurationController = TextEditingController();
  final TextEditingController maxDurationController = TextEditingController();
  final TextEditingController maxAdvanceController = TextEditingController();
  final TextEditingController availableFromController = TextEditingController();
  final TextEditingController availableUntilController = TextEditingController();

  _RuleFormData(this.dayScope);

  void populate(BookingRule rule) {
    isEnabled = true;
    if (rule.maxBookingsPerDay != null) maxBookingsController.text = rule.maxBookingsPerDay.toString();
    if (rule.maxHoursPerDay != null) maxHoursController.text = rule.maxHoursPerDay.toString();
    if (rule.cooldownMinutes != null) cooldownController.text = rule.cooldownMinutes.toString();
    if (rule.minDurationMinutes != null) minDurationController.text = rule.minDurationMinutes.toString();
    if (rule.maxDurationMinutes != null) maxDurationController.text = rule.maxDurationMinutes.toString();
    if (rule.maxAdvanceBookingDays != null) maxAdvanceController.text = rule.maxAdvanceBookingDays.toString();
    if (rule.availableFrom != null) availableFromController.text = rule.availableFrom!;
    if (rule.availableUntil != null) availableUntilController.text = rule.availableUntil!;
  }

  BookingRule toBookingRule() {
    return BookingRule(
      dayScope: dayScope,
      maxBookingsPerDay: int.tryParse(maxBookingsController.text.trim()),
      maxHoursPerDay: int.tryParse(maxHoursController.text.trim()),
      cooldownMinutes: int.tryParse(cooldownController.text.trim()),
      minDurationMinutes: int.tryParse(minDurationController.text.trim()),
      maxDurationMinutes: int.tryParse(maxDurationController.text.trim()),
      maxAdvanceBookingDays: int.tryParse(maxAdvanceController.text.trim()),
      availableFrom: availableFromController.text.trim().isNotEmpty ? availableFromController.text.trim() : null,
      availableUntil: availableUntilController.text.trim().isNotEmpty ? availableUntilController.text.trim() : null,
    );
  }
}
