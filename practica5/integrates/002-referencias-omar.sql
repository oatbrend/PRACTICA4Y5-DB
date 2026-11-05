-- Ejecutar sobre una COPIA después de esquema.sql y 001-dominios.sql.
BEGIN;
ALTER TABLE detalle DROP CONSTRAINT fk_detalle_pedido;
ALTER TABLE detalle
  ADD CONSTRAINT fk_detalle_pedido
  FOREIGN KEY (folio) REFERENCES pedido(folio)
  ON DELETE RESTRICT ON UPDATE CASCADE;
COMMIT;
