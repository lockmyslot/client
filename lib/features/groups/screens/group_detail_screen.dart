import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/groups_provider.dart';
import '../../resources/providers/resources_provider.dart';
import '../../../core/ui/ui.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_display.dart';

class GroupDetailScreen extends ConsumerWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupDetailProvider(groupId));
    final resourcesAsync = ref.watch(groupResourcesProvider(groupId));

    final bottomBar = SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
          ),
        ),
        child: PrimaryButton(
          expand: true,
          onPressed: () => context.push('/quick-book?group=$groupId'),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bolt_outlined, size: 18),
              SizedBox(width: 8),
              Text('Quick Book'),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: groupAsync.when(
          data: (group) => Text(group.name),
          loading: () => const Text('Loading Group...'),
          error: (_, __) => const Text('Group Details'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined),
          onPressed: () => context.go('/groups'),
        ),
        actions: [
          if (groupAsync.when(
            data: (group) => group.isAdmin,
            loading: () => false,
            error: (_, __) => false,
          ))
            const IconButton(
              icon: Icon(Icons.verified_user_outlined),
              tooltip: 'Admin',
              onPressed: null,
            ),
        ],
      ),
      bottomNavigationBar: bottomBar,
      body: SlideFadeSwitcher(
        child: groupAsync.when(
          loading: () => const KeyedSubtree(
            key: ValueKey('loading'),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => KeyedSubtree(
            key: const ValueKey('error'),
            child: ErrorDisplay(
              error: err.toString(),
              onRetry: () {
                ref.invalidate(groupDetailProvider(groupId));
                ref.invalidate(groupResourcesProvider(groupId));
              },
            ),
          ),
          data: (group) => KeyedSubtree(
            key: const ValueKey('data'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group Details Header Metadata Card
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                  child: Entrance(
                    delay: const Duration(milliseconds: 60),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: SizedBox(
                          height: 40,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Member Count (Tap to View Members)
                              Expanded(
                                child: InkWell(
                                  onTap: () =>
                                      context.push('/groups/$groupId/members'),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.people_outline,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text('${group.memberCount}'),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                height: 20,
                                width: 1,
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                              ),
                              if (group.inviteCode != null &&
                                  group.inviteCode!.isNotEmpty) ...[
                                Container(
                                  height: 20,
                                  width: 1,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outlineVariant,
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      Clipboard.setData(
                                        ClipboardData(text: group.inviteCode!),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.vpn_key_outlined,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(group.inviteCode!).mono(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              if (group.inviteCode != null &&
                                  group.inviteCode!.isNotEmpty)
                                Container(
                                  height: 20,
                                  width: 1,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outlineVariant,
                                ),
                              Expanded(
                                child: InkWell(
                                  onTap: () => context.push(
                                    '/groups/$groupId/my_bookings',
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.bookmark_outline,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        const Text('Bookings'),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Resources Section Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
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
                              onPressed: () => context.push(
                                '/groups/$groupId/resources/create',
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.refresh_outlined, size: 16),
                            onPressed: () =>
                                ref.invalidate(groupResourcesProvider(groupId)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Resources List
                Expanded(
                  child: SlideFadeSwitcher(
                    child: resourcesAsync.when(
                      loading: () => const KeyedSubtree(
                        key: ValueKey('loading'),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (err, _) => KeyedSubtree(
                        key: const ValueKey('error'),
                        child: ErrorDisplay(
                          error: err.toString(),
                          onRetry: () =>
                              ref.invalidate(groupResourcesProvider(groupId)),
                        ),
                      ),
                      data: (resources) {
                        if (resources.isEmpty) {
                          return KeyedSubtree(
                            key: const ValueKey('empty'),
                            child: EmptyState(
                              icon: Icons.inventory_2_outlined,
                              title: 'No Resources Added',
                              description: group.isAdmin
                                  ? 'Create resources (e.g. Washing Machine, Court 1, Meeting Room) to allow member booking.'
                                  : 'No resources have been added to this group yet.',
                              action: group.isAdmin
                                  ? PrimaryButton(
                                      onPressed: () => context.push(
                                        '/groups/$groupId/resources/create',
                                      ),
                                      child: const Text('Add Resource'),
                                    )
                                  : null,
                            ),
                          );
                        }

                        return KeyedSubtree(
                          key: const ValueKey('data'),
                          child: RefreshIndicator(
                            onRefresh: () async =>
                                ref.invalidate(groupResourcesProvider(groupId)),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              itemCount: resources.length,
                              itemBuilder: (context, index) {
                                final resource = resources[index];
                                final cardWidget = PressableScale(
                                  onTap: () => context.push(
                                    '/groups/$groupId/resources/${resource.id}',
                                  ),
                                  child: Card(
                                    child: Padding(
                                      padding: kCardPadding,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(resource.name).h4(),
                                              ),
                                            ],
                                          ),
                                          if (resource.description != null &&
                                              resource
                                                  .description!
                                                  .isNotEmpty) ...[
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
                                              Text(
                                                '${resource.capacity}',
                                              ).small().muted(),
                                              const SizedBox(width: 12),
                                              const Icon(
                                                Icons.timer_outlined,
                                                size: 14,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${resource.slotDurationMinutes}m',
                                              ).small().muted(),
                                              const Spacer(),
                                              OutlineButton(
                                                onPressed: () => context.push(
                                                  '/groups/$groupId/resources/${resource.id}/book',
                                                ),
                                                style: TextButton.styleFrom(
                                                  minimumSize: const Size(
                                                    0,
                                                    32,
                                                  ),
                                                  tapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                  visualDensity:
                                                      VisualDensity.compact,
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
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
