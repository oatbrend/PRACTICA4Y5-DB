# Ejercicio 1.5. Pruebas de restricciones de dominio

El archivo ejecutable es pruebas-dominio.sql. Se ejecuta después de esquema.sql, de la migración 001-dominios.sql y de la carga del Excel revisado. Las pruebas negativas capturan el SQLSTATE y el mensaje real de PostgreSQL mediante una función temporal. La transacción termina con ROLLBACK para no conservar registros de prueba.

| Núm. | Tipo | Operación | Resultado esperado | Regla protegida |
|---:|---|---|---|---|
| 1 | NOT NULL | Insertar un cliente sin correo. | SQLSTATE 23502. | Todo cliente debe tener correo. |
| 2 | DEFAULT | Insertar un pedido omitiendo estatus y activo. | Debe mostrar REGISTRADO y TRUE. | El pedido nuevo inicia registrado y activo. |
| 3 | UNIQUE simple | Repetir un correo de cliente. | SQLSTATE 23505. | El correo de cliente no se repite. |
| 4 | UNIQUE compuesta | Repetir numeroCliente + claveSucursal. | SQLSTATE 23505. | La sucursal es única dentro del cliente. |
| 5 | CHECK de rango | Insertar detalle con cantidad cero. | SQLSTATE 23514. | La cantidad debe ser positiva. |
| 6 | CHECK de formato | Insertar correo sin arroba. | SQLSTATE 23514. | El correo respeta correo_electronico. |
| 7 | CHECK entre columnas | Insertar producto con precio de catálogo menor que costo. | SQLSTATE 23514. | El precio de catálogo cubre el costo. |
| 8 | CHECK de lista | Insertar pedido con estatus PAGADO. | SQLSTATE 23514. | Solo se admiten los estados documentados. |
| 9 | CHECK de fecha | Insertar pedido con 31 de febrero. | SQLSTATE 22008. | Los componentes forman una fecha real. |
| 10 | CHECK de formato | Insertar sucursal con CP ABC12. | SQLSTATE 23514. | El código postal tiene cinco dígitos. |
| 11 | CHECK entre columnas | Insertar detalle con precio aplicado menor que costo de producción. | SQLSTATE 23514. | No se vende por debajo del costo. |

## Reglas observadas en la fuente

Los 80 clientes tienen correo y teléfono. Los contactos de transportistas y sucursales sí pueden ser NULL. Los cuatro estados observados en pedidos son ENTREGADO, CANCELADO, ENVIADO y EN PROCESO; el diccionario de generación contempla REGISTRADO como estado inicial, por lo que también se permite y se usa como DEFAULT.

Los 40 productos tienen precioUnitarioUSD mayor que costoUnitarioUSD. Los 1,500 detalles tienen precioAplicado mayor o igual que costoProduccion. Por eso la migración puede proteger ambos casos con CHECK sin rechazar los registros del Excel.
