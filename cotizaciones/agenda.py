from datetime import timedelta

from django.conf import settings
from django.db.models import F
from rest_framework.exceptions import ValidationError
from django.utils import timezone

from .models import ControlAgenda, Cotizacion


def bloquear_agenda():
    # Dentro de atomic: UPDATE serializa reservas también en SQLite.
    ControlAgenda.objects.get_or_create(pk=1)
    ControlAgenda.objects.filter(pk=1).update(revision=F('revision') + 1)


def trabajos_activos():
    return Cotizacion.objects.exclude(estado=Cotizacion.Estado.RECHAZADA).exclude(
        pedido_generado__estado__in=['ENTREGADO', 'COMPLETADO', 'CANCELADO'])


def proxima_fecha_disponible(*, urgente, fecha_deseada=None, excluir=None):
    """Busca una fecha con cupo, sin contar cotizaciones rechazadas."""
    fecha = max(timezone.localdate(), fecha_deseada or timezone.localdate())
    cupo = settings.CUPO_URGENTE_DIARIO if urgente else settings.CUPO_COTIZACIONES_DIARIO
    if cupo <= 0:
        raise ValidationError('No hay cupos habilitados para este tipo de solicitud.')
    for _ in range(730):
        ocupados = trabajos_activos().exclude(pk=excluir).filter(fecha_entrega_programada=fecha, es_urgente=urgente).count()
        if ocupados < cupo:
            return fecha
        fecha += timedelta(days=1)
    raise ValidationError('No hay cupos disponibles en los próximos dos años.')
