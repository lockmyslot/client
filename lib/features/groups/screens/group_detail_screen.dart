import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/groups_provider.dart';
import 'edit_group_sheet.dart';
import '../../resources/data/models/resource.dart';
import '../../resources/providers/resources_provider.dart';
import '../../resources/screens/create_resource_sheet.dart';
import '../../resources/widgets/resource_avatar.dart';
import '../../../core/ui/ui.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/deep_link_utils.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_display.dart';
import '../../../shared/widgets/m3_collapsing_app_bar.dart';

class GroupDetailScreen extends ConsumerWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupDetailProvider(groupId));
    final resourcesAsync = ref.watch(groupResourcesProvider(groupId));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.bolt_outlined),
        label: const Text('Quick Book'),
        onPressed: () => context.push('/quick-book?group=$groupId'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(groupDetailProvider(groupId));
          ref.invalidate(groupResourcesProvider(groupId));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            M3CollapsingAppBar(
              title: groupAsync.when(
                data: (group) => Text(group.name),
                loading: () => const Text('Loading Group...'),
                error: (_, __) => const Text('Group Details'),
              ),
              pinned: true,
            ),
            groupAsync.maybeWhen(
              data: (group) {
                final hasInviteCode =
                    group.inviteCode != null && group.inviteCode!.isNotEmpty;
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // KPI Stat Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              KpiStatChip(
                                icon: Icons.people_outline,
                                value: '${group.memberCount}',
                                label: group.memberCount == 1
                                    ? 'Member'
                                    : 'Members',
                                onTap: () =>
                                    context.push('/groups/$groupId/members'),
                              ),
                              const SizedBox(width: 8),
                              KpiStatChip(
                                icon: group.isAdmin
                                    ? Icons.shield_outlined
                                    : Icons.person_outline,
                                value: group.isAdmin ? 'Admin' : 'Member',
                                label: 'Role',
                                iconColor: group.isAdmin
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                              if (hasInviteCode) ...[
                                const SizedBox(width: 8),
                                KpiStatChip(
                                  icon: Icons.vpn_key_outlined,
                                  value: group.inviteCode!,
                                  label: 'Code',
                                  isMonospace: true,
                                  onTap: () => DeepLinkUtils.showInviteSheet(
                                    context,
                                    groupName: group.name,
                                    inviteCode: group.inviteCode!,
                                    groupId: group.id,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Quick Action Buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              if (group.isAdmin) ...[
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      EditGroupSheet.show(context, group);
                                    },
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 16,
                                    ),
                                    label: const Text('Edit'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => context.push(
                                    '/groups/$groupId/my_bookings',
                                  ),
                                  icon: const Icon(
                                    Icons.bookmark_border_outlined,
                                    size: 16,
                                  ),
                                  label: const Text('My Bookings'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Resources').h3(),
                    if (groupAsync.when(
                      data: (group) => group.isAdmin,
                      loading: () => false,
                      error: (_, __) => false,
                    ))
                      IconButton(
                        icon: const Icon(Icons.add_outlined),
                        onPressed: () {
                          final group = groupAsync.value;
                          CreateResourceSheet.show(
                            context,
                            groupId: groupId,
                            groupName: group?.name,
                          );
                        },
                      ),
                  ],
                ),
              ),
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
                final group = groupAsync.value;
                final isAdmin = group?.isAdmin ?? false;

                if (resources.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'No Resources Added',
                      description: isAdmin
                          ? 'Create resources (e.g. Washing Machine, Court 1, Meeting Room) to allow member booking.'
                          : 'No resources have been added to this group yet.',
                      action: isAdmin
                          ? PrimaryButton(
                              onPressed: () {
                                final group = groupAsync.value;
                                CreateResourceSheet.show(
                                    context,
                                    groupId: groupId,
                                    groupName: group?.name,
                                  );
                                },
                                child: const Text('Add Resource'),
                              )
                            : null,
                      ),
                    );
                  }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      for (int i = 0; i < resources.length; i++) ...[
                        if (i > 0) const SizedBox(height: 2),
                        _buildResourceCard(
                          context,
                          resources[i],
                          _getResourceItemRadius(i, resources.length),
                          colorScheme,
                        ),
                      ],
                    ]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  BorderRadius _getResourceItemRadius(int index, int totalCount) {
    const double large = 16.0;
    const double small = 4.0;

    if (totalCount <= 1) {
      return BorderRadius.circular(large);
    }

    if (index == 0) {
      return const BorderRadius.only(
        topLeft: Radius.circular(large),
        topRight: Radius.circular(large),
        bottomLeft: Radius.circular(small),
        bottomRight: Radius.circular(small),
      );
    }

    if (index == totalCount - 1) {
      return const BorderRadius.only(
        topLeft: Radius.circular(small),
        topRight: Radius.circular(small),
        bottomLeft: Radius.circular(large),
        bottomRight: Radius.circular(large),
      );
    }

    return const BorderRadius.all(Radius.circular(small));
  }

  Widget _buildResourceCard(
    BuildContext context,
    Resource resource,
    BorderRadius borderRadius,
    ColorScheme colorScheme,
  ) {
    final cardWidget = Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: () => context.push(
          '/groups/$groupId/resources/${resource.id}',
        ),
        child: Padding(
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
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
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
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
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
        ),
      ),
    );

    if (resource.isActive) return cardWidget;
    return Opacity(opacity: 0.55, child: cardWidget);
  }
}
