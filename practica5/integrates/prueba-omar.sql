BEGIN;

CREATE TEMP TABLE _inicializar_pg_temp (id integer) ON COMMIT DROP;

CREATE OR REPLACE FUNCTION pg_temp.esperar_error_fk(p_sql text)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE v_estado text; v_mensaje text;
BEGIN
  BEGIN
    EXECUTE p_sql;
    RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='Se permitió borrar un pedido con detalle.';
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_estado=RETURNED_SQLSTATE, v_mensaje=MESSAGE_TEXT;
    IF v_estado='P0001' THEN RAISE; END IF;
    IF v_estado<>'23503' THEN RAISE; END IF;
    RAISE NOTICE 'RESTRICT correcto: SQLSTATE %, mensaje: %',v_estado,v_mensaje;
  END;
END;
$$;

INSERT INTO cliente
 (numerocliente,razonsocial,correocliente,telefonocliente,tipocliente,rfc,regimenfiscal,estadoorigen)
VALUES
 (99300001,'Cliente prueba Omar','omar-prueba@example.test','+52 722 400 0001',
  'NACIONAL','OMA260101OM1','General','Estado de México');

INSERT INTO pedido (folio,numerocliente,estatus,dia,mes,anio)
VALUES (99300001,99300001,'REGISTRADO',1,2,2026);

INSERT INTO detalle (folio,claveparcial,claveproducto,costoproduccion,precioaplicado,cantidad)
SELECT 99300001,1,claveproducto,costounitariousd,preciounitariousd,1
FROM producto ORDER BY claveproducto LIMIT 1;

SELECT COUNT(*) AS detalles_antes
FROM detalle WHERE folio=99300001;

SELECT pg_temp.esperar_error_fk(
  'DELETE FROM pedido WHERE folio=99300001'
);

SELECT COUNT(*) AS pedido_conservado
FROM pedido WHERE folio=99300001;

DELETE FROM detalle WHERE folio=99300001;
DELETE FROM pedido WHERE folio=99300001;
SELECT
  (SELECT COUNT(*) FROM detalle WHERE folio=99300001) AS detalles_despues,
  (SELECT COUNT(*) FROM pedido WHERE folio=99300001) AS pedido_despues;
DELETE FROM cliente WHERE numerocliente=99300001;

ROLLBACK;
