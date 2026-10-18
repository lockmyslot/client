import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/models/maintenance_task.dart';
import '../providers/maintenance_provider.dart';
import '../providers/resources_provider.dart';
import 'schedule_maintenance_sheet.dart';
import '../../../core/ui/ui.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_display.dart';
import '../../../shared/widgets/confirm_dialog.dart';

class MaintenanceTasksScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String resourceId;

  const MaintenanceTasksScreen({
    super.key,
    required this.groupId,
    required this.resourceId,
  });

  @override
  ConsumerState<MaintenanceTasksScreen> createState() =>
      _MaintenanceTasksScreenState();
}

class _MaintenanceTasksScreenState
    extends ConsumerState<MaintenanceTasksScreen> {
  String _selectedFilter = 'ALL'; // ALL | ACTIVE | RECURRING | COMPLETED

  Color _getStatusColor(String status, ColorScheme cs) {
    switch (status.toUpperCase()) {
      case 'SCHEDULED':
        return cs.primary;
      case 'IN_PROGRESS':
        return Colors.orange.shade700;
      case 'COMPLETED':
        return Colors.green.shade700;
      case 'CANCELLED':
        return cs.outline;
      default:
        return cs.primary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'SCHEDULED':
        return Icons.event_available;
      case 'IN_PROGRESS':
        return Icons.build_circle_outlined;
      case 'COMPLETED':
        return Icons.check_circle_outline;
      case 'CANCELLED':
        return Icons.cancel_outlined;
      default:
        return Icons.build;
    }
  }

  Future<void> _updateStatus(MaintenanceTask task, String newStatus) async {
    try {
      await ref.read(maintenanceActionsProvider.notifier).updateMaintenanceTask(
        groupId: widget.groupId,
        resourceId: widget.resourceId,
        taskId: task.id,
        body: {'status': newStatus},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task marked as $newStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update task: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(MaintenanceTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmDialog(
        title: 'Delete Maintenance Task',
        message: 'Are you sure you want to delete "${task.title}"?',
        confirmText: 'Delete',
        isDestructive: true,
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(maintenanceActionsProvider.notifier)
            .deleteMaintenanceTask(
              groupId: widget.groupId,
              resourceId: widget.resourceId,
              taskId: task.id,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maintenance task deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete task: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final resourceAsync = ref.watch(
      resourceDetailProvider((
        groupId: widget.groupId,
        resourceId: widget.resourceId,
      )),
    );

    final tasksAsync = ref.watch(
      resourceMaintenanceProvider((
        groupId: widget.groupId,
        resourceId: widget.resourceId,
        status: null,
      )),
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Maintenance Tasks'),
            resourceAsync.when(
              data: (res) => Text(
                res.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_task),
        label: const Text('Schedule Maintenance'),
        onPressed: () {
          final resName = resourceAsync.value?.name ?? 'Resource';
          ScheduleMaintenanceSheet.show(
            context,
            groupId: widget.groupId,
            resourceId: widget.resourceId,
            resourceName: resName,
          );
        },
      ),
      body: Column(
        children: [
          // Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildFilterChip('ALL', 'All'),
                const SizedBox(width: 8),
                _buildFilterChip('ACTIVE', 'Active / Scheduled'),
                const SizedBox(width: 8),
                _buildFilterChip('RECURRING', 'Recurring'),
                const SizedBox(width: 8),
                _buildFilterChip('COMPLETED', 'Completed / Cancelled'),
              ],
            ),
          ),
          const Divider(height: 1),

          // Task List Content
          Expanded(
            child: tasksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => ErrorDisplay(
                error: err.toString(),
                onRetry: () => ref.invalidate(resourceMaintenanceProvider),
              ),
              data: (tasks) {
                final filtered = tasks.where((t) {
                  if (_selectedFilter == 'ACTIVE') {
                    return t.isScheduled || t.isInProgress;
                  }
                  if (_selectedFilter == 'RECURRING') {
                    return t.isRecurring;
                  }
                  if (_selectedFilter == 'COMPLETED') {
                    return t.isCompleted || t.isCancelled;
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.handyman_outlined,
                    title: 'No Maintenance Tasks',
                    description: _selectedFilter == 'ALL'
                        ? 'No maintenance tasks scheduled for this resource yet.'
                        : 'No tasks match the selected filter.',
                    action: PrimaryButton(
                      onPressed: () {
                        final resName = resourceAsync.value?.name ?? 'Resource';
                        ScheduleMaintenanceSheet.show(
                          context,
                          groupId: widget.groupId,
                          resourceId: widget.resourceId,
                          resourceName: resName,
                        );
                      },
                      child: const Text('Schedule Maintenance'),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(resourceMaintenanceProvider);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, index) {
                      final task = filtered[index];
                      return _buildTaskCard(task, cs, theme);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedFilter = key);
      },
    );
  }

  Widget _buildTaskCard(
    MaintenanceTask task,
    ColorScheme cs,
    ThemeData theme,
  ) {
    final statusColor = _getStatusColor(task.status, cs);
    final statusIcon = _getStatusIcon(task.status);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: task.isInProgress
              ? Colors.orange.shade300
              : cs.outlineVariant.withValues(alpha: 0.6),
          width: task.isInProgress ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: kCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (task.description != null &&
                          task.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Status Badge & Menu
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.status.replaceAll('_', ' '),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (val) {
                    if (val == 'IN_PROGRESS' ||
                        val == 'COMPLETED' ||
                        val == 'CANCELLED') {
                      _updateStatus(task, val);
                    } else if (val == 'DELETE') {
                      _confirmDelete(task);
                    }
                  },
                  itemBuilder: (ctx) => [
                    if (task.isScheduled)
                      const PopupMenuItem(
                        value: 'IN_PROGRESS',
                        child: Row(
                          children: [
                            Icon(Icons.play_arrow_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Mark In Progress'),
                          ],
                        ),
                      ),
                    if (task.isScheduled || task.isInProgress) ...[
                      const PopupMenuItem(
                        value: 'COMPLETED',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline, size: 18),
                            SizedBox(width: 8),
                            Text('Mark Completed'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'CANCELLED',
                        child: Row(
                          children: [
                            Icon(Icons.cancel_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Cancel Schedule'),
                          ],
                        ),
                      ),
                    ],
                    const PopupMenuItem(
                      value: 'DELETE',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Delete Task',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Schedule Info Row
            Row(
              children: [
                Icon(
                  task.isRecurring
                      ? Icons.repeat_rounded
                      : Icons.calendar_today_outlined,
                  size: 16,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    task.isRecurring
                        ? task.recurrenceSummary
                        : '${AppDateUtils.formatDate(task.startTime)} · ${AppDateUtils.formatTime(task.startTime)} - ${AppDateUtils.formatTime(task.endTime)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (task.createdByName != null) ...[
                  Icon(Icons.person_outline,
                      size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    task.createdByName!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
