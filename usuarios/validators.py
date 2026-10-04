from django.core.exceptions import ValidationError


class PasswordComplexityValidator:
    def validate(self, password, user=None):
        errors = []
        if not any(c.isupper() for c in password):
            errors.append('Incluye al menos una letra mayúscula.')
        if not any(c.islower() for c in password):
            errors.append('Incluye al menos una letra minúscula.')
        if not any(not c.isalnum() and not c.isspace() for c in password):
            errors.append('Incluye al menos un carácter especial, por ejemplo !, @ o #.')
        if user and user.username and password.casefold() == user.username.strip().casefold():
            errors.append('La contraseña no puede ser igual al nombre de usuario.')
        if errors:
            raise ValidationError(errors)

    def get_help_text(self):
        return ('Incluye una mayúscula, una minúscula y un carácter especial. '
                'No uses tu nombre de usuario como contraseña.')
