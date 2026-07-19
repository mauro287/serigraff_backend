from django.db import models

# TODO (siguiente paso): completar Categoria y Producto con todos sus campos
# y las FK a proveedores.Proveedor.


class Categoria(models.Model):
    nombre = models.CharField(max_length=100)

    class Meta:
        verbose_name = 'Categoría'
        verbose_name_plural = 'Categorías'

    def __str__(self):
        return self.nombre


class Producto(models.Model):
    nombre = models.CharField(max_length=150)
    categoria = models.ForeignKey(Categoria, on_delete=models.PROTECT, related_name='productos')

    class Meta:
        verbose_name = 'Producto'
        verbose_name_plural = 'Productos'

    def __str__(self):
        return self.nombre
