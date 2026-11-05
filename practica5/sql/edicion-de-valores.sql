BEGIN;

INSERT INTO sucursal
 (numerocliente,clavesucursal,nombreplanta,telefonoencargado,calle,numero,ciudad,estado,pais,cp)
SELECT numerocliente,'S-DEM-01','Sucursal de demostración',
       telefonoencargado,calle,numero,ciudad,estado,pais,cp
FROM sucursal
ORDER BY numerocliente,clavesucursal
LIMIT 1
ON CONFLICT (numerocliente,clavesucursal) DO NOTHING;

-- Se repite la misma operación; la clave compuesta evita duplicados.
INSERT INTO sucursal (numerocliente,clavesucursal,nombreplanta)
SELECT numerocliente,'S-DEM-01','Sucursal de demostración'
FROM sucursal
ORDER BY numerocliente,clavesucursal
LIMIT 1
ON CONFLICT (numerocliente,clavesucursal) DO NOTHING;

SELECT COUNT(*) AS sucursales_demostracion
FROM sucursal WHERE clavesucursal='S-DEM-01';

-- 2. UPDATE basado en producto: toma el precio de catálogo para un detalle.

UPDATE pedido p
SET estatus=CASE
    WHEN p.estatus='CANCELADO' THEN 'CANCELADO'
    WHEN p.estatus='ENTREGADO' THEN 'ENTREGADO'
    WHEN EXISTS (SELECT 1 FROM envio e WHERE e.folio=p.folio) THEN 'ENVIADO'
    ELSE 'EN PROCESO'
END
WHERE p.folio=(SELECT MIN(folio) FROM pedido)
RETURNING p.folio,p.estatus;


-- UPDATE con CASE según exista un envío relacionado.
-- Se conservan los estados finales (CANCELADO y ENTREGADO); con envío, el pedido
-- queda ENVIADO; sin envío, EN PROCESO.

UPDATE pedido p
SET estatus=CASE
    WHEN p.estatus='CANCELADO' THEN 'CANCELADO'
    WHEN EXISTS (SELECT 1 FROM envio e WHERE e.folio=p.folio)
         AND p.estatus='ENVIADO' THEN 'ENVIADO'
    WHEN EXISTS (SELECT 1 FROM envio e WHERE e.folio=p.folio)
      THEN 'ENTREGADO'
    ELSE 'EN PROCESO'
END
WHERE p.folio=(SELECT MIN(folio) FROM pedido)
RETURNING p.folio,p.estatus;

-- Borrado lógico: cambia activo, pero conserva el pedido y sus detalles.
UPDATE pedido
SET activo=FALSE
WHERE folio=(SELECT MIN(folio) FROM pedido WHERE activo=TRUE)
RETURNING folio,estatus,activo;

-- 3. DELETE con subconsulta sobre un pedido temporal.
INSERT INTO pedido (folio,numerocliente,estatus,dia,mes,anio)
SELECT 99200010,c.numerocliente,'ENVIADO',10,10,2026
FROM cliente c
WHERE c.numerocliente=(SELECT MIN(numerocliente) FROM cliente);

INSERT INTO detalle
 (folio,claveparcial,claveproducto,costoproduccion,precioaplicado,cantidad)
SELECT 99200010,1,claveproducto,costounitariousd,preciounitariousd,2
FROM producto
ORDER BY claveproducto LIMIT 1;

-- Se crea el envío usando un transportista compatible con el tipo de cliente
-- y una sucursal perteneciente al mismo cliente.
INSERT INTO envio
 (numeroguia,folio,clavetransportista,numerocliente,clavesucursal,costoflete,dia,mes,anio)
SELECT 'GUIA-99200010',p.folio,t.clavetransportista,p.numerocliente,
       s.clavesucursal,800.00,12,10,2026
FROM pedido p
JOIN cliente c ON c.numerocliente=p.numerocliente
JOIN sucursal s ON s.numerocliente=c.numerocliente
JOIN transportista t
  ON (c.tipocliente='NACIONAL' AND t.esnacional)
  OR (c.tipocliente='EXPORTACION' AND t.esinternacional)
WHERE p.folio=99200010
ORDER BY t.clavetransportista,s.clavesucursal
LIMIT 1;

-- Se elimina primero el envío porque envio -> pedido es RESTRICT.
DELETE FROM envio
WHERE folio IN (
    SELECT p.folio
    FROM pedido p
    WHERE p.folio=99200010
      AND EXISTS (SELECT 1 FROM detalle d WHERE d.folio=p.folio)
);

-- El pedido se elimina mediante una subconsulta sobre detalle.
-- detalle -> pedido usa CASCADE, por eso se elimina también el renglón hijo.
DELETE FROM pedido p
WHERE p.folio IN (
    SELECT d.folio
    FROM detalle d
    WHERE d.folio=p.folio
)
AND p.folio=99200010;

SELECT
  (SELECT COUNT(*) FROM pedido WHERE folio=99200010) AS pedido_restante,
  (SELECT COUNT(*) FROM detalle WHERE folio=99200010) AS detalles_restantes,
  (SELECT COUNT(*) FROM envio WHERE folio=99200010) AS envios_restantes;

-- Se recupera la fuente original, incluidos los cambios de sucursal,
-- precio, estado y activo de esta primera parte.
ROLLBACK;

-- Qué se pierde al borrar de verdad: pedidos cancelados sin envío.
BEGIN;
SELECT (SELECT COUNT(*) FROM pedido) AS pedido_antes,
       (SELECT COUNT(*) FROM detalle) AS detalle_antes;
DELETE FROM pedido p
WHERE p.estatus='CANCELADO'
  AND NOT EXISTS (SELECT 1 FROM envio e WHERE e.folio=p.folio);
SELECT (SELECT COUNT(*) FROM pedido) AS pedido_despues,
       (SELECT COUNT(*) FROM detalle) AS detalle_despues;
ROLLBACK;

-- 4. Transacción de varias tablas con SAVEPOINT, reversión parcial y COMMIT.
BEGIN;

INSERT INTO pedido (folio,numerocliente,estatus,dia,mes,anio)
SELECT 99200011,c.numerocliente,'EN PROCESO',15,10,2026
FROM cliente c
WHERE c.numerocliente=(SELECT MIN(numerocliente) FROM cliente);

INSERT INTO detalle
 (folio,claveparcial,claveproducto,costoproduccion,precioaplicado,cantidad)
SELECT 99200011,1,claveproducto,costounitariousd,preciounitariousd,1
FROM producto
ORDER BY claveproducto LIMIT 1;

SAVEPOINT antes_del_envio;

INSERT INTO envio
 (numeroguia,folio,clavetransportista,numerocliente,clavesucursal,costoflete,dia,mes,anio)
SELECT 'GUIA-99200011',p.folio,t.clavetransportista,p.numerocliente,
       s.clavesucursal,850.00,17,10,2026
FROM pedido p
JOIN cliente c ON c.numerocliente=p.numerocliente
JOIN sucursal s ON s.numerocliente=c.numerocliente
JOIN transportista t
  ON (c.tipocliente='NACIONAL' AND t.esnacional)
  OR (c.tipocliente='EXPORTACION' AND t.esinternacional)
WHERE p.folio=99200011
ORDER BY t.clavetransportista,s.clavesucursal
LIMIT 1;

-- Clasificación temporal posterior a la creación del envío.

UPDATE pedido p
SET estatus=CASE
    WHEN EXISTS (SELECT 1 FROM envio e WHERE e.folio=p.folio)
      THEN 'ENVIADO'
    ELSE 'EN PROCESO'
END
WHERE p.folio=99200011;

SELECT estatus AS estatus_tras_el_case FROM pedido WHERE folio=99200011;

ROLLBACK TO SAVEPOINT antes_del_envio;

SELECT
  (SELECT COUNT(*) FROM pedido WHERE folio=99200011) AS pedido_conservado,
  (SELECT COUNT(*) FROM detalle WHERE folio=99200011) AS detalle_conservado,
  (SELECT COUNT(*) FROM envio WHERE folio=99200011) AS envio_revertido,
  (SELECT estatus FROM pedido WHERE folio=99200011) AS estatus_restaurado;

COMMIT;

-- Limpieza de la demostración confirmada; detalle se elimina por CASCADE.
BEGIN;
DELETE FROM pedido WHERE folio=99200011;
COMMIT;

-- 5. Fallo a mitad de transacción por una FK inexistente.
-- El segundo INSERT falla; ROLLBACK también revierte el pedido inicial.
\set ON_ERROR_STOP off
BEGIN;

INSERT INTO pedido (folio,numerocliente,estatus,dia,mes,anio)
SELECT 99200012,MIN(numerocliente),'REGISTRADO',20,10,2026
FROM cliente;

INSERT INTO detalle
 (folio,claveparcial,claveproducto,costoproduccion,precioaplicado,cantidad)
VALUES
 (99200012,1,'PRODUCTO-INEXISTENTE',10.00,15.00,1);

ROLLBACK;

SELECT COUNT(*) AS pedido_no_conservado_tras_fallo
FROM pedido WHERE folio=99200012;
\set ON_ERROR_STOP on
