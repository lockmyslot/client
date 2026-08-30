import 'package:flutter_test/flutter_test.dart';
import 'package:lockmyslot_app/core/api/api_client.dart';
import 'package:lockmyslot_app/core/api/api_exceptions.dart';
import 'package:lockmyslot_app/core/api/api_response.dart';
import 'package:lockmyslot_app/core/storage/local_cache_service.dart';
import 'package:lockmyslot_app/features/groups/data/groups_repository.dart';
import 'package:lockmyslot_app/features/groups/data/models/group.dart';
import 'package:lockmyslot_app/features/resources/data/resources_repository.dart';
import 'package:lockmyslot_app/features/resources/data/models/resource.dart';
import 'package:lockmyslot_app/features/bookings/data/bookings_repository.dart';
import 'package:lockmyslot_app/features/bookings/data/models/booking.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FakeFlutterSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _data[key] = value;
    } else {
      _data.remove(key);
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _data[key];
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.remove(key);
  }

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.clear();
  }
}

class ThrowingApiClient extends Fake implements ApiClient {
  @override
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    T Function(dynamic json)? fromJson,
  }) async {
    throw const NetworkException('Connection failed');
  }
}

void main() {
  late FakeFlutterSecureStorage fakeStorage;
  late LocalCacheService cacheService;

  setUp(() {
    fakeStorage = FakeFlutterSecureStorage();
    cacheService = LocalCacheService(fakeStorage);
  });

  group('LocalCacheService Tests', () {
    test('sets and gets single object successfully', () async {
      final sampleGroup = Group(
        id: 'g-123',
        name: 'Apartment 4B',
        inviteCode: 'APT4BB',
        role: 'ADMIN',
        memberCount: 4,
        createdAt: DateTime(2026, 1, 1),
      );

      await cacheService.set('test_group', sampleGroup.toJson());

      final retrieved = await cacheService.get<Group>(
        'test_group',
        (json) => Group.fromJson(json as Map<String, dynamic>),
      );

      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'g-123');
      expect(retrieved.name, 'Apartment 4B');
      expect(retrieved.inviteCode, 'APT4BB');
    });

    test('sets and gets list of objects successfully', () async {
      final sampleList = [
        Group(
          id: 'g-1',
          name: 'Group 1',
          role: 'ADMIN',
          memberCount: 2,
          createdAt: DateTime(2026, 1, 1),
        ),
        Group(
          id: 'g-2',
          name: 'Group 2',
          role: 'MEMBER',
          memberCount: 5,
          createdAt: DateTime(2026, 1, 2),
        ),
      ];

      await cacheService.setList(
        'group_list',
        sampleList.map((g) => g.toJson()).toList(),
      );

      final retrieved = await cacheService.getList<Group>(
        'group_list',
        (json) => Group.fromJson(json as Map<String, dynamic>),
      );

      expect(retrieved, isNotNull);
      expect(retrieved!.length, 2);
      expect(retrieved[0].id, 'g-1');
      expect(retrieved[1].id, 'g-2');
    });

    test('returns null for nonexistent keys', () async {
      final retrieved = await cacheService.get<Group>(
        'nonexistent',
        (json) => Group.fromJson(json as Map<String, dynamic>),
      );
      expect(retrieved, isNull);
    });

    test('removes cached item properly', () async {
      await cacheService.set('temp', {'foo': 'bar'});
      expect(await cacheService.get('temp', (j) => j), isNotNull);

      await cacheService.remove('temp');
      expect(await cacheService.get('temp', (j) => j), isNull);
    });
  });

  group('Repository Offline Fallback Tests', () {
    test('GroupsRepository falls back to cached groups on NetworkException', () async {
      final cachedGroup = Group(
        id: 'g-offline',
        name: 'Offline Group',
        role: 'ADMIN',
        memberCount: 3,
        createdAt: DateTime(2026, 1, 1),
      );

      // Populate cache
      await cacheService.setList('my_groups', [cachedGroup.toJson()]);

      final repo = GroupsRepository(ThrowingApiClient(), cacheService);
      final groups = await repo.getMyGroups();

      expect(groups.length, 1);
      expect(groups.first.id, 'g-offline');
      expect(groups.first.name, 'Offline Group');
    });

    test('GroupsRepository throws OfflineException if no cache available', () async {
      final repo = GroupsRepository(ThrowingApiClient(), cacheService);

      expect(
        () async => await repo.getMyGroups(),
        throwsA(isA<OfflineException>()),
      );
    });

    test('ResourcesRepository falls back to cached resources and rules on NetworkException', () async {
      final cachedResource = Resource(
        id: 'r-1',
        groupId: 'g-1',
        name: 'Washing Machine 1',
        capacity: 1,
        slotDurationMinutes: 60,
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      await cacheService.setList('group_resources_g-1', [
        cachedResource.toJson(),
      ]);

      final repo = ResourcesRepository(ThrowingApiClient(), cacheService);
      final resources = await repo.getResources('g-1');

      expect(resources.length, 1);
      expect(resources.first.name, 'Washing Machine 1');
    });

    test('BookingsRepository falls back to cached bookings on NetworkException', () async {
      final cachedBooking = Booking(
        id: 'b-1',
        resourceId: 'r-1',
        resourceName: 'Washing Machine 1',
        userId: 'u-1',
        groupId: 'g-1',
        startTime: DateTime(2026, 8, 12, 10, 0),
        endTime: DateTime(2026, 8, 12, 11, 0),
        status: 'CONFIRMED',
        createdAt: DateTime(2026, 8, 11),
      );

      await cacheService.setList('my_bookings_g-1', [
        cachedBooking.toJson(),
      ]);

      final repo = BookingsRepository(ThrowingApiClient(), cacheService);
      final bookings = await repo.getMyBookings('g-1');

      expect(bookings.length, 1);
      expect(bookings.first.id, 'b-1');
      expect(bookings.first.resourceName, 'Washing Machine 1');
    });
  });
}
