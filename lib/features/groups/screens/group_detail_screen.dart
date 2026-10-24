import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/groups_provider.dart';
import '../../resources/providers/resources_provider.dart';
import '../../resources/screens/create_resource_sheet.dart';
import '../../../core/ui/ui.dart';
import '../../../core/utils/deep_link_utils.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_display.dart';

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
            SliverAppBar.large(
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
                              if (hasInviteCode) ...[
                                Expanded(
                                  child: FilledButton.tonalIcon(
                                    onPressed: () =>
                                        DeepLinkUtils.showInviteSheet(
                                      context,
                                      groupName: group.name,
                                      inviteCode: group.inviteCode!,
                                    ),
                                    icon: const Icon(
                                      Icons.share_outlined,
                                      size: 16,
                                    ),
                                    label: const Text('Invite'),
                                    style: FilledButton.styleFrom(
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                        IconButton(
                          icon: const Icon(Icons.refresh_outlined, size: 16),
                          onPressed: () => ref.invalidate(
                            groupResourcesProvider(groupId),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: resourcesAsync.when(
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => SliverFillRemaining(
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

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final resource = resources[index];
                        final cardWidget = PressableScale(
                          onTap: () => context.push(
                            '/groups/$groupId/resources/${resource.id}',
                          ),
                          child: Card(
                            elevation: 0,
                            color: colorScheme.surfaceContainerLow,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: colorScheme.outlineVariant
                                    .withOpacity(0.4),
                              ),
                            ),
                            child: Padding(
                              padding: kCardPadding,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(resource.name).h4(),
                                      ),
                                    ],
                                  ),
                                  if (resource.description != null &&
                                      resource.description!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      resource.description!,
                                    ).muted().small(),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.people_outline,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text('${resource.capacity}')
                                          .small()
                                          .muted(),
                                      const SizedBox(width: 12),
                                      const Icon(
                                        Icons.timer_outlined,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text('${resource.slotDurationMinutes}m')
                                          .small()
                                          .muted(),
                                      const Spacer(),
                                      OutlineButton(
                                        onPressed: () => context.push(
                                          '/groups/$groupId/resources/${resource.id}/book',
                                        ),
                                        style: TextButton.styleFrom(
                                          minimumSize: const Size(0, 32),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        child: const Text('Book'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Entrance(
                            delay: Duration(milliseconds: index * 60),
                            child: resource.isActive
                                ? cardWidget
                                : Opacity(
                                    opacity: 0.55,
                                    child: cardWidget,
                                  ),
                          ),
                        );
                      },
                      childCount: resources.length,
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
