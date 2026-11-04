import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/groups_repository.dart';
import '../data/models/group.dart';
import '../data/models/group_member.dart';
import '../data/models/group_invite.dart';

final myGroupsProvider = AsyncNotifierProvider<MyGroupsNotifier, List<Group>>(
  () {
    return MyGroupsNotifier();
  },
);

class MyGroupsNotifier extends AsyncNotifier<List<Group>> {
  List<Group> _sortGroups(List<Group> list) {
    final sorted = [...list];
    sorted.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return 0;
    });
    return sorted;
  }

  @override
  Future<List<Group>> build() async {
    final authState = ref.watch(authProvider);
    if (!authState.isAuthenticated) {
      return [];
    }
    final repo = ref.watch(groupsRepositoryProvider);
    final groups = await repo.getMyGroups();
    return _sortGroups(groups);
  }

  Future<void> togglePin(String groupId, {bool? isPinned}) async {
    final currentList = state.value ?? [];
    final currentGroup =
        currentList.where((g) => g.id == groupId).firstOrNull;
    final nextPinned = isPinned ?? !(currentGroup?.isPinned ?? false);

    // Optimistically update the list
    final updatedList = currentList.map((g) {
      if (g.id == groupId) {
        return g.copyWith(isPinned: nextPinned);
      }
      return g;
    }).toList();

    state = AsyncValue.data(_sortGroups(updatedList));

    final repo = ref.read(groupsRepositoryProvider);
    try {
      final actualPinned =
          await repo.togglePinGroup(groupId, isPinned: nextPinned);
      if (actualPinned != nextPinned) {
        final reupdatedList = (state.value ?? updatedList).map((g) {
          if (g.id == groupId) {
            return g.copyWith(isPinned: actualPinned);
          }
          return g;
        }).toList();
        state = AsyncValue.data(_sortGroups(reupdatedList));
      }
    } catch (_) {
      // Retain optimistic state if network fails
    }
    ref.invalidate(groupDetailProvider(groupId));
  }

  Future<Group> createGroup(String name) async {
    final repo = ref.read(groupsRepositoryProvider);
    final group = await repo.createGroup(name);
    ref.invalidateSelf();
    return group;
  }

  Future<Group> joinGroup(String inviteCode) async {
    final repo = ref.read(groupsRepositoryProvider);
    final group = await repo.joinGroup(inviteCode);
    ref.invalidateSelf();
    ref.invalidate(pendingInvitesProvider);
    return group;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

final groupDetailProvider = FutureProvider.family<Group, String>((
  ref,
  groupId,
) async {
  final repo = ref.watch(groupsRepositoryProvider);
  return await repo.getGroupDetail(groupId);
});

final groupMembersProvider = FutureProvider.family<List<GroupMember>, String>((
  ref,
  groupId,
) async {
  final repo = ref.watch(groupsRepositoryProvider);
  return await repo.getGroupMembers(groupId);
});

final pendingInvitesProvider =
    AsyncNotifierProvider<PendingInvitesNotifier, List<GroupInvite>>(() {
  return PendingInvitesNotifier();
});

class PendingInvitesNotifier extends AsyncNotifier<List<GroupInvite>> {
  @override
  Future<List<GroupInvite>> build() async {
    final authState = ref.watch(authProvider);
    if (!authState.isAuthenticated) {
      return [];
    }
    final repo = ref.watch(groupsRepositoryProvider);
    return await repo.getPendingInvites();
  }

  Future<void> accept(String inviteId) async {
    final repo = ref.read(groupsRepositoryProvider);
    await repo.acceptInvite(inviteId);
    ref.invalidate(myGroupsProvider);
    ref.invalidateSelf();
  }

  Future<void> decline(String inviteId) async {
    final repo = ref.read(groupsRepositoryProvider);
    await repo.declineInvite(inviteId);
    ref.invalidateSelf();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
