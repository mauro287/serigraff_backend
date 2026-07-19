from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import Usuario


@admin.register(Usuario)
class UsuarioAdmin(UserAdmin):
    list_display = ('username', 'email', 'tipo_usuario', 'telefono', 'is_active')
    list_filter = ('tipo_usuario', 'is_active', 'is_staff')
    fieldsets = UserAdmin.fieldsets + (
        ('Datos SERIGRAFF', {'fields': ('tipo_usuario', 'telefono', 'direccion')}),
    )
