from rest_framework.permissions import BasePermission


class EsAdministrador(BasePermission):
    def has_permission(self, request, view):
        usuario = request.user
        return bool(
            usuario
            and usuario.is_authenticated
            and (usuario.is_superuser or usuario.tipo_usuario == usuario.TipoUsuario.ADMINISTRADOR)
        )


class EsPersonalInterno(BasePermission):
    def has_permission(self, request, view):
        usuario = request.user
        return bool(usuario and usuario.is_authenticated and usuario.es_personal_interno)


class EsPersonalInternoOLectura(BasePermission):
    def has_permission(self, request, view):
        if request.method in ("GET", "HEAD", "OPTIONS"):
            return True
        return EsPersonalInterno().has_permission(request, view)


class EsPropietarioOPersonal(BasePermission):
    def has_permission(self, request, view):
        return bool(request.user and request.user.is_authenticated)

    def has_object_permission(self, request, view, obj):
        if request.user.es_personal_interno:
            return True
        propietario = getattr(obj, "usuario", None)
        if propietario is None and hasattr(obj, "pedido"):
            propietario = obj.pedido.usuario
        return propietario == request.user
