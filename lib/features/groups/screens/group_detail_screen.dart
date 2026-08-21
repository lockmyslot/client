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

  const GroupDetailScreen({
    super.key,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupDetailProvider(groupId));
    final resourcesAsync = ref.watch(groupResourcesProvider(groupId));

    final bottomBar = groupAsync.when(
      data: (group) => group.isAdmin
          ? Container(
              padding: const EdgeInsets.all(14),
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
                onPressed: () => context.push('/groups/$groupId/resources/create'),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Add Resource'),
                  ],
                ),
              ),
            )
          : null,
      loading: () => null,
      error: (_, __) => null,
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
          IconButton(
            icon: const Icon(Icons.people_outlined),
            onPressed: () => context.push('/groups/$groupId/members'),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            onPressed: () => context.push('/groups/$groupId/my_bookings'),
          ),
        ],
      ),
      bottomNavigationBar: bottomBar,
      body: groupAsync.when(
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
              // Group Details Header Metadata Card
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: SizedBox(
                      height: 40,
                      child: Row(
                        children: [
                          // Member Count (Tap to View Members)
                          Expanded(
                            child: InkWell(
                              onTap: () => context.push('/groups/$groupId/members'),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Text('Members').small().muted(),
                                    Text('${group.memberCount}'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Container(height: 20, width: 1, color: Theme.of(context).colorScheme.outlineVariant),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text('Role').small().muted(),
                                Text(group.role),
                              ],
                            ),
                          ),
                          if (group.inviteCode != null && group.inviteCode!.isNotEmpty) ...[
                            Container(height: 20, width: 1, color: Theme.of(context).colorScheme.outlineVariant),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: group.inviteCode!));
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('Code').small().muted(),
                                          const SizedBox(width: 3),
                                          const Icon(Icons.copy_outlined, size: 12),
                                        ],
                                      ),
                                      Text(group.inviteCode!).mono(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
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
                    IconButton(
                      icon: const Icon(Icons.refresh_outlined, size: 16),
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
                        icon: Icons.inventory_2_outlined,
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

                    return RefreshIndicator(
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
                                          style: TextButton.styleFrom(
                                            minimumSize: const Size(0, 32),
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
