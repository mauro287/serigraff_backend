from rest_framework import status
from rest_framework.test import APITestCase
from datetime import timedelta

from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import override_settings
from django.utils import timezone

from productos.models import Categoria, Producto
from usuarios.models import Usuario
from usuarios.models import RegistroAccion

from .models import Cotizacion
from pedidos.models import Pedido


class CotizacionAPITests(APITestCase):
    def setUp(self):
        self.cliente = Usuario.objects.create_user(username='cliente', password='clave-segura-123')
        categoria = Categoria.objects.create(nombre='Impresión')
        self.producto = Producto.objects.create(nombre='Banner', categoria=categoria)

    def test_cliente_crea_cotizacion_con_detalles(self):
        self.client.force_authenticate(self.cliente)

        response = self.client.post(
            '/api/cotizaciones/',
            {
                'producto': self.producto.id,
                'descripcion': 'Banner publicitario para feria.',
                'cantidad': 2,
                'ancho_cm': '80.00',
                'alto_cm': '120.00',
                'fecha_entrega_deseada': '2026-09-10',
            },
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        cotizacion = Cotizacion.objects.get()
        self.assertEqual(cotizacion.usuario, self.cliente)
        self.assertEqual(cotizacion.producto, self.producto)
        self.assertEqual(cotizacion.cantidad, 2)
        self.assertEqual(cotizacion.descripcion, 'Banner publicitario para feria.')
        self.assertIsNone(cotizacion.total_estimado)
        self.assertTrue(
            RegistroAccion.objects.filter(accion='COTIZACION_CREADA', entidad_id=cotizacion.id).exists()
        )

    def test_cliente_no_puede_fijar_precio_ni_estado(self):
        self.client.force_authenticate(self.cliente)

        response = self.client.post(
            '/api/cotizaciones/',
            {
                'descripcion': 'Tarjetas de presentación.',
                'total_estimado': '20.00',
                'estado': Cotizacion.Estado.APROBADA,
                'observaciones_internas': 'No debe ser visible.',
            },
            format='json',
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        cotizacion = Cotizacion.objects.get()
        self.assertEqual(cotizacion.estado, Cotizacion.Estado.PENDIENTE)
        self.assertIsNone(cotizacion.total_estimado)
        self.assertEqual(cotizacion.observaciones_internas, '')

    def test_cliente_aprueba_cotizacion_y_se_crea_pedido_para_produccion(self):
        personal = Usuario.objects.create_user(
            username='ventas',
            password='clave-segura-123',
            tipo_usuario=Usuario.TipoUsuario.PERSONAL_OPERATIVO,
        )
        cotizacion = Cotizacion.objects.create(
            usuario=self.cliente,
            producto=self.producto,
            descripcion='Banner para aprobación.',
            cantidad=3,
            total_estimado='75.00',
        )

        self.client.force_authenticate(personal)
        enviar = self.client.post(
            f'/api/cotizaciones/{cotizacion.id}/enviar_para_aprobacion/', format='json'
        )
        self.assertEqual(enviar.status_code, status.HTTP_200_OK)

        self.client.force_authenticate(self.cliente)
        aprobar = self.client.post(f'/api/cotizaciones/{cotizacion.id}/aprobar/', format='json')

        self.assertEqual(aprobar.status_code, status.HTTP_200_OK)
        cotizacion.refresh_from_db()
        self.assertEqual(cotizacion.estado, Cotizacion.Estado.APROBADA)
        self.assertIsNotNone(cotizacion.pedido_generado)
        self.assertEqual(cotizacion.pedido_generado.estado, Pedido.Estado.APROBADO)
        self.client.force_authenticate(personal)
        pedido_id = cotizacion.pedido_generado_id
        self.assertEqual(self.client.post(f'/api/pedidos/{pedido_id}/cambiar_estado/', {'estado': 'EN_DISENO'}).status_code, 200)
        self.assertEqual(self.client.post(f'/api/pedidos/{pedido_id}/cambiar_estado/', {'estado': 'EN_PRODUCCION'}).status_code, 400)
        self.assertEqual(cotizacion.pedido_generado.detalles.get().cantidad, 3)
        self.assertTrue(
            RegistroAccion.objects.filter(accion='PEDIDO_GENERADO_PARA_PRODUCCION', entidad_id=cotizacion.pedido_generado.id).exists()
        )

    def test_no_se_puede_aprobar_una_cotizacion_sin_revision_del_personal(self):
        cotizacion = Cotizacion.objects.create(
            usuario=self.cliente,
            descripcion='Pendiente de precio.',
        )
        self.client.force_authenticate(self.cliente)

        response = self.client.post(f'/api/cotizaciones/{cotizacion.id}/aprobar/', format='json')

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_cliente_adjunta_varios_logos_e_imagenes_a_cotizacion_pendiente(self):
        cotizacion = Cotizacion.objects.create(usuario=self.cliente, descripcion='Diseño con logo.')
        self.client.force_authenticate(self.cliente)
        logo = SimpleUploadedFile('logo.png', b'logo', content_type='image/png')
        imagen = SimpleUploadedFile('referencia.jpg', b'imagen', content_type='image/jpeg')

        response = self.client.post(
            f'/api/cotizaciones/{cotizacion.id}/archivos/',
            {'archivos': [logo, imagen]},
            format='multipart',
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(cotizacion.archivos.count(), 2)

    @override_settings(CUPO_COTIZACIONES_DIARIO=2, CUPO_URGENTE_DIARIO=1)
    def test_agenda_mueve_cotizaciones_al_siguiente_dia_cuando_se_llena_el_cupo(self):
        self.client.force_authenticate(self.cliente)
        for numero in range(3):
            response = self.client.post(
                '/api/cotizaciones/', {'descripcion': f'Trabajo {numero + 1}.'}, format='json'
            )
            self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        fechas = list(Cotizacion.objects.order_by('id').values_list('fecha_entrega_programada', flat=True))
        self.assertEqual(fechas[:2], [timezone.localdate(), timezone.localdate()])
        self.assertEqual(fechas[2], timezone.localdate() + timedelta(days=1))

    @override_settings(CUPO_COTIZACIONES_DIARIO=1, CUPO_URGENTE_DIARIO=1)
    def test_urgencia_tiene_cupo_reservado_y_muestra_fecha_programada(self):
        self.client.force_authenticate(self.cliente)
        self.client.post('/api/cotizaciones/', {'descripcion': 'Normal.'}, format='json')
        urgente = self.client.post(
            '/api/cotizaciones/',
            {'descripcion': 'Urgente.', 'es_urgente': True, 'motivo_urgencia': 'Evento mañana.'},
            format='json',
        )

        self.assertEqual(urgente.status_code, status.HTTP_201_CREATED)
        self.assertTrue(urgente.data['es_urgente'])
        self.assertEqual(urgente.data['fecha_entrega_programada'], timezone.localdate().isoformat())
