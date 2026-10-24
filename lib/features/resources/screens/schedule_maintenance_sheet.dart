import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/maintenance_provider.dart';
import '../../groups/providers/groups_provider.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/ui/ui.dart';
import '../../../core/utils/date_utils.dart';

class ScheduleMaintenanceSheet extends ConsumerStatefulWidget {
  final String groupId;
  final String resourceId;
  final String resourceName;

  const ScheduleMaintenanceSheet({
    super.key,
    required this.groupId,
    required this.resourceId,
    required this.resourceName,
  });

  static Future<void> show(
    BuildContext context, {
    required String groupId,
    required String resourceId,
    required String resourceName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ScheduleMaintenanceSheet(
        groupId: groupId,
        resourceId: resourceId,
        resourceName: resourceName,
      ),
    );
  }

  @override
  ConsumerState<ScheduleMaintenanceSheet> createState() =>
      _ScheduleMaintenanceSheetState();
}

class _ScheduleMaintenanceSheetState
    extends ConsumerState<ScheduleMaintenanceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _recurrenceType = 'NONE'; // 'NONE' | 'WEEKLY' | 'DAILY'
  int _dayOfWeek = 1; // 1 = Monday
  DateTime _startDate = DateTime.now().add(const Duration(hours: 1));
  DateTime _endDate = DateTime.now().add(const Duration(hours: 3));
  TimeOfDay _startTimeOfDay = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTimeOfDay = const TimeOfDay(hour: 11, minute: 0);
  String? _selectedAssigneeId;
  bool _cancelConflicting = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            _startDate.hour,
            _startDate.minute,
          );
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(hours: 2));
          }
        } else {
          _endDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            _endDate.hour,
            _endDate.minute,
          );
        }
      });
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _startTimeOfDay : _endTimeOfDay;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTimeOfDay = picked;
          _startDate = DateTime(
            _startDate.year,
            _startDate.month,
            _startDate.day,
            picked.hour,
            picked.minute,
          );
        } else {
          _endTimeOfDay = picked;
          _endDate = DateTime(
            _endDate.year,
            _endDate.month,
            _endDate.day,
            picked.hour,
            picked.minute,
          );
        }
      });
    }
  }

  Future<void> _submit({bool forceOverride = false}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final body = <String, dynamic>{
      'title': _titleController.text.trim(),
      if (_descriptionController.text.trim().isNotEmpty)
        'description': _descriptionController.text.trim(),
      if (_selectedAssigneeId != null)
        'assigned_to_id': _selectedAssigneeId,
      'recurrence_type': _recurrenceType,
      'cancel_conflicting_bookings': forceOverride || _cancelConflicting,
    };

    if (_recurrenceType == 'NONE') {
      body['start_time'] = _startDate.toUtc().toIso8601String();
      body['end_time'] = _endDate.toUtc().toIso8601String();
    } else {
      body['start_time_of_day'] = _formatTimeOfDay(_startTimeOfDay);
      body['end_time_of_day'] = _formatTimeOfDay(_endTimeOfDay);
      body['start_time'] = _startDate.toUtc().toIso8601String();
      body['end_time'] = _endDate.toUtc().toIso8601String();

      if (_recurrenceType == 'WEEKLY') {
        body['day_of_week'] = _dayOfWeek;
      }
    }

    try {
      final task = await ref
          .read(maintenanceActionsProvider.notifier)
          .createMaintenanceTask(
            groupId: widget.groupId,
            resourceId: widget.resourceId,
            body: body,
          );

      if (!mounted) return;
      setState(() => _isLoading = false);

      final cancelledCount = task.cancelledBookingsCount ?? 0;
      final message =
          cancelledCount > 0
              ? 'Maintenance scheduled ($cancelledCount conflicting bookings cancelled)'
              : 'Maintenance scheduled successfully';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      Navigator.of(context).pop();
    } on ConflictException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showConflictDialog(e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to schedule maintenance: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showConflictDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            const Text('Booking Conflicts'),
          ],
        ),
        content: const Text(
          'Existing confirmed bookings overlap with this scheduled maintenance window. '
          'Would you like to cancel conflicting bookings and schedule maintenance anyway?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _submit(forceOverride: true);
            },
            child: const Text('Cancel Bookings & Schedule'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final membersAsync = ref.watch(groupMembersProvider(widget.groupId));

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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Schedule Maintenance',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.resourceName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title *',
                  hintText: 'e.g., Deep Cleaning, AC Filter Replacement',
                  prefixIcon: Icon(Icons.build_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Title is required';
                  }
                  if (val.trim().length < 2) {
                    return 'Title must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Details, contractor instructions or notes',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 14),

              // Assignee Field (Optional)
              membersAsync.when(
                data: (members) {
                  return DropdownButtonFormField<String?>(
                    initialValue: _selectedAssigneeId,
                    decoration: const InputDecoration(
                      labelText: 'Assign To (Optional)',
                      hintText: 'Select a group member',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Unassigned'),
                      ),
                      ...members.map(
                        (m) => DropdownMenuItem<String?>(
                          value: m.userId,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(m.displayName),
                              if (m.isAdmin) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cs.primaryContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Admin',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: cs.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedAssigneeId = val);
                    },
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 18),

              // Recurrence Type Selector
              Text(
                'Schedule Type',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'NONE',
                    label: Text('One-off'),
                    icon: Icon(Icons.calendar_today_outlined, size: 16),
                  ),
                  ButtonSegment(
                    value: 'WEEKLY',
                    label: Text('Weekly'),
                    icon: Icon(Icons.repeat_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: 'DAILY',
                    label: Text('Daily'),
                    icon: Icon(Icons.today_outlined, size: 16),
                  ),
                ],
                selected: {_recurrenceType},
                onSelectionChanged: (val) {
                  setState(() => _recurrenceType = val.first);
                },
              ),
              const SizedBox(height: 18),

              // Type specific inputs
              if (_recurrenceType == 'NONE') ...[
                // One-off Start & End Date Time
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(isStart: true),
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start Date',
                            prefixIcon: Icon(Icons.calendar_month, size: 18),
                          ),
                          child: Text(
                            AppDateUtils.formatDate(_startDate),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickTime(isStart: true),
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start Time',
                            prefixIcon: Icon(Icons.access_time, size: 18),
                          ),
                          child: Text(
                            _formatTimeOfDay(_startTimeOfDay),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(isStart: false),
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'End Date',
                            prefixIcon: Icon(Icons.calendar_month, size: 18),
                          ),
                          child: Text(
                            AppDateUtils.formatDate(_endDate),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickTime(isStart: false),
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'End Time',
                            prefixIcon: Icon(Icons.access_time, size: 18),
                          ),
                          child: Text(
                            _formatTimeOfDay(_endTimeOfDay),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Weekly day of week selector
                if (_recurrenceType == 'WEEKLY') ...[
                  Text(
                    'Day of Week',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (int i = 0; i < 7; i++)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text([
                                'Sun',
                                'Mon',
                                'Tue',
                                'Wed',
                                'Thu',
                                'Fri',
                                'Sat',
                              ][i]),
                              selected: _dayOfWeek == i,
                              onSelected: (selected) {
                                if (selected) setState(() => _dayOfWeek = i);
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Recurring time of day
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickTime(isStart: true),
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Time From',
                            prefixIcon: Icon(Icons.access_time, size: 18),
                          ),
                          child: Text(
                            _formatTimeOfDay(_startTimeOfDay),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickTime(isStart: false),
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Time Until',
                            prefixIcon: Icon(Icons.access_time, size: 18),
                          ),
                          child: Text(
                            _formatTimeOfDay(_endTimeOfDay),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Effective date range
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(isStart: true),
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Valid From',
                            prefixIcon: Icon(Icons.date_range, size: 18),
                          ),
                          child: Text(
                            AppDateUtils.formatDate(_startDate),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(isStart: false),
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Valid Until',
                            prefixIcon: Icon(Icons.date_range, size: 18),
                          ),
                          child: Text(
                            AppDateUtils.formatDate(_endDate),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 14),

              // Conflict override checkbox
              CheckboxListTile(
                value: _cancelConflicting,
                onChanged: (val) {
                  setState(() => _cancelConflicting = val ?? false);
                },
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  'Cancel overlapping bookings automatically',
                  style: theme.textTheme.bodyMedium,
                ),
                subtitle: Text(
                  'If unchecked, the system will prompt you before overriding',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons
              PrimaryButton(
                onPressed: _isLoading ? null : () => _submit(),
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
                        'Schedule Maintenance',
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
