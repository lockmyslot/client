import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/api_constants.dart';
import 'models/group.dart';
import 'models/group_member.dart';

class GroupsRepository {
  final ApiClient _apiClient;

  GroupsRepository(this._apiClient);

  Future<List<Group>> getMyGroups() async {
    final response = await _apiClient.get<List<Group>>(
      ApiConstants.groups,
      fromJson: (json) {
        if (json is List) {
          return json.map((e) => Group.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );
    return response.data;
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
    final response = await _apiClient.get<Group>(
      ApiConstants.groupDetail(groupId),
      fromJson: (json) => Group.fromJson(json as Map<String, dynamic>),
    );
    return response.data;
  }

  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    final response = await _apiClient.get<List<GroupMember>>(
      ApiConstants.groupMembers(groupId),
      fromJson: (json) {
        if (json is List) {
          return json.map((e) => GroupMember.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );
    return response.data;
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
    return response.data;
  }
}

final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  return GroupsRepository(ref.watch(apiClientProvider));
});
