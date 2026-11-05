
BEGIN;
ALTER TABLE envio ALTER COLUMN clavetransportista DROP NOT NULL;
ALTER TABLE envio DROP CONSTRAINT fk_envio_transportista;
ALTER TABLE envio
  ADD CONSTRAINT fk_envio_transportista
  FOREIGN KEY (clavetransportista)
  REFERENCES transportista (clavetransportista)
  ON DELETE SET NULL ON UPDATE CASCADE;
COMMIT;
