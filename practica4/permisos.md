# Ejercicio 1.6. Usuarios y permisos

## Roles

Se crean tres roles de grupo sin inicio de sesión y un usuario para cada uno:

- **rol_aplicacion / usuario_app:** la aplicación y el script de carga. Puede consultar, insertar, actualizar y borrar registros de las siete tablas del proyecto.
- **rol_consulta / usuario_consulta:** consultas de lectura; no puede insertar, actualizar ni borrar.
- **rol_administracion / usuario_admin:** administra las tablas del proyecto y puede crear objetos en el esquema public.

Las contraseñas *no* se guardan en el repositorio. Cada integrante las define en su archivo .env (plantilla en .env.example): POSTGRES_PASSWORD para el administrador inicial postgres, APP_DB_PASSWORD para usuario_app, CONSULTA_DB_PASSWORD para usuario_consulta y ADMIN_DB_PASSWORD para usuario_admin. El .env está en el .gitignore. Para cambiar la contraseña de un usuario, edita el .env, cárgalo con set -a; source .env; set +a y vuelve a ejecutar permisos.sql. POSTGRES_PASSWORD solo se aplica al crear la base, así que para cambiarla hay que recrearla con docker compose down -v.


## Matriz de permisos

| Tabla | Aplicación | Consulta | Administración |
|---|---|---|---|
| cliente | SELECT, INSERT, UPDATE, DELETE | SELECT | ALL |
| transportista | SELECT, INSERT, UPDATE, DELETE | SELECT | ALL |
| producto | SELECT, INSERT, UPDATE, DELETE | SELECT | ALL |
| sucursal | SELECT, INSERT, UPDATE, DELETE | SELECT | ALL |
| pedido | SELECT, INSERT, UPDATE, DELETE | SELECT | ALL |
| detalle | SELECT, INSERT, UPDATE, DELETE | SELECT | ALL |
| envio | SELECT, INSERT, UPDATE, DELETE | SELECT | ALL |
| Esquema public | USAGE | USAGE | USAGE, CREATE |
| Crear roles/usuarios | No | No | No (sin CREATEROLE) |

La administración recibe la propiedad de las tablas del proyecto y puede crear objetos en el esquema. No es superusuario ni recibe CREATEROLE: puede administrar las tablas, pero no crear cuentas o roles nuevos. La aplicación y consulta no reciben permiso para crear tablas ni modificar la estructura.

## Crear los usuarios

`permisos.sql` no contiene contraseñas: las recibe como variables de psql desde el `.env`. Con el `.env` cargado, ejecuta desde la raíz del repositorio:

```bash
docker compose cp ./practica4/permisos.sql db:/tmp/permisos.sql
docker compose exec -T db psql -U postgres -d ventas_industriales -v ON_ERROR_STOP=1 \
  -v app_pw="$APP_DB_PASSWORD" -v ro_pw="$CONSULTA_DB_PASSWORD" -v adm_pw="$ADMIN_DB_PASSWORD" \
  -f /tmp/permisos.sql
```

El cargador y el benchmark se conectan como `usuario_app` y leen su contraseña de `APP_DB_PASSWORD`.

## Pruebas

El archivo pruebas-permisos.sql ejecuta operaciones permitidas y negadas para los tres usuarios. También retira temporalmente INSERT de rol_aplicacion, comprueba que el gestor lo rechaza y vuelve a otorgarlo para no dejar inutilizado el script de carga.

```powershell
docker compose cp .\\practica4\\pruebas-permisos.sql db:/tmp/pruebas-permisos.sql
docker compose exec -T db psql -U postgres -d ventas_industriales -f /tmp/pruebas-permisos.sql
```


