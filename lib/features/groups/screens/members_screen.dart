import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../providers/groups_provider.dart';
import '../data/groups_repository.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/error_display.dart';

class MembersScreen extends ConsumerWidget {
  final String groupId;

  const MembersScreen({
    super.key,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupDetailProvider(groupId));
    final membersAsync = ref.watch(groupMembersProvider(groupId));

    return Scaffold(
      headers: [
        AppBar(
          title: const Text('Group Members'),
          leading: [
            IconButton.ghost(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ],
      child: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorDisplay(
          error: err.toString(),
          onRetry: () => ref.invalidate(groupMembersProvider(groupId)),
        ),
        data: (members) {
          final group = groupAsync.value;
          final isAdmin = group?.isAdmin ?? false;

          return Column(
            children: [
              if (group?.inviteCode != null) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.vpn_key, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Group Invite Code').small().semiBold(),
                                Text(group!.inviteCode!).mono().h4(),
                              ],
                            ),
                          ),
                          SecondaryButton(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: group.inviteCode!));
                            },
                            child: const Row(
                              children: [
                                Icon(Icons.copy, size: 14),
                                SizedBox(width: 4),
                                Text('Copy'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.muted,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    member.displayName.isNotEmpty
                                        ? member.displayName[0].toUpperCase()
                                        : 'U',
                                  ).h4(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(member.displayName).p(),
                                    Text('Joined ${AppDateUtils.formatDisplayDate(member.joinedAt)}')
                                        .muted()
                                        .small(),
                                  ],
                                ),
                              ),
                              PrimaryBadge(child: Text(member.role)),
                              if (isAdmin && !member.isAdmin) ...[
                                const SizedBox(width: 8),
                                IconButton.ghost(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () async {
                                    final confirmed = await ConfirmDialog.show(
                                      context,
                                      title: 'Remove Member',
                                      message: 'Are you sure you want to remove ${member.displayName} from the group?',
                                      confirmText: 'Remove',
                                      isDestructive: true,
                                    );
                                    if (confirmed == true) {
                                      await ref
                                          .read(groupsRepositoryProvider)
                                          .removeMember(groupId, member.userId);
                                      ref.invalidate(groupMembersProvider(groupId));
                                      ref.invalidate(groupDetailProvider(groupId));
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
