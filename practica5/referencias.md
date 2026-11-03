# Ejercicio 2.1 y 2.2. Claves foráneas y acciones referenciales

El esquema del proyecto propio declara siete relaciones referenciales. Todas las claves foráneas son NOT NULL porque, de acuerdo con el modelo, cada registro hijo debe estar asociado con su padre.

| Tabla hija / FK | Tabla padre / columna | Relación del EER | ¿Admite NULL? | ON DELETE | ON UPDATE | Justificación |
|---|---|---|---|---|---|---|
| sucursal.numeroCliente | cliente.numeroCliente | CLIENTE tiene SUCURSAL | No | CASCADE | CASCADE | La sucursal depende del cliente para identificarse; al eliminar un cliente, sus sucursales dejan de tener sentido. |
| pedido.numeroCliente | cliente.numeroCliente | CLIENTE realiza PEDIDO | No | RESTRICT | CASCADE | No se elimina un cliente con pedidos porque se debe conservar el historial comercial. |
| detalle.folio | pedido.folio | PEDIDO registra DETALLE | No | CASCADE | CASCADE | El detalle depende del pedido y no tiene sentido como renglón independiente. |
| detalle.claveProducto | producto.claveProducto | PRODUCTO aparece en DETALLE | No | RESTRICT | CASCADE | No se elimina un producto si ya aparece en una venta histórica. |
| envio.(folio, numeroCliente) | pedido.(folio, numeroCliente) | PEDIDO es enviado para el mismo CLIENTE | No | RESTRICT | CASCADE | El envío debe pertenecer al pedido y al mismo cliente; la FK compuesta evita asociar un folio con un cliente diferente. |
| envio.claveTransportista | transportista.claveTransportista | TRANSPORTISTA ejecuta ENVÍO | No | RESTRICT | CASCADE | Se conserva la trazabilidad de quién realizó el traslado. |
| envio.(numeroCliente, claveSucursal) | sucursal.(numeroCliente, claveSucursal) | SUCURSAL recibe el ENVÍO | No | RESTRICT | CASCADE | El destino debe existir y estar asociado con el cliente indicado en el envío. |

## Correspondencia con el modelo relacional

- En las relaciones uno a muchos, la clave del lado uno se propaga como clave foránea al lado muchos.
- SUCURSAL tiene una clave primaria compuesta (numeroCliente, claveSucursal): una clave de sucursal puede repetirse entre clientes distintos, pero no dentro del mismo cliente.
- DETALLE se identifica con (folio, claveParcial), por lo que cada renglón pertenece a un pedido.
- ENVIO referencia la sucursal destino mediante (numeroCliente, claveSucursal).
- envio.folio también es UNIQUE: el diseño contempla como máximo un envío por pedido.
- La migración migraciones/002-referencias.sql agrega UNIQUE (pedido.folio, pedido.numeroCliente) y sustituye la FK simple de envío por una FK compuesta (folio, numeroCliente). Los 452 registros de envio del Excel cumplen esta condición: el cliente asociado al envío coincide con el del pedido. La base revisada contiene 80 clientes, 30 transportistas, 40 productos, 100 sucursales, 500 pedidos, 1,500 detalles y 452 envíos.

## Acciones referenciales elegidas

Se utiliza CASCADE cuando el hijo depende del padre para existir (sucursal y detalle). Se utiliza RESTRICT en relaciones que deben preservar el historial comercial (pedido, producto, transportista, envio y la sucursal referenciada por un envío). ON UPDATE CASCADE propaga cambios de clave primaria a los hijos para no dejar referencias desactualizadas.

Todas las relaciones son obligatorias desde el lado hijo; por eso sus claves foráneas no admiten NULL. Los datos opcionales, como teléfono de sucursal o correo de transportista, no son relaciones y sí pueden admitir NULL.
