import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/resources_provider.dart';
import '../providers/maintenance_provider.dart';
import '../data/models/maintenance_task.dart';
import '../data/resources_repository.dart';
import 'schedule_maintenance_sheet.dart';
import '../../../core/ui/ui.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_display.dart';

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
  String? _statusFilter;

  @override
  Widget build(BuildContext context) {
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
        status: _statusFilter,
      )),
    );

    return Scaffold(
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
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(
            resourceMaintenanceProvider((
              groupId: widget.groupId,
              resourceId: widget.resourceId,
              status: _statusFilter,
            )),
          );
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverAppBar.large(
              title: Text('Maintenance'),
              pinned: true,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        selected: _statusFilter == null,
                        label: const Text('All'),
                        onSelected: (_) =>
                            setState(() => _statusFilter = null),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        selected: _statusFilter == 'SCHEDULED',
                        label: const Text('Scheduled'),
                        onSelected: (_) =>
                            setState(() => _statusFilter = 'SCHEDULED'),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        selected: _statusFilter == 'IN_PROGRESS',
                        label: const Text('In Progress'),
                        onSelected: (_) =>
                            setState(() => _statusFilter = 'IN_PROGRESS'),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        selected: _statusFilter == 'COMPLETED',
                        label: const Text('Completed'),
                        onSelected: (_) =>
                            setState(() => _statusFilter = 'COMPLETED'),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        selected: _statusFilter == 'CANCELLED',
                        label: const Text('Cancelled'),
                        onSelected: (_) =>
                            setState(() => _statusFilter = 'CANCELLED'),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: tasksAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, stack) => SliverFillRemaining(
                  child: ErrorDisplay(
                    error: err.toString(),
                    onRetry: () => ref.invalidate(
                      resourceMaintenanceProvider((
                        groupId: widget.groupId,
                        resourceId: widget.resourceId,
                        status: _statusFilter,
                      )),
                    ),
                  ),
                ),
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return SliverFillRemaining(
                      child: EmptyState(
                        icon: Icons.build_outlined,
                        title: 'No Maintenance Tasks',
                        description: _statusFilter != null
                            ? 'No tasks found matching filter: $_statusFilter'
                            : 'No maintenance has been scheduled for this resource.',
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final task = tasks[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Entrance(
                            delay: Duration(milliseconds: index * 40),
                            child: _MaintenanceTaskCard(
                              task: task,
                              groupId: widget.groupId,
                              resourceId: widget.resourceId,
                            ),
                          ),
                        );
                      },
                      childCount: tasks.length,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaintenanceTaskCard extends ConsumerWidget {
  final MaintenanceTask task;
  final String groupId;
  final String resourceId;

  const _MaintenanceTaskCard({
    required this.task,
    required this.groupId,
    required this.resourceId,
  });

  Color _statusColor(ColorScheme cs) {
    if (task.isScheduled) return cs.tertiary;
    if (task.isInProgress) return cs.primary;
    if (task.isCompleted) return cs.secondary;
    return cs.error;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = _statusColor(cs);

    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: kCardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.status,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  AppDateUtils.formatTime(task.startTime),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(task.title, style: theme.textTheme.titleMedium),
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                task.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '${AppDateUtils.formatDisplayDate(task.startTime)} · ${AppDateUtils.formatTime(task.startTime)} - ${AppDateUtils.formatTime(task.endTime)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (task.cancelledBookingsCount != null &&
                task.cancelledBookingsCount! > 0) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 14,
                    color: cs.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${task.cancelledBookingsCount} booking(s) cancelled',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.error,
                    ),
                  ),
                ],
              ),
            ],
            if (task.isScheduled || task.isInProgress) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (task.isScheduled) ...[
                    OutlinedButton(
                      onPressed: () async {
                        final confirm = await ConfirmDialog.show(
                          context,
                          title: 'Cancel Task',
                          message:
                              'Are you sure you want to cancel this maintenance task?',
                          confirmText: 'Cancel Task',
                          isDestructive: true,
                        );
                        if (confirm == true) {
                          final repo = ref.read(resourcesRepositoryProvider);
                          await repo.updateMaintenanceTask(
                            groupId,
                            resourceId,
                            task.id,
                            {'status': 'CANCELLED'},
                          );
                          ref.invalidate(
                            resourceMaintenanceProvider((
                              groupId: groupId,
                              resourceId: resourceId,
                              status: null,
                            )),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: cs.error,
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: () async {
                        final repo = ref.read(resourcesRepositoryProvider);
                        await repo.updateMaintenanceTask(
                          groupId,
                          resourceId,
                          task.id,
                          {'status': 'IN_PROGRESS'},
                        );
                        ref.invalidate(
                          resourceMaintenanceProvider((
                            groupId: groupId,
                            resourceId: resourceId,
                            status: null,
                          )),
                        );
                      },
                      child: const Text('Start'),
                    ),
                  ],
                  if (task.isInProgress) ...[
                    FilledButton(
                      onPressed: () async {
                        final repo = ref.read(resourcesRepositoryProvider);
                        await repo.updateMaintenanceTask(
                          groupId,
                          resourceId,
                          task.id,
                          {'status': 'COMPLETED'},
                        );
                        ref.invalidate(
                          resourceMaintenanceProvider((
                            groupId: groupId,
                            resourceId: resourceId,
                            status: null,
                          )),
                        );
                      },
                      child: const Text('Mark Complete'),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
