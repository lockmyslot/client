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

class MembersScreen extends ConsumerWidget {
  final String groupId;

  const MembersScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupDetailProvider(groupId));
    final membersAsync = ref.watch(groupMembersProvider(groupId));

    final inviteCodeBar = groupAsync.maybeWhen(
      data: (group) {
        final inviteCode = group.inviteCode;
        if (inviteCode == null || inviteCode.isEmpty) {
          return null;
        }
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
            child: Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.vpn_key_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Group Invite Code').small().muted(),
                          Text(inviteCode).mono().semiBold(),
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
                      icon: const Icon(Icons.person_add_outlined, size: 16),
                      label: const Text('Invite'),
                    ),
                  ],
                ),
              ),
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
          const M3CollapsingAppBar(
            title: Text('Group Members'),
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
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Entrance(
                          delay: Duration(milliseconds: 60 + index * 60),
                          child: Card(
                            elevation: 0,
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainer,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: Padding(
                              padding: kCardPadding,
                              child: Row(
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primaryContainer,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            member.displayName.isNotEmpty
                                                ? member.displayName[0]
                                                      .toUpperCase()
                                                : 'U',
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimaryContainer,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (member.isAdmin)
                                        Positioned(
                                          right: -2,
                                          bottom: -2,
                                          child: Container(
                                            padding: const EdgeInsets.all(2.5),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainer,
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.shield,
                                              size: 9,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary,
                                            ),
                                          ),
                                        )
                                      else if (member.isGuest)
                                        Positioned(
                                          right: -2,
                                          bottom: -2,
                                          child: Container(
                                            padding: const EdgeInsets.all(2.5),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainer,
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.badge,
                                              size: 9,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSecondary,
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
                                        ).semiBold(),
                                        if (member.username != null &&
                                            member.username!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            '@${member.username}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ).muted().small(),
                                        ],
                                        const SizedBox(height: 2),
                                        Text(
                                          'Joined ${AppDateUtils.formatDisplayDate(member.joinedAt)}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ).muted().small(),
                                      ],
                                    ),
                                  ),
                                  if (isAdmin && !member.isAdmin) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
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
