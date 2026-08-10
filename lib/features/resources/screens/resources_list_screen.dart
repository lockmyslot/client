import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../providers/resources_provider.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_display.dart';

class ResourcesListScreen extends ConsumerWidget {
  final String groupId;

  const ResourcesListScreen({
    super.key,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resourcesAsync = ref.watch(groupResourcesProvider(groupId));

    return Scaffold(
      headers: [
        AppBar(
          title: const Text('Resources'),
          leading: [
            IconButton.ghost(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ],
      child: resourcesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorDisplay(
          error: err.toString(),
          onRetry: () => ref.invalidate(groupResourcesProvider(groupId)),
        ),
        data: (resources) {
          if (resources.isEmpty) {
            return const EmptyState(
              icon: Icons.inventory_2,
              title: 'No Resources Available',
              description: 'There are no active resources set up in this group yet.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: resources.length,
            itemBuilder: (context, index) {
              final resource = resources[index];
              final cardWidget = Card(
                child: GestureDetector(
                  onTap: () => context.push('/groups/$groupId/resources/${resource.id}'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(resource.name).h4()),
                          ],
                        ),
                        if (resource.description != null) ...[
                          const SizedBox(height: 4),
                          Text(resource.description!).muted().small(),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text('Capacity: ${resource.capacity}').small(),
                            const SizedBox(width: 16),
                            Text('Slot: ${resource.slotDurationMinutes} mins').small(),
                            const Spacer(),
                            PrimaryButton(
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
                padding: const EdgeInsets.only(bottom: 12),
                child: resource.isActive
                    ? cardWidget
                    : Opacity(opacity: 0.55, child: cardWidget),
              );
            },
          );
        },
      ),
    );
  }
}
