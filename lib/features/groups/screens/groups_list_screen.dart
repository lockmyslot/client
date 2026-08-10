import 'package:flutter/material.dart' show showDialog;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../providers/groups_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_display.dart';

class GroupsListScreen extends ConsumerWidget {
  const GroupsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(myGroupsProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      headers: [
        AppBar(
          title: const Text('My Groups'),
          trailing: [
            IconButton.ghost(
              icon: const Icon(Icons.person),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.account_circle, size: 32),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(user?.displayName ?? 'User Profile').h3(),
                                          const Text('Member').small().muted(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    SecondaryButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                    const SizedBox(width: 12),
                                    PrimaryButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        ref.read(authProvider.notifier).logout();
                                      },
                                      child: const Text('Logout'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    onPressed: () => context.push('/groups/join'),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.vpn_key, size: 16),
                        SizedBox(width: 8),
                        Text('Join Group'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    onPressed: () => context.push('/groups/create'),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, size: 16),
                        SizedBox(width: 8),
                        Text('Create Group'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: groupsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => ErrorDisplay(
                error: err.toString(),
                onRetry: () => ref.read(myGroupsProvider.notifier).refresh(),
              ),
              data: (groups) {
                if (groups.isEmpty) {
                  return EmptyState(
                    icon: Icons.group_work,
                    title: 'No Groups Yet',
                    description: 'Create or join a group to start booking shared resources.',
                    action: PrimaryButton(
                      onPressed: () => context.push('/groups/create'),
                      child: const Text('Create Your First Group'),
                    ),
                  );
                }

                return RefreshTrigger(
                  onRefresh: () => ref.read(myGroupsProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => context.push('/groups/${group.id}'),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.muted,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.group, size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(group.name).h4(),
                                            ),
                                            const SizedBox(width: 8),
                                            PrimaryBadge(
                                              child: Text(group.role),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text('${group.memberCount} member${group.memberCount == 1 ? '' : 's'}')
                                            .muted()
                                            .small(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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
