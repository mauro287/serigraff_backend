from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import RegistroAccion, SolicitudAcceso, Usuario


@admin.register(Usuario)
class UsuarioAdmin(UserAdmin):
    list_display = ('username', 'email', 'tipo_usuario', 'telefono', 'is_active')
    list_filter = ('tipo_usuario', 'is_active', 'is_staff')
    fieldsets = UserAdmin.fieldsets + (
        ('Datos SERIGRAFF', {'fields': ('tipo_usuario', 'telefono', 'cedula')}),
        ('Entrega', {'fields': ('lugar_entrega', 'referencia_entrega')}),
        ('Facturación', {'fields': ('razon_social', 'ruc', 'direccion_facturacion', 'correo_facturacion')}),
    )


@admin.register(SolicitudAcceso)
class SolicitudAccesoAdmin(admin.ModelAdmin):
    list_display = ('id', 'usuario', 'estado', 'fecha_solicitud', 'revisado_por')
    list_filter = ('estado',)
    search_fields = ('usuario__username', 'usuario__email')
    readonly_fields = ('fecha_solicitud', 'fecha_revision')


@admin.register(RegistroAccion)
class RegistroAccionAdmin(admin.ModelAdmin):
    list_display = ('fecha', 'usuario', 'accion', 'entidad', 'entidad_id')
    list_filter = ('accion', 'entidad')
    search_fields = ('usuario__username', 'detalle')
    readonly_fields = ('usuario', 'accion', 'entidad', 'entidad_id', 'detalle', 'fecha')
