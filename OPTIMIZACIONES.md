# Evidencia de optimizaciones

## Operación costosa identificada

El endpoint `GET /api/productos/` serializa cada producto junto a su categoría. Si se usa lazy loading, acceder a `categoria_detalle` puede ejecutar una consulta adicional por producto: el patrón N+1.

La vista usa `select_related('categoria')`, que realiza un `JOIN` y obtiene productos y categorías en una misma consulta. Se eligió eager loading porque la respuesta siempre incluye la categoría; lazy loading solo sería preferible cuando una operación no necesitara ese dato relacionado.

## Cache-aside

1. La vista busca la respuesta en Redis con una clave que incluye la URL completa.
2. Ante una ausencia, consulta SQLite, serializa y guarda el resultado durante 300 segundos.
3. Al crear, actualizar o eliminar una categoría o producto, limpia la caché de forma explícita.
4. Después del commit de la transacción, encola `warmup_product_cache` para recalentar en Redis la ruta principal `/api/productos/` sin retrasar la respuesta HTTP.

El callback `transaction.on_commit` evita que un worker lea datos que aún no fueron confirmados. Redis se comparte entre la API y el worker definidos en `compose.yaml`.

## Comparación antes y después

La prueba `ProductoCacheAndNPlusOneTest` mide consultas SQL:

| Escenario | Resultado esperado |
| --- | --- |
| Primera solicitud, sin caché | Menos de 4 consultas y sin N+1 |
| Segunda solicitud, con caché | 0 consultas SQL |

Ejecutar `python manage.py test productos` para reproducir la comparación. La prueba adicional confirma que una modificación invalida la caché y encola el recalentamiento solo después del commit.

## Ejecución con Redis y Celery

```powershell
docker compose up --build
docker compose exec api python manage.py createsuperuser
```

El servicio `api` expone la API en `http://localhost:8000`; `worker` procesa la cola Celery; y `redis` sirve como broker, backend de resultados y caché compartida.
