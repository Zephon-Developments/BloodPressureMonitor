import 'package:blood_pressure_monitor/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateMedicationName', () {
    test('accepts valid medication name', () {
      final result = validateMedicationName('Aspirin');
      expect(result.level, ValidationLevel.valid);
    });

    test('rejects empty name', () {
      final result = validateMedicationName('');
      expect(result.level, ValidationLevel.error);
      expect(result.message, contains('required'));
    });

    test('rejects whitespace-only name', () {
      final result = validateMedicationName('   ');
      expect(result.level, ValidationLevel.error);
      expect(result.message, contains('required'));
    });

    test('rejects name exceeding 120 characters', () {
      final longName = 'A' * 121;
      final result = validateMedicationName(longName);
      expect(result.level, ValidationLevel.error);
      expect(result.message, contains('120 characters'));
    });

    test('accepts name at 120 character limit', () {
      final maxName = 'A' * 120;
      final result = validateMedicationName(maxName);
      expect(result.level, ValidationLevel.valid);
    });
  });

  group('validateMedicationDosage', () {
    test('accepts null dosage', () {
      final result = validateMedicationDosage(null);
      expect(result.level, ValidationLevel.valid);
    });

    test('accepts empty dosage', () {
      final result = validateMedicationDosage('');
      expect(result.level, ValidationLevel.valid);
    });

    test('accepts valid dosage', () {
      final result = validateMedicationDosage('100mg');
      expect(result.level, ValidationLevel.valid);
    });

    test('rejects dosage exceeding 120 characters', () {
      final longDosage = 'A' * 121;
      final result = validateMedicationDosage(longDosage);
      expect(result.level, ValidationLevel.error);
      expect(result.message, contains('120 characters'));
    });

    test('accepts dosage at 120 character limit', () {
      final maxDosage = 'A' * 120;
      final result = validateMedicationDosage(maxDosage);
      expect(result.level, ValidationLevel.valid);
    });
  });

  group('validateMedicationUnit', () {
    test('accepts null unit', () {
      final result = validateMedicationUnit(null);
      expect(result.level, ValidationLevel.valid);
    });

    test('accepts empty unit', () {
      final result = validateMedicationUnit('');
      expect(result.level, ValidationLevel.valid);
    });

    test('accepts valid unit', () {
      final result = validateMedicationUnit('mg');
      expect(result.level, ValidationLevel.valid);
    });

    test('rejects unit exceeding 50 characters', () {
      final longUnit = 'A' * 51;
      final result = validateMedicationUnit(longUnit);
      expect(result.level, ValidationLevel.error);
      expect(result.message, contains('50 characters'));
    });

    test('accepts unit at 50 character limit', () {
      final maxUnit = 'A' * 50;
      final result = validateMedicationUnit(maxUnit);
      expect(result.level, ValidationLevel.valid);
    });
  });

  group('validateMedicationFrequency', () {
    test('accepts null frequency', () {
      final result = validateMedicationFrequency(null);
      expect(result.level, ValidationLevel.valid);
    });

    test('accepts empty frequency', () {
      final result = validateMedicationFrequency('');
      expect(result.level, ValidationLevel.valid);
    });

    test('accepts valid frequency', () {
      final result = validateMedicationFrequency('twice daily');
      expect(result.level, ValidationLevel.valid);
    });

    test('rejects frequency exceeding 120 characters', () {
      final longFrequency = 'A' * 121;
      final result = validateMedicationFrequency(longFrequency);
      expect(result.level, ValidationLevel.error);
      expect(result.message, contains('120 characters'));
    });

    test('accepts frequency at 120 character limit', () {
      final maxFrequency = 'A' * 120;
      final result = validateMedicationFrequency(maxFrequency);
      expect(result.level, ValidationLevel.valid);
    });
  });

  group('validateGroupName', () {
    test('accepts valid group name', () {
      final result = validateGroupName('Morning Meds');
      expect(result.level, ValidationLevel.valid);
    });

    test('rejects empty group name', () {
      final result = validateGroupName('');
      expect(result.level, ValidationLevel.error);
      expect(result.message, contains('required'));
    });

    test('rejects whitespace-only group name', () {
      final result = validateGroupName('   ');
      expect(result.level, ValidationLevel.error);
      expect(result.message, contains('required'));
    });

    test('rejects group name exceeding 120 characters', () {
      final longName = 'A' * 121;
      final result = validateGroupName(longName);
      expect(result.level, ValidationLevel.error);
      expect(result.message, contains('120 characters'));
    });

    test('accepts group name at 120 character limit', () {
      final maxName = 'A' * 120;
      final result = validateGroupName(maxName);
      expect(result.level, ValidationLevel.valid);
    });
  });
}
