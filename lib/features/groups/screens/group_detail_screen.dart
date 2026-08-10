import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../providers/groups_provider.dart';
import '../../resources/providers/resources_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_display.dart';

class GroupDetailScreen extends ConsumerWidget {
  final String groupId;

  const GroupDetailScreen({
    super.key,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupDetailProvider(groupId));
    final resourcesAsync = ref.watch(groupResourcesProvider(groupId));

    return Scaffold(
      headers: [
        AppBar(
          title: groupAsync.when(
            data: (group) => Text(group.name),
            loading: () => const Text('Loading Group...'),
            error: (_, __) => const Text('Group Details'),
          ),
          leading: [
            IconButton.ghost(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/groups'),
            ),
          ],
          trailing: [
            IconButton.ghost(
              icon: const Icon(Icons.people),
              onPressed: () => context.push('/groups/$groupId/members'),
            ),
            IconButton.ghost(
              icon: const Icon(Icons.bookmark),
              onPressed: () => context.push('/groups/$groupId/my_bookings'),
            ),
          ],
        ),
      ],
      footers: groupAsync.when(
        data: (group) => group.isAdmin
            ? [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.background,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).colorScheme.border,
                        width: 1,
                      ),
                    ),
                  ),
                  child: PrimaryButton(
                    onPressed: () => context.push('/groups/$groupId/resources/create'),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, size: 18),
                        SizedBox(width: 8),
                        Text('Add Resource'),
                      ],
                    ),
                  ),
                ),
              ]
            : <Widget>[],
        loading: () => <Widget>[],
        error: (_, __) => <Widget>[],
      ),
      child: groupAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorDisplay(
          error: err.toString(),
          onRetry: () {
            ref.invalidate(groupDetailProvider(groupId));
            ref.invalidate(groupResourcesProvider(groupId));
          },
        ),
        data: (group) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group Details Header Metadata (No Card Layout)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    // Member Count
                    GestureDetector(
                      onTap: () => context.push('/groups/$groupId/members'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.muted,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people_outline, size: 14),
                            const SizedBox(width: 5),
                            Text('${group.memberCount} member${group.memberCount == 1 ? '' : 's'}')
                                .small()
                                .semiBold(),
                          ],
                        ),
                      ),
                    ),

                    // Role Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.muted,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_user_outlined, size: 14),
                          const SizedBox(width: 5),
                          Text(group.role).small().semiBold(),
                        ],
                      ),
                    ),

                    // Invite Code (Tap to Copy)
                    if (group.inviteCode != null && group.inviteCode!.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: group.inviteCode!));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.muted,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.vpn_key_outlined, size: 14),
                              const SizedBox(width: 5),
                              Text('Code: ${group.inviteCode}').mono().small(),
                              const SizedBox(width: 4),
                              const Icon(Icons.copy, size: 12),
                            ],
                          ),
                        ),
                      ),
                  ],
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
                    IconButton.ghost(
                      icon: const Icon(Icons.refresh, size: 16),
                      onPressed: () => ref.invalidate(groupResourcesProvider(groupId)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Resources List
              Expanded(
                child: resourcesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => ErrorDisplay(
                    error: err.toString(),
                    onRetry: () => ref.invalidate(groupResourcesProvider(groupId)),
                  ),
                  data: (resources) {
                    if (resources.isEmpty) {
                      return EmptyState(
                        icon: Icons.inventory_2,
                        title: 'No Resources Added',
                        description: group.isAdmin
                            ? 'Create resources (e.g. Washing Machine, Court 1, Meeting Room) to allow member booking.'
                            : 'No resources have been added to this group yet.',
                        action: group.isAdmin
                            ? PrimaryButton(
                                onPressed: () => context.push('/groups/$groupId/resources/create'),
                                child: const Text('Add Resource'),
                              )
                            : null,
                      );
                    }

                    return RefreshTrigger(
                      onRefresh: () async => ref.invalidate(groupResourcesProvider(groupId)),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        itemCount: resources.length,
                        itemBuilder: (context, index) {
                          final resource = resources[index];
                          final cardWidget = GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => context.push('/groups/$groupId/resources/${resource.id}'),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(resource.name).small().semiBold(),
                                        ),
                                      ],
                                    ),
                                    if (resource.description != null && resource.description!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(resource.description!).muted().small(),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.people_outline, size: 14),
                                        const SizedBox(width: 4),
                                        Text('${resource.capacity}').small().muted(),
                                        const SizedBox(width: 12),
                                        const Icon(Icons.timer_outlined, size: 14),
                                        const SizedBox(width: 4),
                                        Text('${resource.slotDurationMinutes}m').small().muted(),
                                        const Spacer(),
                                        OutlineButton(
                                          onPressed: () => context.push('/groups/$groupId/resources/${resource.id}/book'),
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
                            child: resource.isActive
                                ? cardWidget
                                : Opacity(opacity: 0.55, child: cardWidget),
                          );
                        },
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
