
-- Roles de grupo: no pueden iniciar sesión directamente.
SELECT 'CREATE ROLE rol_aplicacion NOLOGIN'
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_aplicacion') \gexec
SELECT 'CREATE ROLE rol_consulta NOLOGIN'
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_consulta') \gexec
SELECT 'CREATE ROLE rol_administracion NOLOGIN'
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_administracion') \gexec

-- Usuarios de conexión con contraseñas predeterminadas.
SELECT 'CREATE ROLE usuario_app LOGIN'
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'usuario_app') \gexec
ALTER ROLE usuario_app WITH LOGIN PASSWORD :'app_pw';

SELECT 'CREATE ROLE usuario_consulta LOGIN'
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'usuario_consulta') \gexec
ALTER ROLE usuario_consulta WITH LOGIN PASSWORD :'ro_pw';

SELECT 'CREATE ROLE usuario_admin LOGIN'
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'usuario_admin') \gexec
ALTER ROLE usuario_admin WITH LOGIN PASSWORD :'adm_pw';


GRANT rol_aplicacion TO usuario_app;
GRANT rol_consulta TO usuario_consulta;
GRANT rol_administracion TO usuario_admin;

GRANT USAGE ON SCHEMA public TO rol_aplicacion, rol_consulta, rol_administracion;
GRANT SELECT, INSERT, UPDATE, DELETE
  ON public.cliente, public.transportista, public.producto, public.sucursal,
     public.pedido, public.detalle, public.envio
  TO rol_aplicacion;
GRANT SELECT
  ON public.cliente, public.transportista, public.producto, public.sucursal,
     public.pedido, public.detalle, public.envio
  TO rol_consulta;

-- Administración: propietario de las tablas del proyecto y permiso de crear
-- objetos en public. Se otorga CREATE antes de transferir la propiedad.
GRANT CREATE ON SCHEMA public TO rol_administracion;
ALTER TABLE public.cliente OWNER TO rol_administracion;
ALTER TABLE public.transportista OWNER TO rol_administracion;
ALTER TABLE public.producto OWNER TO rol_administracion;
ALTER TABLE public.sucursal OWNER TO rol_administracion;
ALTER TABLE public.pedido OWNER TO rol_administracion;
ALTER TABLE public.detalle OWNER TO rol_administracion;
ALTER TABLE public.envio OWNER TO rol_administracion;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO rol_administracion;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO rol_administracion;

-- Los objetos que el administrador cree después conservan el mismo criterio.
ALTER DEFAULT PRIVILEGES FOR ROLE rol_administracion IN SCHEMA public
  GRANT ALL ON TABLES TO rol_administracion;
ALTER DEFAULT PRIVILEGES FOR ROLE rol_administracion IN SCHEMA public
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO rol_aplicacion;
ALTER DEFAULT PRIVILEGES FOR ROLE rol_administracion IN SCHEMA public
  GRANT SELECT ON TABLES TO rol_consulta;
