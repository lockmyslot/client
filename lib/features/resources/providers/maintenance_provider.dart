import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/maintenance_task.dart';
import '../data/resources_repository.dart';
import '../../bookings/providers/availability_provider.dart';

final resourceMaintenanceProvider = FutureProvider.family<
  List<MaintenanceTask>,
  ({String groupId, String resourceId, String? status})
>((ref, arg) async {
  final repo = ref.watch(resourcesRepositoryProvider);
  return await repo.getResourceMaintenance(
    arg.groupId,
    arg.resourceId,
    status: arg.status,
  );
});

final groupMaintenanceProvider = FutureProvider.family<
  List<MaintenanceTask>,
  ({String groupId, String? status})
>((ref, arg) async {
  final repo = ref.watch(resourcesRepositoryProvider);
  return await repo.getGroupMaintenance(arg.groupId, status: arg.status);
});

final maintenanceDetailProvider = FutureProvider.family<
  MaintenanceTask,
  ({String groupId, String resourceId, String taskId})
>((ref, arg) async {
  final repo = ref.watch(resourcesRepositoryProvider);
  return await repo.getMaintenanceDetail(
    arg.groupId,
    arg.resourceId,
    arg.taskId,
  );
});

class MaintenanceActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  final ResourcesRepository _repo;

  MaintenanceActionsNotifier(this._ref, this._repo)
    : super(const AsyncValue.data(null));

  Future<MaintenanceTask> createMaintenanceTask({
    required String groupId,
    required String resourceId,
    required Map<String, dynamic> body,
  }) async {
    state = const AsyncValue.loading();
    try {
      final task = await _repo.createMaintenanceTask(groupId, resourceId, body);
      _ref.invalidate(resourceMaintenanceProvider);
      _ref.invalidate(groupMaintenanceProvider);
      _ref.invalidate(availabilityProvider);
      state = const AsyncValue.data(null);
      return task;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<MaintenanceTask> updateMaintenanceTask({
    required String groupId,
    required String resourceId,
    required String taskId,
    required Map<String, dynamic> body,
  }) async {
    state = const AsyncValue.loading();
    try {
      final task = await _repo.updateMaintenanceTask(
        groupId,
        resourceId,
        taskId,
        body,
      );
      _ref.invalidate(resourceMaintenanceProvider);
      _ref.invalidate(groupMaintenanceProvider);
      _ref.invalidate(maintenanceDetailProvider);
      _ref.invalidate(availabilityProvider);
      state = const AsyncValue.data(null);
      return task;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteMaintenanceTask({
    required String groupId,
    required String resourceId,
    required String taskId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteMaintenanceTask(groupId, resourceId, taskId);
      _ref.invalidate(resourceMaintenanceProvider);
      _ref.invalidate(groupMaintenanceProvider);
      _ref.invalidate(availabilityProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final maintenanceActionsProvider =
    StateNotifierProvider<MaintenanceActionsNotifier, AsyncValue<void>>((ref) {
      final repo = ref.watch(resourcesRepositoryProvider);
      return MaintenanceActionsNotifier(ref, repo);
    });
