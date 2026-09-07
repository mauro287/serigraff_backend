from .models import RegistroAccion


def registrar_accion(*, usuario, accion, entidad, entidad_id=None, detalle=''):
    """Guarda metadatos de auditoría; nunca contraseñas ni datos de facturación."""
    return RegistroAccion.objects.create(
        usuario=usuario if getattr(usuario, 'is_authenticated', False) else None,
        accion=accion,
        entidad=entidad,
        entidad_id=entidad_id,
        detalle=detalle,
    )
