# SERIGRAFF — Backend

Backend de la aplicación móvil de SERIGRAFF (empresa de marketing: diseño
gráfico, impresión publicitaria, corte láser y material promocional).

## Stack

- **Backend/lógica:** Python + Django
- **API:** Django REST Framework (DRF)
- **Base de datos:** SQLite (gestionada con DB Browser for SQLite)
- **Control de versiones:** Git / GitHub
- **Entorno de desarrollo:** Visual Studio Code

## Estructura del proyecto

```
serigraff_backend/
├── manage.py
├── requirements.txt
├── .gitignore
├── serigraff_backend/      # Configuración global (settings, urls, wsgi)
├── usuarios/               # Usuario personalizado (cliente / admin / personal)
├── proveedores/            # Proveedores de materiales y tecnología
├── productos/              # Categoría y Producto (catálogo)
├── cotizaciones/           # Solicitudes de cotización de clientes
└── pedidos/                # Pedido, DetallePedido y Venta
```

Cada app sigue la misma organización interna:
`models.py`, `admin.py`, `urls.py` (y próximamente `serializers.py` / `views.py`).

## Entidades del sistema

| Entidad | App | Relación principal |
|---|---|---|
| Usuario | `usuarios` | 1—N con Pedido, Cotización y Venta |
| Proveedor | `proveedores` | 1—N con Producto |
| Categoría | `productos` | 1—N con Producto |
| Producto | `productos` | N—1 con Categoría y Proveedor |
| Cotización | `cotizaciones` | N—1 con Usuario |
| Pedido | `pedidos` | N—1 con Usuario, 1—N con DetallePedido |
| DetallePedido | `pedidos` | N—1 con Pedido y Producto |
| Venta | `pedidos` | 1—1 con Pedido |

## Instalación local

1. Clonar el repositorio:
   ```bash
   git clone <url-del-repo>
   cd serigraff_backend
   ```

2. Crear y activar un entorno virtual:
   ```bash
   python -m venv venv
   # Windows
   venv\Scripts\activate
   # macOS/Linux
   source venv/bin/activate
   ```

3. Instalar dependencias:
   ```bash
   pip install -r requirements.txt
   ```

4. Aplicar migraciones (crea `db.sqlite3`):
   ```bash
   python manage.py makemigrations
   python manage.py migrate
   ```

5. Crear un superusuario para acceder al panel de administración:
   ```bash
   python manage.py createsuperuser
   ```

6. Levantar el servidor de desarrollo:
   ```bash
   python manage.py runserver
   ```

7. Abrir el panel admin en `http://127.0.0.1:8000/admin/`
   y la API en `http://127.0.0.1:8000/api/`.

## Gestión de la base de datos

El archivo `db.sqlite3` se genera al correr las migraciones. Puedes abrirlo
con **DB Browser for SQLite** para inspeccionar tablas, ejecutar consultas
SQL manuales o verificar datos durante el desarrollo. No se versiona en Git
(ver `.gitignore`) porque cada desarrollador debe generar la suya localmente.

## Flujo de Git sugerido

```bash
git init
git add .
git commit -m "Estructura inicial del proyecto SERIGRAFF"
git branch -M main
git remote add origin <url-de-tu-repo-en-github>
git push -u origin main
```

Ramas sugeridas: `main` (estable), `develop` (integración) y
`feature/<nombre>` para cada funcionalidad nueva.

## Estado actual

- [x] Estructura del proyecto y las 5 apps
- [x] Modelo de Usuario personalizado (`AbstractUser`)
- [ ] Modelos completos de Proveedor, Categoría, Producto, Cotización,
      Pedido, DetallePedido y Venta (siguiente paso)
- [ ] Serializers y ViewSets de DRF
- [ ] Señal de conversión automática Cotización → Pedido
- [ ] Tests
