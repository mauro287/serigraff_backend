String? validateNewPassword(String? value, String username) {
  final password = value ?? '';
  if (password.length < 8) return 'Usa al menos 8 caracteres.';
  if (password.toLowerCase() == username.trim().toLowerCase()) {
    return 'La contraseña no puede ser igual al nombre de usuario.';
  }
  final letters = password.runes.map(String.fromCharCode).toList();
  if (!letters.any((c) => c.toUpperCase() == c && c.toLowerCase() != c)) {
    return 'Incluye al menos una letra mayúscula.';
  }
  if (!letters.any((c) => c.toLowerCase() == c && c.toUpperCase() != c)) {
    return 'Incluye al menos una letra minúscula.';
  }
  if (!RegExp(r'[^\p{L}\p{N}\s]', unicode: true).hasMatch(password)) {
    return 'Incluye un carácter especial, por ejemplo !, @ o #.';
  }
  return null;
}
