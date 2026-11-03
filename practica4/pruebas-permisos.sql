-- Ejecutar como postgres después de permisos.sql.
\set ON_ERROR_STOP off

\echo '1. Aplicación: SELECT e INSERT permitidos'
BEGIN;
SET LOCAL ROLE usuario_app;
SELECT COUNT(*) AS clientes_visibles FROM public.cliente;
INSERT INTO public.cliente
 (numerocliente, razonsocial, correocliente, telefonocliente, tipocliente,
  rfc, regimenfiscal, estadoorigen)
VALUES
 (99990001, 'Cliente prueba permisos', 'permisos-app@example.test',
  '+52 722 999 0001', 'NACIONAL', 'PPP260101PP1',
  'General de Ley Personas Morales', 'Estado de México');
ROLLBACK;

\echo '2. Aplicación: CREATE TABLE negado (se espera permission denied)'
BEGIN;
SET LOCAL ROLE usuario_app;
CREATE TABLE public.prueba_app_no_autorizada (id integer);
ROLLBACK;

\echo '3. Consulta: SELECT permitido'
BEGIN;
SET LOCAL ROLE usuario_consulta;
SELECT COUNT(*) AS pedidos_visibles FROM public.pedido;
ROLLBACK;

\echo '4. Consulta: INSERT negado (se espera permission denied)'
BEGIN;
SET LOCAL ROLE usuario_consulta;
INSERT INTO public.cliente
 (numerocliente, razonsocial, correocliente, telefonocliente, tipocliente,
  rfc, regimenfiscal, estadoorigen)
VALUES
 (99990002, 'Cliente no permitido', 'permisos-consulta@example.test',
  '+52 722 999 0002', 'NACIONAL', 'QQQ260101QQ1',
  'General de Ley Personas Morales', 'Estado de México');
ROLLBACK;

\echo '5. Administración: CREATE TABLE permitido y deshecho al final'
BEGIN;
SET LOCAL ROLE usuario_admin;
CREATE TABLE public.prueba_admin_temporal (id integer PRIMARY KEY);
DROP TABLE public.prueba_admin_temporal;
ROLLBACK;

\echo '6. Administración: crear usuarios/roles está negado (no tiene CREATEROLE)'
SET ROLE usuario_admin;
CREATE ROLE rol_prueba_no_autorizado;
RESET ROLE;

\echo '7. REVOKE: retirar INSERT temporalmente y comprobar el rechazo'
REVOKE INSERT ON public.cliente FROM rol_aplicacion;
BEGIN;
SET LOCAL ROLE usuario_app;
INSERT INTO public.cliente
 (numerocliente, razonsocial, correocliente, telefonocliente, tipocliente,
  rfc, regimenfiscal, estadoorigen)
VALUES
 (99990003, 'Cliente tras REVOKE', 'permisos-revoke@example.test',
  '+52 722 999 0003', 'NACIONAL', 'RRR260101RR1',
  'General de Ley Personas Morales', 'Estado de México');
ROLLBACK;

\echo '8. Restaurar INSERT para que el usuario de aplicación pueda seguir cargando'
GRANT INSERT ON public.cliente TO rol_aplicacion;
\set ON_ERROR_STOP on
