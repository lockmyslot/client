import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/api_constants.dart';
import 'models/resource.dart';
import 'models/booking_rule.dart';

class ResourcesRepository {
  final ApiClient _apiClient;

  ResourcesRepository(this._apiClient);

  Future<List<Resource>> getResources(String groupId) async {
    final response = await _apiClient.get<List<Resource>>(
      ApiConstants.resources(groupId),
      fromJson: (json) {
        if (json is List) {
          return json
              .map((e) => Resource.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
    );
    return response.data;
  }

  Future<Resource> getResourceDetail(String groupId, String resourceId) async {
    final response = await _apiClient.get<Resource>(
      ApiConstants.resourceDetail(groupId, resourceId),
      fromJson: (json) => Resource.fromJson(json as Map<String, dynamic>),
    );
    return response.data;
  }

  Future<Resource> createResource(
    String groupId, {
    required String name,
    String? description,
    required int capacity,
    required int slotDurationMinutes,
  }) async {
    final response = await _apiClient.post<Resource>(
      ApiConstants.resources(groupId),
      body: {
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
        'capacity': capacity,
        'slot_duration_minutes': slotDurationMinutes,
      },
      fromJson: (json) => Resource.fromJson(json as Map<String, dynamic>),
    );
    return response.data;
  }

  Future<Resource> updateResource(
    String groupId,
    String resourceId,
    Map<String, dynamic> body,
  ) async {
    final response = await _apiClient.patch<Resource>(
      ApiConstants.resourceDetail(groupId, resourceId),
      body: body,
      fromJson: (json) => Resource.fromJson(json as Map<String, dynamic>),
    );
    return response.data;
  }

  Future<void> deleteResource(String groupId, String resourceId) async {
    await _apiClient.delete(ApiConstants.resourceDetail(groupId, resourceId));
  }

  Future<List<BookingRule>> getBookingRules(
    String groupId,
    String resourceId,
  ) async {
    final response = await _apiClient.get<List<BookingRule>>(
      ApiConstants.bookingRules(groupId, resourceId),
      fromJson: (json) {
        if (json is List) {
          return json
              .map((e) => BookingRule.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
    );
    return response.data;
  }

  Future<List<BookingRule>> updateBookingRules(
    String groupId,
    String resourceId,
    List<BookingRule> rules,
  ) async {
    final body = rules.map((r) => r.toJson()).toList();
    final response = await _apiClient.put<List<BookingRule>>(
      ApiConstants.bookingRules(groupId, resourceId),
      body: body,
      fromJson: (json) {
        if (json is List) {
          return json
              .map((e) => BookingRule.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      },
    );
    return response.data;
  }
}

final resourcesRepositoryProvider = Provider<ResourcesRepository>((ref) {
  return ResourcesRepository(ref.watch(apiClientProvider));
});
