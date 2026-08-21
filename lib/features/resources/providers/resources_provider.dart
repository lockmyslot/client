import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/resource.dart';
import '../data/resources_repository.dart';

final groupResourcesProvider = FutureProvider.family<List<Resource>, String>((
  ref,
  groupId,
) async {
  final repo = ref.watch(resourcesRepositoryProvider);
  return await repo.getResources(groupId);
});

final resourceDetailProvider =
    FutureProvider.family<Resource, ({String groupId, String resourceId})>((
      ref,
      arg,
    ) async {
      final repo = ref.watch(resourcesRepositoryProvider);
      return await repo.getResourceDetail(arg.groupId, arg.resourceId);
    });
