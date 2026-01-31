import 'package:flutter_test/flutter_test.dart';
import 'package:madina/register_validator.dart';

void main() {
  group('Functional Testing of Password Validation Module', () {


    test('FT-01: Password length less than 8 (5 chars)', () {
      final result =
          RegisterValidator.validatePassword('Abc12', 'Abc12');
      expect(result, isNotNull);
    });

    test('FT-02: Password length 7 characters', () {
      final result =
          RegisterValidator.validatePassword('Abc1234', 'Abc1234');
      expect(result, isNotNull);
    });

    test('FT-03: Password length exactly 8 characters', () {
      final result =
          RegisterValidator.validatePassword('Abc12345', 'Abc12345');
      expect(result, isNull);
    });

    test('FT-04: Password length 9 characters', () {
      final result =
          RegisterValidator.validatePassword('Abc123456', 'Abc123456');
      expect(result, isNull);
    });

    test('FT-05: Very long password (20 chars)', () {
      final result =
          RegisterValidator.validatePassword('Abc12345678901234567', 'Abc12345678901234567');
      expect(result, isNull);
    });

    test('FT-06: Empty password', () {
      final result =
          RegisterValidator.validatePassword('', '');
      expect(result, isNotNull);
    });


    test('FT-07: Password without uppercase letter', () {
      final result =
          RegisterValidator.validatePassword('abc12345', 'abc12345');
      expect(result, isNotNull);
    });

    test('FT-08: Uppercase letter at beginning', () {
      final result =
          RegisterValidator.validatePassword('Abc12345', 'Abc12345');
      expect(result, isNull);
    });

    test('FT-09: Uppercase letter in middle', () {
      final result =
          RegisterValidator.validatePassword('abcD1234', 'abcD1234');
      expect(result, isNull);
    });

    test('FT-10: Uppercase letter at end', () {
      final result =
          RegisterValidator.validatePassword('abc1234D', 'abc1234D');
      expect(result, isNull);
    });

    test('FT-11: Multiple uppercase letters', () {
      final result =
          RegisterValidator.validatePassword('ABc12345', 'ABc12345');
      expect(result, isNull);
    });

    test('FT-12: Only uppercase letters without number', () {
      final result =
          RegisterValidator.validatePassword('ABCDEFGH', 'ABCDEFGH');
      expect(result, isNotNull);
    });


    test('FT-13: Password without number', () {
      final result =
          RegisterValidator.validatePassword('Abcdefgh', 'Abcdefgh');
      expect(result, isNotNull);
    });

    test('FT-14: Password with one number', () {
      final result =
          RegisterValidator.validatePassword('Abcdefg1', 'Abcdefg1');
      expect(result, isNull);
    });

    test('FT-15: Number at beginning', () {
      final result =
          RegisterValidator.validatePassword('1Abcdefg', '1Abcdefg');
      expect(result, isNull);
    });

    test('FT-16: Number in middle', () {
      final result =
          RegisterValidator.validatePassword('Abc1defg', 'Abc1defg');
      expect(result, isNull);
    });

    test('FT-17: Number at end', () {
      final result =
          RegisterValidator.validatePassword('Abcdefg1', 'Abcdefg1');
      expect(result, isNull);
    });

    test('FT-18: Multiple numbers', () {
      final result =
          RegisterValidator.validatePassword('Abc12345', 'Abc12345');
      expect(result, isNull);
    });



    test('FT-19: Passwords do not match', () {
      final result =
          RegisterValidator.validatePassword('Abc12345', 'Abc1234');
      expect(result, isNotNull);
    });

    test('FT-20: Confirm password empty', () {
      final result =
          RegisterValidator.validatePassword('Abc12345', '');
      expect(result, isNotNull);
    });

    test('FT-21: Password empty, confirm filled', () {
      final result =
          RegisterValidator.validatePassword('', 'Abc12345');
      expect(result, isNotNull);
    });

    test('FT-22: Both passwords empty', () {
      final result =
          RegisterValidator.validatePassword('', '');
      expect(result, isNotNull);
    });

    test('FT-23: One character difference', () {
      final result =
          RegisterValidator.validatePassword('Abc12345', 'Abc12346');
      expect(result, isNotNull);
    });

    test('FT-24: Case-sensitive mismatch', () {
      final result =
          RegisterValidator.validatePassword('Abc12345', 'abc12345');
      expect(result, isNotNull);
    });


    test('FT-25: Valid password scenario 1', () {
      final result =
          RegisterValidator.validatePassword('Qwerty12', 'Qwerty12');
      expect(result, isNull);
    });

    test('FT-26: Valid password scenario 2', () {
      final result =
          RegisterValidator.validatePassword('Hello123', 'Hello123');
      expect(result, isNull);
    });

    test('FT-27: Valid password scenario 3', () {
      final result =
          RegisterValidator.validatePassword('Secure9A', 'Secure9A');
      expect(result, isNull);
    });

    test('FT-28: Valid password scenario 4', () {
      final result =
          RegisterValidator.validatePassword('Flutter8A', 'Flutter8A');
      expect(result, isNull);
    });

    test('FT-29: Valid password scenario 5', () {
      final result =
          RegisterValidator.validatePassword('TestPass1A', 'TestPass1A');
      expect(result, isNull);
    });

    test('FT-30: Strong valid password', () {
      final result =
          RegisterValidator.validatePassword('StrongPass9A', 'StrongPass9A');
      expect(result, isNull);
    });

  });
}
