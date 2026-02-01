import 'package:flutter_test/flutter_test.dart';
import 'package:madina/register_validator.dart';

void main() {
  group('Register password validation', () {
    test('password too short', () {
      final result = RegisterValidator.validatePassword('Ab1', 'Ab1');
      expect(result, isNotNull);
    });

    test('no capital letter', () {
      final result =
          RegisterValidator.validatePassword('password1', 'password1');
      expect(result, isNotNull);
    });

    test('no number', () {
      final result =
          RegisterValidator.validatePassword('Password', 'Password');
      expect(result, isNotNull);
    });

    test('passwords not equal', () {
      final result =
          RegisterValidator.validatePassword('Password1', 'Password2');
      expect(result, isNotNull);
    });

    test('valid password', () {
      final result =
          RegisterValidator.validatePassword('Password1', 'Password1');
      expect(result, isNull);
    });
  });
}
