from django import forms
from django.contrib import admin, messages
from django.utils import timezone
from rest_framework.exceptions import ValidationError
from .models import ArchivoCotizacion, Cotizacion
from .services import enviar_precio_al_cliente


class CotizacionPrecioForm(forms.ModelForm):
    class Meta:
        model = Cotizacion
        fields = '__all__'
        labels = {'total_estimado': 'Precio total para el cliente (USD)'}
        help_texts = {'total_estimado': 'Importe total del trabajo, no precio por unidad. Guarda y usa la acción de envío en el listado.'}

    def clean_total_estimado(self):
        value = self.cleaned_data.get('total_estimado')
        if value is not None and value <= 0:
            raise forms.ValidationError('El precio total debe ser mayor que cero.')
        return value

    def clean_valida_hasta(self):
        value = self.cleaned_data.get('valida_hasta')
        if value and value < timezone.localdate():
            raise forms.ValidationError('Selecciona una fecha vigente o deja el campo vacío.')
        return value


class ArchivoCotizacionInline(admin.TabularInline):
    model = ArchivoCotizacion
    fields = ('archivo', 'fecha_carga')
    readonly_fields = fields
    extra = 0
    can_delete = False

    def has_add_permission(self, request, obj=None):
        return False


@admin.register(Cotizacion)
class CotizacionAdmin(admin.ModelAdmin):
    form = CotizacionPrecioForm
    list_display = ('id', 'usuario', 'trabajo_solicitado', 'referencia_catalogo', 'cantidad', 'estado', 'total_estimado', 'fecha_solicitud')
    list_display_links = ('id', 'trabajo_solicitado')
    list_filter = ('estado', 'es_urgente')
    search_fields = ('usuario__username', 'descripcion', 'producto__nombre')
    list_select_related = ('usuario', 'producto')
    inlines = [ArchivoCotizacionInline]
    actions = ['enviar_precio']
    fieldsets = (
        ('Solicitud del cliente', {'fields': ('usuario', 'descripcion', 'producto', 'cantidad', 'ancho_cm', 'alto_cm', 'archivo_diseno')}),
        ('Entrega', {'fields': ('fecha_entrega_deseada', 'fecha_entrega_programada', 'es_urgente', 'motivo_urgencia')}),
        ('Precio y condiciones para el cliente', {'fields': ('total_estimado', 'condiciones', 'valida_hasta'),
            'description': 'Guarda el precio. Después selecciona esta cotización en el listado y ejecuta «Enviar precio al cliente para aprobación».'}),
        ('Seguimiento', {'fields': ('estado', 'pedido_generado', 'fecha_solicitud', 'observaciones_internas')}),
    )

    def get_readonly_fields(self, request, obj=None):
        fields = ['usuario', 'descripcion', 'producto', 'cantidad', 'ancho_cm', 'alto_cm', 'archivo_diseno',
                  'fecha_entrega_deseada', 'fecha_entrega_programada', 'es_urgente', 'motivo_urgencia',
                  'estado', 'pedido_generado', 'fecha_solicitud']
        if obj and obj.estado != Cotizacion.Estado.PENDIENTE:
            fields += ['total_estimado', 'condiciones', 'valida_hasta']
        return fields

    @admin.display(description='Trabajo solicitado')
    def trabajo_solicitado(self, obj):
        return obj.descripcion or 'Sin descripción registrada'

    @admin.display(description='Referencia de catálogo')
    def referencia_catalogo(self, obj):
        return obj.producto.nombre if obj.producto_id else 'Personalizado / sin producto de catálogo'

    def has_add_permission(self, request):
        return False

    def has_delete_permission(self, request, obj=None):
        return False

    def has_enviar_permission(self, request):
        return self.has_change_permission(request) and request.user.es_personal_interno

    @admin.action(description='Enviar precio al cliente para aprobación', permissions=['enviar'])
    def enviar_precio(self, request, queryset):
        if not self.has_enviar_permission(request):
            from django.core.exceptions import PermissionDenied
            raise PermissionDenied
        for cotizacion in queryset:
            try:
                enviar_precio_al_cliente(cotizacion.pk, request.user)
            except ValidationError as exc:
                self.message_user(request, f'Cotización #{cotizacion.pk}: {exc.detail}', level=messages.ERROR)
            else:
                self.message_user(request, f'Cotización #{cotizacion.pk}: precio enviado y aviso creado para el cliente.', level=messages.SUCCESS)


@admin.register(ArchivoCotizacion)
class ArchivoCotizacionAdmin(admin.ModelAdmin):
    list_display = ('id', 'cotizacion', 'archivo', 'fecha_carga')
