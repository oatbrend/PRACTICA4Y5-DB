-- Migración 002: fortalecer la relación entre envío, pedido y cliente.
-- Los datos del Excel cumplen la regla: el cliente del envío coincide con el cliente del pedido.
BEGIN;

ALTER TABLE pedido
  ADD CONSTRAINT uq_pedido_folio_cliente UNIQUE (folio, numerocliente);

-- Se reemplaza la FK simple por una FK compuesta para impedir que un envío
-- use el folio de un pedido y el número de otro cliente.
ALTER TABLE envio
  DROP CONSTRAINT fk_envio_pedido;

ALTER TABLE envio
  ADD CONSTRAINT fk_envio_pedido_cliente
  FOREIGN KEY (folio, numerocliente)
  REFERENCES pedido (folio, numerocliente)
  ON DELETE RESTRICT
  ON UPDATE CASCADE;

COMMIT;

