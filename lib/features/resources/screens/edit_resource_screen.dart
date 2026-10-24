import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/models/resource.dart';
import '../providers/resources_provider.dart';
import '../../../shared/widgets/error_display.dart';
import 'edit_resource_sheet.dart';

export 'edit_resource_sheet.dart';

class EditResourceScreen extends ConsumerWidget {
  final String groupId;
  final String resourceId;
  final Resource? initialResource;

  const EditResourceScreen({
    super.key,
    required this.groupId,
    required this.resourceId,
    this.initialResource,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (initialResource != null) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black87 : Colors.black45,
        body: SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: EditResourceSheet(
              groupId: groupId,
              resource: initialResource!,
              onSuccess: (resource) {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/groups/$groupId/resources/$resourceId');
                }
              },
              onClose: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/groups/$groupId/resources/$resourceId');
                }
              },
            ),
          ),
        ),
      );
    }

    final resourceAsync = ref.watch(
      resourceDetailProvider((groupId: groupId, resourceId: resourceId)),
    );

    return Scaffold(
      backgroundColor: isDark ? Colors.black87 : Colors.black45,
      body: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: resourceAsync.when(
            loading: () => Container(
              height: 250,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E24) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E24) : Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ErrorDisplay(
                    error: err.toString(),
                    onRetry: () => ref.invalidate(
                      resourceDetailProvider((
                        groupId: groupId,
                        resourceId: resourceId,
                      )),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/groups/$groupId/resources/$resourceId');
                      }
                    },
                    child: const Text('Back'),
                  ),
                ],
              ),
            ),
            data: (resource) => EditResourceSheet(
              groupId: groupId,
              resource: resource,
              onSuccess: (updated) {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/groups/$groupId/resources/$resourceId');
                }
              },
              onClose: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/groups/$groupId/resources/$resourceId');
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
