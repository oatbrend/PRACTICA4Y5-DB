# Ejercicio 2.3. Pruebas de integridad referencial


## Relaciones comprobadas en la fuente

El Excel contiene 80 clientes, 30 transportistas, 40 productos, 100 sucursales, 500 pedidos, 1,500 detalles y 452 envíos. Las claves primarias simples y compuestas no presentan duplicados. Las relaciones entre las siete tablas no presentan registros huérfanos.

Los 452 envíos corresponden exactamente a los 444 pedidos ENTREGADO y los 8 ENVIADO. Los 41 pedidos CANCELADO y los 7 EN PROCESO no tienen envío. En todos los envíos, el cliente coincide con el cliente del pedido y con el de la sucursal destino. Además, el transportista corresponde a la modalidad del cliente (nacional o exportación).

La migración 002 declara una FK compuesta entre envio(folio, numeroCliente) y pedido(folio, numeroCliente). Esta regla evita asociar el folio de un pedido con el identificador de otro cliente, algo que una FK simple sobre folio no detectaría.

## Casos de prueba

| Prueba | Operación | Resultado esperado | Qué demuestra |
|---|---|---|---|
| ON DELETE CASCADE | Eliminar un cliente de prueba que tiene sucursal. | Se eliminan cliente y sucursal. | Antes y después se muestran conteos. |
| ON DELETE RESTRICT | Eliminar un cliente que tiene pedido. | SQLSTATE 23503; el cliente y pedido permanecen. | Se conserva el historial comercial. |
| ON UPDATE CASCADE | Cambiar la clave del cliente de prueba. | La nueva clave pasa a sucursal y pedido. | Las referencias se actualizan. |
| FK de transportista | Insertar envío con transportista inexistente. | SQLSTATE 23503. | No se permiten transportistas inexistentes. |
| FK compuesta pedido/cliente | Usar folio de un cliente y sucursal de otro. | SQLSTATE 23503. | El envío corresponde al mismo cliente del pedido. |
| Orden de carga | Insertar pedido antes de crear cliente; después cargar padre e hijo. | Primer INSERT rechazado; segundo aceptado. | Las tablas padre se cargan antes que las hijas. |

## Comprobaciones finales

Las consultas del SQL comprueban sucursales, pedidos, detalles y envíos sin padre; correos duplicados, sucursales duplicadas y clientes sin correo. Para la versión del Excel revisada, todas deben devolver cero.

