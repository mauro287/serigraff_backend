from rest_framework.test import APITestCase
from .models import Usuario, Notificacion
from cotizaciones.models import Cotizacion
from pedidos.models import Pedido, DisenoPedido


class MobileAdminTests(APITestCase):
    def setUp(self):
        self.customer = Usuario.objects.create_user(username='cliente_admin_test')
        self.operator = Usuario.objects.create_user(username='operador_test', tipo_usuario='PERSONAL_OPERATIVO')
        self.admin = Usuario.objects.create_user(username='administrador_test', tipo_usuario='ADMINISTRADOR')
        self.root = Usuario.objects.create_user(username='super_test', is_superuser=True)
        self.quote = Cotizacion.objects.create(usuario=self.customer, descripcion='Producto personalizado', cantidad=3)
        self.order = Pedido.objects.create(usuario=self.customer, estado='APROBADO')

    def test_admin_routes_reject_customers_operators_and_anonymous(self):
        for user, code in [(None, 401), (self.customer, 403), (self.operator, 403)]:
            self.client.force_authenticate(user)
            for path in ['cotizaciones/', 'pedidos/', f'cotizaciones/{self.quote.pk}/', f'pedidos/{self.order.pk}/', f'cotizaciones/{self.quote.pk}/archivos/1/']:
                self.assertEqual(self.client.get('/api/administracion/' + path).status_code, code)
            self.assertEqual(self.client.patch(f'/api/administracion/cotizaciones/{self.quote.pk}/', {'total_estimado': '25.00'}).status_code, code)
            self.assertEqual(self.client.post(f'/api/administracion/cotizaciones/{self.quote.pk}/enviar_para_aprobacion/').status_code, code)
            self.assertEqual(self.client.post(f'/api/administracion/pedidos/{self.order.pk}/cambiar_estado/', {'estado': 'EN_DISENO'}).status_code, code)

    def test_server_role_is_readonly_and_includes_superuser(self):
        for user, expected in [(self.customer, False), (self.operator, False), (self.admin, True), (self.root, True)]:
            self.client.force_authenticate(user)
            self.assertEqual(self.client.get('/api/perfil/').data['es_administrador'], expected)
            response = self.client.patch('/api/perfil/', {'es_administrador': not expected}, format='json')
            self.assertEqual(response.data['es_administrador'], expected)

    def test_admin_price_notice_and_customer_approval(self):
        self.client.force_authenticate(self.admin)
        url = f'/api/administracion/cotizaciones/{self.quote.pk}/'
        self.assertEqual(self.client.patch(url, {'total_estimado': '-2'}).status_code, 400)
        self.assertEqual(self.client.patch(url, {'total_estimado': '25.50'}).status_code, 200)
        self.assertEqual(self.client.post(url + 'enviar_para_aprobacion/').status_code, 200)
        self.assertEqual(Notificacion.objects.filter(cotizacion=self.quote, usuario=self.customer).count(), 1)
        self.assertEqual(self.client.post(f'/api/cotizaciones/{self.quote.pk}/aprobar/').status_code, 403)
        self.client.force_authenticate(self.customer)
        self.assertEqual(self.client.post(f'/api/cotizaciones/{self.quote.pk}/aprobar/').status_code, 200)

    def test_order_transition_requires_approved_design(self):
        self.client.force_authenticate(self.admin)
        path = f'/api/administracion/pedidos/{self.order.pk}/cambiar_estado/'
        self.assertEqual(self.client.post(path, {'estado': 'EN_PRODUCCION'}).status_code, 400)
        self.assertEqual(self.client.post(path, {'estado': 'EN_DISENO'}).status_code, 200)
        self.assertEqual(self.client.post(path, {'estado': 'EN_PRODUCCION'}).status_code, 400)
        DisenoPedido.objects.create(pedido=self.order, version=1, imagen='prueba.png', estado='APROBADO')
        for state in ['EN_PRODUCCION', 'LISTO_ENTREGA', 'ENTREGADO']:
            self.assertEqual(self.client.post(path, {'estado': state}).status_code, 200)
        self.order.refresh_from_db()
        self.assertEqual(self.order.estado, 'ENTREGADO')
