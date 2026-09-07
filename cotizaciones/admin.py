from django.contrib import admin
from .models import ArchivoCotizacion, Cotizacion


@admin.register(Cotizacion)
class CotizacionAdmin(admin.ModelAdmin):
    list_display = ('id', 'usuario', 'producto', 'cantidad', 'estado', 'total_estimado', 'fecha_solicitud')
    list_filter = ('estado',)
    search_fields = ('usuario__username', 'descripcion')


@admin.register(ArchivoCotizacion)
class ArchivoCotizacionAdmin(admin.ModelAdmin):
    list_display = ('id', 'cotizacion', 'archivo', 'fecha_carga')
