import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/resources_provider.dart';
import '../widgets/resource_avatar.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/connected_list.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_display.dart';
import '../../../shared/widgets/m3_collapsing_app_bar.dart';

class ResourcesListScreen extends ConsumerWidget {
  final String groupId;

  const ResourcesListScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resourcesAsync = ref.watch(groupResourcesProvider(groupId));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(groupResourcesProvider(groupId));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const M3CollapsingAppBar(
              title: Text('Resources'),
              pinned: true,
            ),
            resourcesAsync.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorDisplay(
                  error: err.toString(),
                  onRetry: () =>
                      ref.invalidate(groupResourcesProvider(groupId)),
                ),
              ),
              data: (resources) {
                if (resources.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'No Resources Available',
                      description:
                          'There are no active resources set up in this group yet.',
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      buildConnectedItems(
                        itemCount: resources.length,
                        builder: (i, borderRadius) => _buildResourceCard(
                          context,
                          resources[i],
                          borderRadius,
                          colorScheme,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceCard(
    BuildContext context,
    dynamic resource,
    BorderRadius borderRadius,
    ColorScheme colorScheme,
  ) {
    final cardWidget = ConnectedCard(
      borderRadius: borderRadius,
      borderSide: BorderSide(
        color: colorScheme.outlineVariant.withValues(alpha: 0.2),
      ),
      onTap: () => context.push(
        '/groups/$groupId/resources/${resource.id}',
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        children: [
          ResourceAvatar(
            iconKey: resource.icon,
            colorHex: resource.color,
            name: resource.name,
            size: 44,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resource.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Capacity: ${resource.capacity}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${AppDateUtils.formatSlotDuration(resource.slotDurationMinutes, compact: true)} slot',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                if (resource.description != null &&
                    resource.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    resource.description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.8),
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_outlined,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );

    if (resource.isActive) return cardWidget;
    return Opacity(opacity: 0.55, child: cardWidget);
  }
}
