import 'package:flutter_test/flutter_test.dart';
import 'package:gul_alem/register_validator.dart';

void main() {
  group('Register password validation', () {
    test('password too short', () {
      final result = RegisterValidator.validatePassword('Ab1', 'Ab1');
      expect(result, isNotNull);
    });

    test('no special character', () {
      final result = RegisterValidator.validatePassword(
        'password1',
        'password1',
      );
      expect(result, isNotNull);
    });

    test('no number', () {
      final result = RegisterValidator.validatePassword('Password', 'Password');
      expect(result, isNotNull);
    });

    test('passwords not equal', () {
      final result = RegisterValidator.validatePassword(
        'Password1',
        'Password2',
      );
      expect(result, isNotNull);
    });

    test('valid password', () {
      final result = RegisterValidator.validatePassword(
        'Password1!',
        'Password1!',
      );
      expect(result, isNull);
    });
  });

  group('Register profile validation', () {
    test('validates full name', () {
      expect(RegisterValidator.isValidFullName('A'), isFalse);
      expect(RegisterValidator.isValidFullName('John  Doe'), isTrue);
      expect(RegisterValidator.isValidFullName('John123'), isFalse);
    });

    test('normalizes and validates phone', () {
      expect(
        RegisterValidator.normalizePhone('+7 (777) 123-45-67'),
        '77771234567',
      );
      expect(RegisterValidator.isValidPhone('77771234567'), isTrue);
      expect(RegisterValidator.isValidPhone('123'), isFalse);
    });

    test('validates email', () {
      expect(RegisterValidator.isValidEmail('user@example.com'), isTrue);
      expect(RegisterValidator.isValidEmail('bad-email'), isFalse);
      expect(RegisterValidator.isValidEmail('user@example'), isFalse);
    });
  });
}
