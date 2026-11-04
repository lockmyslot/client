import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/resources_provider.dart';
import '../widgets/resource_avatar.dart';
import '../../../core/ui/ui.dart';
import '../../../core/utils/date_utils.dart';
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
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final resource = resources[index];
                        final cardWidget = Card(
                          elevation: 0,
                          color: colorScheme.surfaceContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: colorScheme.outlineVariant
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                          child: GestureDetector(
                            onTap: () => context.push(
                              '/groups/$groupId/resources/${resource.id}',
                            ),
                            child: Padding(
                              padding: kCardPadding,
                              child: Row(
                                children: [
                                  ResourceAvatar(
                                    iconKey: resource.icon,
                                    colorHex: resource.color,
                                    name: resource.name,
                                    size: 44,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(resource.name).h4(),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.people_outline,
                                              size: 14,
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 4),
                                            Text('Capacity: ${resource.capacity}')
                                                .small()
                                                .muted(),
                                            const SizedBox(width: 12),
                                            Icon(
                                              Icons.timer_outlined,
                                              size: 14,
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 4),
                                            Text('${AppDateUtils.formatSlotDuration(resource.slotDurationMinutes, compact: true)} slot')
                                                .small()
                                                .muted(),
                                          ],
                                        ),
                                        if (resource.description != null &&
                                            resource.description!
                                                .isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(resource.description!)
                                              .muted()
                                              .small(),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 20,
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.6),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: resource.isActive
                              ? cardWidget
                              : Opacity(opacity: 0.55, child: cardWidget),
                        );
                      },
                      childCount: resources.length,
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
}
