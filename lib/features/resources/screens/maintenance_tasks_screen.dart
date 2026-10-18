import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/models/maintenance_task.dart';
import '../providers/maintenance_provider.dart';
import '../providers/resources_provider.dart';
import 'schedule_maintenance_sheet.dart';
import '../../auth/providers/auth_provider.dart';
import '../../groups/data/models/group_member.dart';
import '../../groups/providers/groups_provider.dart';
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

  Future<void> _showAssignMemberDialog(
    MaintenanceTask task,
    List<GroupMember> members,
  ) async {
    String? chosenUserId = task.assignedToId;

    final selected = await showDialog<String?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Assign Maintenance Task'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select a member to assign to "${task.title}":',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  initialValue: chosenUserId,
                  decoration: const InputDecoration(
                    labelText: 'Assignee',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Unassigned'),
                    ),
                    ...members.map(
                      (m) => DropdownMenuItem<String?>(
                        value: m.userId,
                        child: Text(
                          m.displayName + (m.isAdmin ? ' (Admin)' : ''),
                        ),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setDialogState(() => chosenUserId = val);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(task.assignedToId),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(chosenUserId),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (selected != task.assignedToId) {
      try {
        await ref
            .read(maintenanceActionsProvider.notifier)
            .updateMaintenanceTask(
              groupId: widget.groupId,
              resourceId: widget.resourceId,
              taskId: task.id,
              body: {'assigned_to_id': selected},
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Assignee updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update assignee: $e'),
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

    final authState = ref.watch(authProvider);
    final currentUser = authState.user;
    final membersAsync = ref.watch(groupMembersProvider(widget.groupId));
    final members = membersAsync.value ?? [];
    final currentMember =
        members.where((m) => m.userId == currentUser?.id).firstOrNull;
    final isAdmin = currentMember?.isAdmin ?? false;

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
                _buildFilterChip('ASSIGNED_TO_ME', 'Assigned to Me'),
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
                  if (_selectedFilter == 'ASSIGNED_TO_ME') {
                    return t.assignedToId != null &&
                        t.assignedToId == currentUser?.id;
                  }
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
                        : (_selectedFilter == 'ASSIGNED_TO_ME'
                            ? 'You have no maintenance tasks assigned to you.'
                            : 'No tasks match the selected filter.'),
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
                      return _buildTaskCard(
                        task,
                        cs,
                        theme,
                        members,
                        isAdmin,
                        currentUser?.id,
                      );
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
    List<GroupMember> members,
    bool isAdmin,
    String? currentUserId,
  ) {
    final statusColor = _getStatusColor(task.status, cs);
    final statusIcon = _getStatusIcon(task.status);
    final isAssignee = task.assignedToId != null && task.assignedToId == currentUserId;
    final canManageStatus = isAdmin || isAssignee;

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
                if (canManageStatus || isAdmin)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (val) {
                      if (val == 'IN_PROGRESS' ||
                          val == 'COMPLETED' ||
                          val == 'CANCELLED') {
                        _updateStatus(task, val);
                      } else if (val == 'DELETE') {
                        _confirmDelete(task);
                      } else if (val == 'ASSIGN') {
                        _showAssignMemberDialog(task, members);
                      }
                    },
                    itemBuilder: (ctx) => [
                      if (isAdmin)
                        const PopupMenuItem(
                          value: 'ASSIGN',
                          child: Row(
                            children: [
                              Icon(Icons.person_add_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Assign Member'),
                            ],
                          ),
                        ),
                      if (canManageStatus && task.isScheduled)
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
                      if (canManageStatus && (task.isScheduled || task.isInProgress))
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
                      if (isAdmin && (task.isScheduled || task.isInProgress))
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
                      if (isAdmin)
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
            const SizedBox(height: 10),

            // Assignee Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: task.assignedToId != null
                        ? (isAssignee
                            ? cs.primary.withValues(alpha: 0.15)
                            : cs.secondaryContainer.withValues(alpha: 0.5))
                        : cs.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isAssignee
                          ? cs.primary.withValues(alpha: 0.4)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        task.assignedToId != null
                            ? Icons.person
                            : Icons.person_off_outlined,
                        size: 14,
                        color: task.assignedToId != null
                            ? (isAssignee
                                ? cs.primary
                                : cs.onSecondaryContainer)
                            : cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        task.assignedToId != null
                            ? (isAssignee
                                ? 'Assigned to You (${task.assignedToName})'
                                : 'Assigned: ${task.assignedToName}')
                            : 'Unassigned',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: task.assignedToId != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: task.assignedToId != null
                              ? (isAssignee
                                  ? cs.primary
                                  : cs.onSecondaryContainer)
                              : cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isAdmin) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _showAssignMemberDialog(task, members),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_outlined, size: 13, color: cs.primary),
                          const SizedBox(width: 3),
                          Text(
                            task.assignedToId != null ? 'Reassign' : 'Assign',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 10),
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
