from django.apps import AppConfig


class CotizacionesConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'cotizaciones'
    verbose_name = 'Cotizaciones'

    def ready(self):
        # Aquí conectaremos la señal que convierte una Cotización aprobada
        # en un Pedido automáticamente (siguiente paso).
        import cotizaciones.signals  # noqa: F401
