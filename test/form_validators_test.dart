import 'package:flutter_test/flutter_test.dart';

import 'package:cv_tech/core/utils/validators/form_validators.dart';

void main() {
  group('FormValidators', () {
    test('validateEmail returns required message for empty value', () {
      expect(FormValidators.validateEmail(''), 'L\'email est requis');
    });

    test('validateEmail returns format message for invalid email', () {
      expect(FormValidators.validateEmail('invalid-email'), 'Format d\'email invalide');
    });

    test('validateEmail returns null for valid email', () {
      expect(FormValidators.validateEmail('user@example.com'), isNull);
    });

    test('validatePassword enforces rules', () {
      expect(FormValidators.validatePassword(''), 'Le mot de passe est requis');
      expect(FormValidators.validatePassword('Ab1'), 'Minimum 6 caractères requis');
      expect(FormValidators.validatePassword('abcdef1'),
          'Doit contenir au moins une lettre majuscule');
      expect(FormValidators.validatePassword('ABCDEF1'),
          'Doit contenir au moins une lettre minuscule');
      expect(FormValidators.validatePassword('Abcdef'),
          'Doit contenir au moins un chiffre');
      expect(FormValidators.validatePassword('Abcdef1'), isNull);
    });

    test('validateConfirmPassword checks matching values', () {
      final validator = FormValidators.validateConfirmPassword('Abcdef1');
      expect(validator(''), 'La confirmation est requise');
      expect(validator('Abcdef2'), 'Les mots de passe ne correspondent pas');
      expect(validator('Abcdef1'), isNull);
    });

    test('validateOtp enforces 6 digits', () {
      expect(FormValidators.validateOtp(''), 'Le code OTP est requis');
      expect(FormValidators.validateOtp('123'),
          'Le code doit contenir 6 chiffres');
      expect(FormValidators.validateOtp('12345a'),
          'Le code doit contenir uniquement des chiffres');
      expect(FormValidators.validateOtp('123456'), isNull);
    });
  });
}
