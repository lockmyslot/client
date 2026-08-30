import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/storage/local_cache_service.dart';
import 'models/group.dart';
import 'models/group_member.dart';

class GroupsRepository {
  final ApiClient _apiClient;
  final LocalCacheService? _cache;

  GroupsRepository(this._apiClient, [this._cache]);

  Future<List<Group>> getMyGroups() async {
    const cacheKey = 'my_groups';
    try {
      final response = await _apiClient.get<List<Group>>(
        ApiConstants.groups,
        fromJson: (json) {
          if (json is List) {
            return json
                .map((e) => Group.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          return [];
        },
      );
      final groups = response.data;
      await _cache?.setList(
        cacheKey,
        groups.map((g) => g.toJson()).toList(),
      );
      return groups;
    } on NetworkException {
      final cached = await _cache?.getList<Group>(
        cacheKey,
        (json) => Group.fromJson(json as Map<String, dynamic>),
      );
      if (cached != null) {
        return cached;
      }
      throw const OfflineException(
        'You are offline and no cached groups were found.',
      );
    }
  }

  Future<Group> createGroup(String name) async {
    final response = await _apiClient.post<Group>(
      ApiConstants.groups,
      body: {'name': name},
      fromJson: (json) => Group.fromJson(json as Map<String, dynamic>),
    );
    return response.data;
  }

  Future<Group> joinGroup(String inviteCode) async {
    final response = await _apiClient.post<Group>(
      ApiConstants.joinGroup,
      body: {'invite_code': inviteCode},
      fromJson: (json) => Group.fromJson(json as Map<String, dynamic>),
    );
    return response.data;
  }

  Future<Group> getGroupDetail(String groupId) async {
    final cacheKey = 'group_detail_$groupId';
    try {
      final response = await _apiClient.get<Group>(
        ApiConstants.groupDetail(groupId),
        fromJson: (json) => Group.fromJson(json as Map<String, dynamic>),
      );
      final group = response.data;
      await _cache?.set(cacheKey, group.toJson());
      return group;
    } on NetworkException {
      final cached = await _cache?.get<Group>(
        cacheKey,
        (json) => Group.fromJson(json as Map<String, dynamic>),
      );
      if (cached != null) {
        return cached;
      }
      throw const OfflineException(
        'You are offline and no cached details exist for this group.',
      );
    }
  }

  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    final cacheKey = 'group_members_$groupId';
    try {
      final response = await _apiClient.get<List<GroupMember>>(
        ApiConstants.groupMembers(groupId),
        fromJson: (json) {
          if (json is List) {
            return json
                .map((e) => GroupMember.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          return [];
        },
      );
      final members = response.data;
      await _cache?.setList(
        cacheKey,
        members.map((m) => m.toJson()).toList(),
      );
      return members;
    } on NetworkException {
      final cached = await _cache?.getList<GroupMember>(
        cacheKey,
        (json) => GroupMember.fromJson(json as Map<String, dynamic>),
      );
      if (cached != null) {
        return cached;
      }
      throw const OfflineException(
        'You are offline and no cached member list was found.',
      );
    }
  }

  Future<void> removeMember(String groupId, String userId) async {
    await _apiClient.delete(ApiConstants.removeMember(groupId, userId));
  }

  Future<void> leaveGroup(String groupId) async {
    await _apiClient.post(ApiConstants.leaveGroup(groupId));
  }

  Future<Group> regenerateInviteCode(String groupId) async {
    final response = await _apiClient.post<Group>(
      ApiConstants.regenerateInvite(groupId),
      fromJson: (json) => Group.fromJson(json as Map<String, dynamic>),
    );
    final group = response.data;
    await _cache?.set('group_detail_$groupId', group.toJson());
    return group;
  }
}

final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  return GroupsRepository(
    ref.watch(apiClientProvider),
    ref.watch(localCacheServiceProvider),
  );
});
