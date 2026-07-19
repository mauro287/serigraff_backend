from django.db import models

# TODO (siguiente paso): completar el modelo Proveedor con todos sus campos
# (nombre_empresa, contacto, telefono, email, direccion, tipo_material, etc.)


class Proveedor(models.Model):
    nombre_empresa = models.CharField(max_length=150)

    class Meta:
        verbose_name = 'Proveedor'
        verbose_name_plural = 'Proveedores'

    def __str__(self):
        return self.nombre_empresa
