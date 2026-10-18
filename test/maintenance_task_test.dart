import 'package:flutter_test/flutter_test.dart';
import 'package:lockmyslot_app/features/resources/data/models/maintenance_task.dart';

void main() {
  group('MaintenanceTask model test', () {
    test('should parse one-off maintenance task from JSON', () {
      final json = {
        'id': 'task-123',
        'resource_id': 'res-1',
        'resource_name': 'Conference Room A',
        'group_id': 'grp-1',
        'title': 'HVAC Filter Replacement',
        'description': 'Replace HEPA filters',
        'status': 'SCHEDULED',
        'recurrence_type': 'NONE',
        'start_time': '2026-10-25T10:00:00.000Z',
        'end_time': '2026-10-25T12:00:00.000Z',
        'created_by': 'usr-admin',
        'created_by_name': 'Admin User',
        'created_at': '2026-10-17T12:00:00.000Z',
      };

      final task = MaintenanceTask.fromJson(json);

      expect(task.id, 'task-123');
      expect(task.resourceId, 'res-1');
      expect(task.resourceName, 'Conference Room A');
      expect(task.title, 'HVAC Filter Replacement');
      expect(task.isScheduled, true);
      expect(task.isRecurring, false);
      expect(task.recurrenceSummary, 'One-off schedule');
      expect(task.startTime.isUtc, true);
    });

    test('should parse weekly recurring maintenance task from JSON', () {
      final json = {
        'id': 'task-weekly',
        'resource_id': 'res-1',
        'group_id': 'grp-1',
        'title': 'Weekly Deep Cleaning',
        'status': 'IN_PROGRESS',
        'recurrence_type': 'WEEKLY',
        'day_of_week': 1,
        'start_time_of_day': '08:00',
        'end_time_of_day': '10:00',
        'start_time': '2026-10-01T00:00:00.000Z',
        'end_time': '2026-12-31T23:59:59.000Z',
        'created_by': 'usr-admin',
        'created_at': '2026-10-17T12:00:00.000Z',
      };

      final task = MaintenanceTask.fromJson(json);

      expect(task.id, 'task-weekly');
      expect(task.isWeekly, true);
      expect(task.isRecurring, true);
      expect(task.isInProgress, true);
      expect(task.dayOfWeekName, 'Monday');
      expect(task.recurrenceSummary, 'Every Monday (08:00 - 10:00 UTC)');
    });

    test('should serialize to JSON correctly', () {
      final task = MaintenanceTask(
        id: 'task-1',
        resourceId: 'res-1',
        groupId: 'grp-1',
        title: 'Inspection',
        status: 'COMPLETED',
        recurrenceType: 'DAILY',
        startTimeOfDay: '07:00',
        endTimeOfDay: '08:00',
        startTime: DateTime.utc(2026, 10, 20, 7, 0),
        endTime: DateTime.utc(2026, 10, 30, 8, 0),
        createdById: 'usr-1',
        createdAt: DateTime.utc(2026, 10, 17, 10, 0),
      );

      final json = task.toJson();

      expect(json['id'], 'task-1');
      expect(json['status'], 'COMPLETED');
      expect(json['recurrence_type'], 'DAILY');
      expect(json['start_time_of_day'], '07:00');
      expect(json['end_time_of_day'], '08:00');
    });
  });
}
