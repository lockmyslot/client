import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/groups_repository.dart';
import '../data/models/group.dart';
import '../data/models/group_member.dart';

final myGroupsProvider = AsyncNotifierProvider<MyGroupsNotifier, List<Group>>(
  () {
    return MyGroupsNotifier();
  },
);

class MyGroupsNotifier extends AsyncNotifier<List<Group>> {
  @override
  Future<List<Group>> build() async {
    final repo = ref.watch(groupsRepositoryProvider);
    return await repo.getMyGroups();
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
