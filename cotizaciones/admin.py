from django.contrib import admin
from .models import Cotizacion


@admin.register(Cotizacion)
class CotizacionAdmin(admin.ModelAdmin):
    list_display = ('id', 'usuario', 'estado', 'fecha_solicitud')
    list_filter = ('estado',)
