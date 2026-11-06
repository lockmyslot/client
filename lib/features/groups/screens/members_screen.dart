import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/groups_provider.dart';
import '../data/groups_repository.dart';
import '../../../core/ui/ui.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_display.dart';
import '../../../shared/widgets/m3_collapsing_app_bar.dart';
import 'unified_invite_sheet.dart';
import 'change_role_sheet.dart';

class MembersScreen extends ConsumerWidget {
  final String groupId;

  const MembersScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final groupAsync = ref.watch(groupDetailProvider(groupId));
    final membersAsync = ref.watch(groupMembersProvider(groupId));

    final inviteCodeBar = groupAsync.maybeWhen(
      data: (group) {
        final inviteCode = group.inviteCode;
        if (inviteCode == null || inviteCode.isEmpty || group.isGuest) {
          return null;
        }

        return SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.vpn_key_outlined,
                    size: 20,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Group Invite Code',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        inviteCode,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    UnifiedInviteSheet.show(
                      context,
                      groupName: group.name,
                      inviteCode: inviteCode,
                      groupId: group.id,
                      initialTab: InviteTab.share,
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    backgroundColor:
                        cs.primaryContainer.withValues(alpha: 0.5),
                    foregroundColor: cs.onPrimaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.person_add_outlined, size: 16),
                  label: const Text('Invite'),
                ),
              ],
            ),
          ),
        );
      },
      orElse: () => null,
    );

    return Scaffold(
      bottomNavigationBar: inviteCodeBar,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          M3CollapsingAppBar(
            title: const Text('Group Members'),
            subtitle: groupAsync.maybeWhen(
              data: (g) => Text(g.name),
              orElse: () => null,
            ),
            pinned: true,
          ),
          membersAsync.when(
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: ErrorDisplay(
                error: err.toString(),
                onRetry: () => ref.invalidate(groupMembersProvider(groupId)),
              ),
            ),
            data: (members) {
              final group = groupAsync.value;
              final isAdmin = group?.isAdmin ?? false;
              final isModerator = group?.isModerator ?? false;

              if (members.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.people_outline,
                    title: 'No Members',
                    description: 'There are no members in this group.',
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final member = members[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Entrance(
                          delay: Duration(milliseconds: 60 + index * 50),
                          child: Container(
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: cs.outlineVariant
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: cs.primaryContainer,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          member.displayName.isNotEmpty
                                              ? member.displayName[0]
                                                  .toUpperCase()
                                              : 'U',
                                          style: TextStyle(
                                            color: cs.onPrimaryContainer,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (member.isAdmin)
                                      Positioned(
                                        right: -2,
                                        bottom: -2,
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: cs.primary,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: cs.surfaceContainerLow,
                                              width: 2,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.shield,
                                            size: 10,
                                            color: cs.onPrimary,
                                          ),
                                        ),
                                      )
                                    else if (member.isGuest)
                                      Positioned(
                                        right: -2,
                                        bottom: -2,
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: cs.secondary,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: cs.surfaceContainerLow,
                                              width: 2,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.badge,
                                            size: 10,
                                            color: cs.onSecondary,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        member.displayName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (member.username != null &&
                                          member.username!.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          '@${member.username}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.labelMedium
                                              ?.copyWith(
                                            color: cs.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Text(
                                        member.isGuest &&
                                                member.expiresAt != null
                                            ? 'Joined ${AppDateUtils.formatDisplayDate(member.joinedAt)} • Expires ${AppDateUtils.formatDisplayDate(member.expiresAt!)}'
                                            : 'Joined ${AppDateUtils.formatDisplayDate(member.joinedAt)}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: cs.onSurfaceVariant
                                              .withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isAdmin && !member.isAdmin) ...[
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.manage_accounts_outlined,
                                      size: 20,
                                    ),
                                    tooltip: 'Change Role',
                                    onPressed: () => ChangeRoleSheet.show(
                                      context,
                                      groupId: groupId,
                                      member: member,
                                    ),
                                  ),
                                ],
                                if ((isAdmin && !member.isAdmin) ||
                                    (isModerator && member.isGuest)) ...[
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: cs.error,
                                      size: 20,
                                    ),
                                    tooltip: 'Remove Member',
                                    onPressed: () async {
                                      final confirmed =
                                          await ConfirmDialog.show(
                                        context,
                                        title: 'Remove Member',
                                        message:
                                            'Are you sure you want to remove ${member.displayName} from the group?',
                                        confirmText: 'Remove',
                                        isDestructive: true,
                                      );
                                      if (confirmed == true) {
                                        await ref
                                            .read(groupsRepositoryProvider)
                                            .removeMember(
                                              groupId,
                                              member.userId,
                                            );
                                        ref.invalidate(
                                          groupMembersProvider(groupId),
                                        );
                                        ref.invalidate(
                                          groupDetailProvider(groupId),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: members.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
