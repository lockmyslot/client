import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/groups_provider.dart';
import '../../../core/ui/ui.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_display.dart';

class GroupsListScreen extends ConsumerWidget {
  const GroupsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(myGroupsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Groups'),
      ),
      body: SlideFadeSwitcher(
        child: groupsAsync.when(
          loading: () => const KeyedSubtree(
            key: ValueKey('loading'),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => KeyedSubtree(
            key: const ValueKey('error'),
            child: ErrorDisplay(
              error: err.toString(),
              onRetry: () => ref.read(myGroupsProvider.notifier).refresh(),
            ),
          ),
          data: (groups) {
            if (groups.isEmpty) {
              return KeyedSubtree(
                key: const ValueKey('empty'),
                child: EmptyState(
                  icon: Icons.group_work_outlined,
                  title: 'No Groups Yet',
                  description:
                      'Create or join a group to start booking shared resources.',
                  action: PrimaryButton(
                    onPressed: () => context.push('/groups/create'),
                    child: const Text('Create Your First Group'),
                  ),
                ),
              );
            }

            return KeyedSubtree(
              key: const ValueKey('data'),
              child: RefreshIndicator(
                onRefresh: () => ref.read(myGroupsProvider.notifier).refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Entrance(
                        delay: Duration(milliseconds: index * 60),
                        child: PressableScale(
                          onTap: () => context.push('/groups/${group.id}'),
                          child: Card(
                            elevation: 0,
                            color: colorScheme.surfaceContainerLow,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: colorScheme.outlineVariant.withOpacity(0.4),
                              ),
                            ),
                            child: Padding(
                              padding: kCardPadding,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.group_outlined,
                                      size: 24,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(group.name).h4(),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: colorScheme.secondaryContainer,
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: Text(
                                                group.role,
                                                style: TextStyle(
                                                  color: colorScheme.onSecondaryContainer,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${group.memberCount} member${group.memberCount == 1 ? '' : 's'}',
                                        ).muted().small(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
