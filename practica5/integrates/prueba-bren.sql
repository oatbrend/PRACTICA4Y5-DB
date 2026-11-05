BEGIN;

INSERT INTO cliente
 (numerocliente,razonsocial,correocliente,telefonocliente,tipocliente,rfc,regimenfiscal,estadoorigen)
VALUES
 (99400001,'Cliente prueba Bren','oatbrend-prueba@example.test','+52 722 400 0002',
  'NACIONAL','BRE260101BR1','General','Estado de México');

INSERT INTO sucursal (numerocliente,clavesucursal,nombreplanta)
VALUES (99400001,'BR01','Sucursal de prueba Bren');

INSERT INTO pedido (folio,numerocliente,estatus,dia,mes,anio)
VALUES (99400001,99400001,'REGISTRADO',17,8,2026);

INSERT INTO transportista
 (clavetransportista,nombreempresa,email,esnacional,esinternacional,rfc)
VALUES
 ('CI-TRANS','Transportista prueba Bren','chiikawa-trans@example.test',
  TRUE,FALSE,'TRA260101TR1');

INSERT INTO envio
 (numeroguia,folio,clavetransportista,numerocliente,clavesucursal,costoflete,dia,mes,anio)
VALUES
 ('GUIA-BRENDA-01',99400001,'CI-TRANS',99400001,'BR01',500,20,8,2026);

SELECT
  (SELECT COUNT(*) FROM transportista WHERE clavetransportista='CI-TRANS') AS transportistas_antes,
  (SELECT COUNT(*) FROM envio WHERE numeroguia='GUIA-BRENDA-01') AS envios_antes;

DELETE FROM transportista WHERE clavetransportista='CI-TRANS';

SELECT numeroguia, folio, clavetransportista
FROM envio WHERE numeroguia='GUIA-BRENDA-01';
SELECT
  (SELECT COUNT(*) FROM transportista WHERE clavetransportista='CI-TRANS') AS transportistas_despues,
  (SELECT COUNT(*) FROM envio WHERE numeroguia='GUIA-BRENDA-01') AS envios_despues;


ROLLBACK;

--Se espera que le envio no exista y clavetransportista es NULL
