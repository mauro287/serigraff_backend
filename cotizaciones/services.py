from datetime import timedelta

from django.db import transaction
from django.utils import timezone
from rest_framework.exceptions import ValidationError

from .agenda import bloquear_agenda
from .models import Cotizacion
from usuarios.auditoria import registrar_accion
from usuarios.notificaciones import avisar


@transaction.atomic
def enviar_precio_al_cliente(cotizacion_id, usuario):
    """Shared by the authenticated API and permission-checked Django admin."""
    bloquear_agenda()
    cotizacion = Cotizacion.objects.get(pk=cotizacion_id)
    if cotizacion.estado != Cotizacion.Estado.PENDIENTE:
        raise ValidationError('Solo se pueden enviar cotizaciones pendientes.')
    if cotizacion.total_estimado is None or cotizacion.total_estimado <= 0:
        raise ValidationError('Registra un precio total mayor que cero antes de enviar.')
    cotizacion.valida_hasta = cotizacion.valida_hasta or timezone.localdate() + timedelta(days=15)
    if cotizacion.valida_hasta < timezone.localdate():
        raise ValidationError('La fecha de vigencia no puede estar vencida.')
    cotizacion.estado = Cotizacion.Estado.PENDIENTE_APROBACION
    cotizacion.save(update_fields=['estado', 'valida_hasta'])
    avisar(cotizacion.usuario, f'Cotización #{cotizacion.pk} lista para aprobar.', cotizacion=cotizacion)
    registrar_accion(usuario=usuario, accion='COTIZACION_ENVIADA_APROBACION', entidad='Cotizacion', entidad_id=cotizacion.pk)
    return cotizacion
