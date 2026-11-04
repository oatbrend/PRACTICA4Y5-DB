
BEGIN;

CREATE OR REPLACE FUNCTION pg_temp.esperar_error(
    p_nombre text, p_sql text, p_sqlstate text
) RETURNS void LANGUAGE plpgsql AS $$
DECLARE
    v_estado text;
    v_mensaje text;
BEGIN
    BEGIN
        EXECUTE p_sql;
        RAISE EXCEPTION USING ERRCODE = 'P0001',
            MESSAGE = 'La operación no fue rechazada por la restricción esperada.';
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_estado = RETURNED_SQLSTATE,
            v_mensaje = MESSAGE_TEXT;
        IF v_estado = 'P0001' THEN RAISE; END IF;
        IF v_estado <> p_sqlstate THEN
            RAISE EXCEPTION 'Prueba %: se esperaba SQLSTATE %, se recibió % (%).',
                p_nombre, p_sqlstate, v_estado, v_mensaje;
        END IF;
        RAISE NOTICE 'OK - % - SQLSTATE %, mensaje: %',
            p_nombre, v_estado, v_mensaje;
    END;
END;
$$;

-- 1. NOT NULL: correoCliente es obligatorio.
SELECT pg_temp.esperar_error(
 'NOT NULL en correo del cliente',
 'INSERT INTO cliente (numerocliente,razonsocial,correocliente,telefonocliente,tipocliente,rfc,regimenfiscal,estadoorigen)
  VALUES (99000001,''Cliente de prueba'',NULL,''+52 722 000 0000'',''NACIONAL'',''ZZZ260101ZZ1'',''General'',''Estado de México'')',
 '23502'
);

-- 2. DEFAULT: al omitir estatus y activo, toma REGISTRADO y TRUE.
INSERT INTO pedido (folio,numerocliente,dia,mes,anio)
SELECT 99000002,MIN(numerocliente),1,1,2026 FROM cliente;
SELECT folio,estatus,activo
FROM pedido WHERE folio=99000002;
DELETE FROM pedido WHERE folio=99000002;

-- 3. UNIQUE simple: correo de cliente no se repite.
SELECT pg_temp.esperar_error(
 'UNIQUE simple en correo de cliente',
 'INSERT INTO cliente (numerocliente,razonsocial,correocliente,telefonocliente,tipocliente,rfc,regimenfiscal,estadoorigen)
  SELECT 99000003,''Cliente duplicado'',correocliente,''+52 722 000 0001'',''NACIONAL'',''YYY260101YY1'',''General'',''Estado de México''
  FROM cliente LIMIT 1',
 '23505'
);

-- 4. UNIQUE compuesta: no se repite cliente + claveSucursal.
SELECT pg_temp.esperar_error(
 'UNIQUE compuesta de sucursal',
 'INSERT INTO sucursal (numerocliente,clavesucursal,nombreplanta)
  SELECT numerocliente,clavesucursal,''Sucursal duplicada'' FROM sucursal LIMIT 1',
 '23505'
);

-- 5. CHECK de rango: cantidad del detalle debe ser positiva.
SELECT pg_temp.esperar_error(
 'CHECK de cantidad positiva',
 'INSERT INTO detalle (folio,claveparcial,claveproducto,costoproduccion,precioaplicado,cantidad)
  SELECT p.folio,999,pr.claveproducto,10,20,0 FROM pedido p CROSS JOIN producto pr LIMIT 1',
 '23514'
);

-- 6. CHECK de formato: correo sin arroba.
SELECT pg_temp.esperar_error(
 'CHECK de formato de correo',
 'INSERT INTO cliente (numerocliente,razonsocial,correocliente,telefonocliente,tipocliente,rfc,regimenfiscal,estadoorigen)
  VALUES (99000004,''Cliente correo inválido'',''correo-sin-arroba'',''+52 722 000 0004'',''NACIONAL'',''XXX260101XX1'',''General'',''Estado de México'')',
 '23514'
);

-- 7. CHECK entre columnas: precio de catálogo menor que costo.
SELECT pg_temp.esperar_error(
 'CHECK de precio unitario vs costo',
 'INSERT INTO producto (claveproducto,modeloproducto,costounitariousd,preciounitariousd,tipoproducto,provmaquinaria)
  VALUES (''PRUEBA990'',''OMNIGOLD P220N'',100,90,''OMNIGOLD'',''Proveedor de prueba'')',
 '23514'
);

-- 8. CHECK de lista: PAGADO no es un estado permitido.
SELECT pg_temp.esperar_error(
 'CHECK de estatus permitido',
 'INSERT INTO pedido (folio,numerocliente,estatus,dia,mes,anio)
  SELECT 99000005,MIN(numerocliente),''PAGADO'',5,1,2026 FROM cliente',
 '23514'
);

-- 9. CHECK de fecha: 31 de febrero no existe.
SELECT pg_temp.esperar_error(
 'CHECK de fecha válida',
 'INSERT INTO pedido (folio,numerocliente,estatus,dia,mes,anio)
  SELECT 99000006,MIN(numerocliente),''ENVIADO'',31,2,2026 FROM cliente',
 '22008'
);

-- 10. CHECK de formato postal: CP debe tener cinco dígitos.
SELECT pg_temp.esperar_error(
 'CHECK de código postal',
 'INSERT INTO sucursal (numerocliente,clavesucursal,nombreplanta,cp)
  SELECT MIN(numerocliente),''CPBAD'',''Sucursal CP inválido'',''ABC12'' FROM cliente',
 '23514'
);

-- 11. CHECK de precio aplicado: no puede ser menor al costo de producción.
SELECT pg_temp.esperar_error(
 'CHECK de precio aplicado vs costo de producción',
 'INSERT INTO detalle (folio,claveparcial,claveproducto,costoproduccion,precioaplicado,cantidad)
  SELECT p.folio,998,pr.claveproducto,100,90,1 FROM pedido p CROSS JOIN producto pr LIMIT 1',
 '23514'
);

ROLLBACK;