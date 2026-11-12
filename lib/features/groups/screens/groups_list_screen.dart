import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/groups_repository.dart';
import '../providers/groups_provider.dart';
import '../widgets/group_avatar.dart';
import 'create_group_sheet.dart';
import 'join_group_sheet.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/ui.dart';
import '../../../core/utils/deep_link_utils.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_display.dart';
import '../../../shared/widgets/m3_collapsing_app_bar.dart';
import '../data/models/group.dart';

class GroupsListScreen extends ConsumerWidget {
  const GroupsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(myGroupsProvider);
    final pendingInvitesAsync = ref.watch(pendingInvitesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myGroupsProvider);
          ref.invalidate(pendingInvitesProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            M3CollapsingAppBar(
              title: const Text('My Groups'),
              pinned: true,
            ),
            if (pendingInvitesAsync.valueOrNull?.isNotEmpty ?? false)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppShapes.card,
                      side: BorderSide(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      borderRadius: AppShapes.card,
                      onTap: () => JoinGroupSheet.show(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: AppShapes.control,
                              ),
                              child: Icon(
                                Icons.mail_outline,
                                size: 18,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${pendingInvitesAsync.value!.length} Pending ${pendingInvitesAsync.value!.length == 1 ? "Invitation" : "Invitations"}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Tap to review and join your groups',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FilledButton.tonal(
                              onPressed: () => JoinGroupSheet.show(context),
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                shape: RoundedRectangleBorder(
                                  borderRadius: AppShapes.control,
                                ),
                              ),
                              child: const Text('Review'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            groupsAsync.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorDisplay(
                  error: err.toString(),
                  onRetry: () => ref.invalidate(myGroupsProvider),
                ),
              ),
              data: (groups) {
                if (groups.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.group_work_outlined,
                      title: 'No Groups Yet',
                      description:
                          'Create or join a group to start booking shared resources.',
                      action: PrimaryButton(
                        onPressed: () => CreateGroupSheet.show(context),
                        child: const Text('Create Your First Group'),
                      ),
                    ),
                  );
                }

                final pinnedGroups = groups.where((g) => g.isPinned).toList();
                final unpinnedGroups =
                    groups.where((g) => !g.isPinned).toList();

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (pinnedGroups.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: 10.0,
                            left: 4,
                            top: 4.0,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.push_pin,
                                size: 16,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Pinned',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        _buildGroupSection(
                          context,
                          ref,
                          pinnedGroups,
                          colorScheme,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (unpinnedGroups.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: 10.0,
                            left: 4,
                            top: 4.0,
                          ),
                          child: Text(
                            'All Groups',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                        _buildGroupSection(
                          context,
                          ref,
                          unpinnedGroups,
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

  BorderRadius _getGroupItemRadius(int index, int totalCount) {
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

  Widget _buildGroupSection(
    BuildContext context,
    WidgetRef ref,
    List<Group> sectionGroups,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        for (int i = 0; i < sectionGroups.length; i++) ...[
          if (i > 0) const SizedBox(height: 2),
          _buildGroupCard(
            context,
            ref,
            sectionGroups[i],
            _getGroupItemRadius(i, sectionGroups.length),
            colorScheme,
          ),
        ],
      ],
    );
  }

  Widget _buildGroupCard(
    BuildContext context,
    WidgetRef ref,
    Group group,
    BorderRadius borderRadius,
    ColorScheme colorScheme,
  ) {
    final roleText =
        group.isAdmin ? 'Admin' : (group.isGuest ? 'Guest' : 'Member');
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(
          color: group.isPinned
              ? colorScheme.primary.withValues(alpha: 0.35)
              : colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: () => context.push('/groups/${group.id}'),
        onLongPress: () => _showGroupOptionsSheet(context, ref, group),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              GroupAvatar(
                name: group.name,
                iconKey: group.icon,
                colorHex: group.color,
                size: 48,
                borderRadius: BorderRadius.circular(14),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$roleText • ${group.memberCount} members',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              if (group.isPinned)
                Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: Icon(
                    Icons.push_pin,
                    size: 16,
                    color: colorScheme.primary,
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
  }

  void _showGroupOptionsSheet(
    BuildContext context,
    WidgetRef ref,
    Group group,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 8.0,
              ),
              child: Text(
                group.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                group.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                color: colorScheme.primary,
              ),
              title: Text(
                group.isPinned ? 'Unpin from top' : 'Pin to top',
              ),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(myGroupsProvider.notifier).togglePin(group.id);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.person_add_outlined,
                color: colorScheme.primary,
              ),
              title: const Text('Invite'),
              onTap: () async {
                Navigator.pop(ctx);
                if (group.inviteCode != null &&
                    group.inviteCode!.isNotEmpty) {
                  DeepLinkUtils.showInviteSheet(
                    context,
                    groupName: group.name,
                    inviteCode: group.inviteCode!,
                    groupId: group.id,
                  );
                } else if (group.isAdmin) {
                  try {
                    final detail = await ref
                        .read(groupsRepositoryProvider)
                        .getGroupDetail(group.id);
                    if (context.mounted &&
                        detail.inviteCode != null &&
                        detail.inviteCode!.isNotEmpty) {
                      DeepLinkUtils.showInviteSheet(
                        context,
                        groupName: detail.name,
                        inviteCode: detail.inviteCode!,
                        groupId: detail.id,
                      );
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to load invite code'),
                        ),
                      );
                    }
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Only group admins can invite members',
                        ),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
