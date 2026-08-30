import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/storage/local_cache_service.dart';
import 'models/resource.dart';
import 'models/booking_rule.dart';

class ResourcesRepository {
  final ApiClient _apiClient;
  final LocalCacheService? _cache;

  ResourcesRepository(this._apiClient, [this._cache]);

  Future<List<Resource>> getResources(String groupId) async {
    final cacheKey = 'group_resources_$groupId';
    try {
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
      final resources = response.data;
      await _cache?.setList(
        cacheKey,
        resources.map((r) => r.toJson()).toList(),
      );
      return resources;
    } on NetworkException {
      final cached = await _cache?.getList<Resource>(
        cacheKey,
        (json) => Resource.fromJson(json as Map<String, dynamic>),
      );
      if (cached != null) {
        return cached;
      }
      throw const OfflineException(
        'You are offline and no cached resources were found for this group.',
      );
    }
  }

  Future<Resource> getResourceDetail(String groupId, String resourceId) async {
    final cacheKey = 'resource_detail_${groupId}_$resourceId';
    try {
      final response = await _apiClient.get<Resource>(
        ApiConstants.resourceDetail(groupId, resourceId),
        fromJson: (json) => Resource.fromJson(json as Map<String, dynamic>),
      );
      final resource = response.data;
      await _cache?.set(cacheKey, resource.toJson());
      return resource;
    } on NetworkException {
      final cached = await _cache?.get<Resource>(
        cacheKey,
        (json) => Resource.fromJson(json as Map<String, dynamic>),
      );
      if (cached != null) {
        return cached;
      }
      throw const OfflineException(
        'You are offline and no cached details exist for this resource.',
      );
    }
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
    final resource = response.data;
    await _cache?.set('resource_detail_${groupId}_$resourceId', resource.toJson());
    return resource;
  }

  Future<void> deleteResource(String groupId, String resourceId) async {
    await _apiClient.delete(ApiConstants.resourceDetail(groupId, resourceId));
    await _cache?.remove('resource_detail_${groupId}_$resourceId');
  }

  Future<List<BookingRule>> getBookingRules(
    String groupId,
    String resourceId,
  ) async {
    final cacheKey = 'booking_rules_${groupId}_$resourceId';
    try {
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
      final rules = response.data;
      await _cache?.setList(
        cacheKey,
        rules.map((r) => r.toJson()).toList(),
      );
      return rules;
    } on NetworkException {
      final cached = await _cache?.getList<BookingRule>(
        cacheKey,
        (json) => BookingRule.fromJson(json as Map<String, dynamic>),
      );
      if (cached != null) {
        return cached;
      }
      throw const OfflineException(
        'You are offline and no cached rules exist for this resource.',
      );
    }
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
    final updatedRules = response.data;
    await _cache?.setList(
      'booking_rules_${groupId}_$resourceId',
      updatedRules.map((r) => r.toJson()).toList(),
    );
    return updatedRules;
  }
}

final resourcesRepositoryProvider = Provider<ResourcesRepository>((ref) {
  return ResourcesRepository(
    ref.watch(apiClientProvider),
    ref.watch(localCacheServiceProvider),
  );
});
