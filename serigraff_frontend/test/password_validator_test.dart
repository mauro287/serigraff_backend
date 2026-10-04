import 'package:flutter_test/flutter_test.dart';

import 'package:serigraff_frontend/features/auth/presentation/password_validator.dart';

void main() {
  test('rechaza contraseñas que incumplen cada requisito', () {
    for (final password in [
      null,
      'Aa!',
      'sinmayuscula!',
      'SINMINUSCULA!',
      'SinEspecial123',
      'Mayuscula ',
      'Usuario!',
    ]) {
      expect(validateNewPassword(password, 'Usuario!'), isNotNull);
    }
  });
  test('acepta mayúscula, minúscula y símbolo sin exigir números', () {
    expect(validateNewPassword('Bosque!Azul', 'cliente'), isNull);
    expect(validateNewPassword('Árbol!Verde', 'cliente'), isNull);
  });
}
