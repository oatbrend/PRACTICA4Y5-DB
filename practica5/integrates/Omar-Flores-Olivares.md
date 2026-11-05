# Ejercicio 2.6. Cambio individual — Omar Flores Olivares

## Relación seleccionada

**DETALLE pertenece a PEDIDO**: `detalle.folio` referencia a `pedido.folio`.

En el esquema original la acción es `ON DELETE CASCADE`. Se propone cambiarla a `ON DELETE RESTRICT` para proteger los renglones de una venta: si un pedido ya tiene detalles, no se puede borrar directamente. Primero se debe revisar y eliminar explícitamente cada detalle, y después el pedido. Se conserva `ON UPDATE CASCADE`.

## Cambio SQL

Archivo: `002-referencias-omar.sql`.

```sql
ALTER TABLE detalle DROP CONSTRAINT fk_detalle_pedido;

ALTER TABLE detalle
  ADD CONSTRAINT fk_detalle_pedido
  FOREIGN KEY (folio)
  REFERENCES pedido (folio)
  ON DELETE RESTRICT
  ON UPDATE CASCADE;
```

## Prueba

Archivo: `prueba-omar.sql`. Inserta un cliente, pedido y detalle temporales; comprueba que eliminar el pedido falla mientras exista el detalle; después elimina primero el detalle y luego el pedido. Todo termina en ROLLBACK para no dejar registros de prueba.

## Impacto y decisión para el dominio

- **Con RESTRICT:** el pedido permanece y sus detalles también; PostgreSQL impide eliminar el pedido mientras tenga renglones.
- **Con CASCADE:** al eliminar el pedido, sus detalles se eliminan automáticamente.
- **Conclusión:** para este modelo, CASCADE es la acción más adecuada porque DETALLE depende del PEDIDO para identificarse y no tiene sentido sin él. Si se necesita conservar el historial, el borrado lógico del pedido (`activo = FALSE`) es preferible a conservar detalles huérfanos. RESTRICT se prueba como alternativa para observar su efecto, pero no se recomienda como regla definitiva.


