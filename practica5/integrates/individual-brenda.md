# Ejercicio 2.6. Trabajo individual — Brenda Roa Venegas

## Relación propuesta

**ENVÍO es realizado por TRANSPORTISTA**: `envio.clavetransportista` referencia a `transportista.clavetransportista`.

En el esquema original la acción es `ON DELETE RESTRICT`. Se propone probar `ON DELETE SET NULL` para conservar el registro histórico del envío aunque se elimine el registro del transportista del catálogo. Para que SET NULL funcione, la columna `clavetransportista` debe admitir NULL. Se conserva `ON UPDATE CASCADE`.

## Cambio SQL

Archivo: `003-referencias-bren.sql`.

```sql
ALTER TABLE envio ALTER COLUMN clavetransportista DROP NOT NULL;
ALTER TABLE envio DROP CONSTRAINT fk_envio_transportista;

ALTER TABLE envio
  ADD CONSTRAINT fk_envio_transportista
  FOREIGN KEY (clavetransportista)
  REFERENCES transportista (clavetransportista)
  ON DELETE SET NULL
  ON UPDATE CASCADE;
```

## Impacto

- **Ventaja:** el envío y su guía permanecen en el historial aunque el transportista se elimine del catálogo.
- **Desventaja:** el registro de envío pierde la referencia a quién lo realizó.
- **Comparación con el original:** RESTRICT conserva la relación obligatoria y obliga a mantener el transportista; SET NULL conserva el envío, pero deja sin identificar al transportista eliminado.

**Conclusión de dominio:** RESTRICT es la opción más segura para el modelo actual, porque el transportista forma parte de la linea de un envío. SET NULL conserva la guía, pero pierde la identificación de quién la realizó. La propuesta permite mostrar esa diferencia y concluir que conviene mantener RESTRICT salvo que el negocio permita conservar envíos sin transportista identificado.

