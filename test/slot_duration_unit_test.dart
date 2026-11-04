import 'package:flutter_test/flutter_test.dart';
import 'package:lockmyslot_app/features/resources/data/models/slot_duration_unit.dart';

void main() {
  group('SlotDurationUnit Tests', () {
    test('parseMinutes parses common minutes correctly', () {
      final m30 = SlotDurationUnit.parseMinutes(30);
      expect(m30.unit, SlotDurationUnit.minutes);
      expect(m30.value, 30);

      final m45 = SlotDurationUnit.parseMinutes(45);
      expect(m45.unit, SlotDurationUnit.minutes);
      expect(m45.value, 45);

      final m60 = SlotDurationUnit.parseMinutes(60);
      expect(m60.unit, SlotDurationUnit.minutes);
      expect(m60.value, 60);

      final m120 = SlotDurationUnit.parseMinutes(120);
      expect(m120.unit, SlotDurationUnit.hours);
      expect(m120.value, 2);

      final m1440 = SlotDurationUnit.parseMinutes(1440);
      expect(m1440.unit, SlotDurationUnit.days);
      expect(m1440.value, 1);

      final m2880 = SlotDurationUnit.parseMinutes(2880);
      expect(m2880.unit, SlotDurationUnit.days);
      expect(m2880.value, 2);
    });

    test('toMinutes converts value and unit to total minutes', () {
      expect(SlotDurationUnit.toMinutes(30, SlotDurationUnit.minutes), 30);
      expect(SlotDurationUnit.toMinutes(2, SlotDurationUnit.hours), 120);
      expect(SlotDurationUnit.toMinutes(1, SlotDurationUnit.days), 1440);
      expect(SlotDurationUnit.toMinutes(3, SlotDurationUnit.days), 4320);
    });

    test('convertValue converts between units correctly', () {
      expect(
        SlotDurationUnit.convertValue(60, SlotDurationUnit.minutes, SlotDurationUnit.hours),
        1,
      );
      expect(
        SlotDurationUnit.convertValue(1, SlotDurationUnit.hours, SlotDurationUnit.minutes),
        60,
      );
      expect(
        SlotDurationUnit.convertValue(24, SlotDurationUnit.hours, SlotDurationUnit.days),
        1,
      );
      expect(
        SlotDurationUnit.convertValue(1, SlotDurationUnit.days, SlotDurationUnit.hours),
        24,
      );
      expect(
        SlotDurationUnit.convertValue(1, SlotDurationUnit.days, SlotDurationUnit.minutes),
        1440,
      );
    });

    test('validate validates constraints per unit', () {
      // Minutes validation
      expect(SlotDurationUnit.validate(null, SlotDurationUnit.minutes), 'Required');
      expect(SlotDurationUnit.validate('', SlotDurationUnit.minutes), 'Required');
      expect(SlotDurationUnit.validate('0', SlotDurationUnit.minutes), 'Must be > 0');
      expect(SlotDurationUnit.validate('10', SlotDurationUnit.minutes), '15 to 43200 mins');
      expect(SlotDurationUnit.validate('25', SlotDurationUnit.minutes), 'Multiple of 15');
      expect(SlotDurationUnit.validate('30', SlotDurationUnit.minutes), isNull);
      expect(SlotDurationUnit.validate('60', SlotDurationUnit.minutes), isNull);

      // Hours validation
      expect(SlotDurationUnit.validate('0', SlotDurationUnit.hours), 'Must be > 0');
      expect(SlotDurationUnit.validate('1', SlotDurationUnit.hours), isNull);
      expect(SlotDurationUnit.validate('24', SlotDurationUnit.hours), isNull);
      expect(SlotDurationUnit.validate('800', SlotDurationUnit.hours), '1 to 720 hours');

      // Days validation
      expect(SlotDurationUnit.validate('0', SlotDurationUnit.days), 'Must be > 0');
      expect(SlotDurationUnit.validate('1', SlotDurationUnit.days), isNull);
      expect(SlotDurationUnit.validate('7', SlotDurationUnit.days), isNull);
      expect(SlotDurationUnit.validate('31', SlotDurationUnit.days), '1 to 30 days');
    });
  });
}
