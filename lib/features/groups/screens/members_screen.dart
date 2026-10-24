import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/groups_provider.dart';
import '../data/groups_repository.dart';
import '../../../core/ui/ui.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/deep_link_utils.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/error_display.dart';

class MembersScreen extends ConsumerWidget {
  final String groupId;

  const MembersScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupDetailProvider(groupId));
    final membersAsync = ref.watch(groupMembersProvider(groupId));

    return Scaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          const SliverAppBar.large(
            title: Text('Group Members'),
            pinned: true,
          ),
          groupAsync.maybeWhen(
            data: (group) {
              final inviteCode = group.inviteCode;
              if (inviteCode == null || inviteCode.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Group Invite Code').small().muted(),
                                Text(inviteCode).mono().semiBold(),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              DeepLinkUtils.showInviteSheet(
                                context,
                                groupName: group.name,
                                inviteCode: inviteCode,
                              );
                            },
                            icon: const Icon(Icons.share_outlined, size: 16),
                            label: const Text('Share'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
            orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            sliver: membersAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => SliverFillRemaining(
                child: ErrorDisplay(
                  error: err.toString(),
                  onRetry: () => ref.invalidate(groupMembersProvider(groupId)),
                ),
              ),
              data: (members) {
                final group = groupAsync.value;
                final isAdmin = group?.isAdmin ?? false;

                return SliverList(
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
                                .surfaceContainerLow,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant
                                    .withOpacity(0.4),
                              ),
                            ),
                            child: Padding(
                              padding: kCardPadding,
                              child: Row(
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
                                        const SizedBox(height: 2),
                                        Text(
                                          'Joined ${AppDateUtils.formatDisplayDate(member.joinedAt)}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ).muted().small(),
                                      ],
                                    ),
                                  ),
                                  PrimaryBadge(child: Text(member.role)),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
