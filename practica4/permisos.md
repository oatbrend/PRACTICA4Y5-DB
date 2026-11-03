# Ejercicio 1.6. Usuarios y permisos

## Roles

Se crean tres roles de grupo sin inicio de sesión y un usuario para cada uno:

- **rol_aplicacion / usuario_app:** la aplicación y el script de carga. Puede consultar, insertar, actualizar y borrar registros de las siete tablas del proyecto.
- **rol_consulta / usuario_consulta:** consultas de lectura; no puede insertar, actualizar ni borrar.
- **rol_administracion / usuario_admin:** administra las tablas del proyecto y puede crear objetos en el esquema public.

Las contraseñas predeterminadas son públicas y están definidas directamente en el proyecto para facilitar la ejecución local de la práctica. 
| Usuario | Contraseña | Uso |
|---|---|---|
| postgres | `postgres_demo_2026` | Administrador inicial de PostgreSQL. |
| usuario_app | `app_demo_2026` | Carga y modificación de registros. |
| usuario_consulta | `consulta_demo_2026` | Consultas de solo lectura. |
| usuario_admin | `admin_demo_2026` | Administración de tablas y objetos en public. |

Para cambiar contraseñas, edita `compose.yaml` para el usuario postgres y `practica4/permisos.sql` para los tres usuarios de la práctica. Si cambias la contraseña de `usuario_app`, actualízala también en `practica4/poblar/poblar.py` y `practica4/poblar/comparar-copy-insert.py`. Ejecuta de nuevo `permisos.sql` para aplicar los cambios de los tres usuarios. Estas claves son únicamente para una base local de demostración; no deben reutilizarse en producción.

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

Las contraseñas ya están definidas en [permisos.sql](./practica4/permisos.sql). Ejecuta el script desde la carpeta del repositorio:

```powershell
docker compose cp .\\practica4\\permisos.sql db:/tmp/permisos.sql
docker compose exec -T db psql -U postgres -d ventas_industriales -v ON_ERROR_STOP=1 -f /tmp/permisos.sql
```

El cargador y el benchmark utilizan automáticamente `usuario_app` con la contraseña predeterminada. No es necesario establecer `DATABASE_URL` ni variables de entorno.

## Pruebas

El archivo pruebas-permisos.sql ejecuta operaciones permitidas y negadas para los tres usuarios. También retira temporalmente INSERT de rol_aplicacion, comprueba que el gestor lo rechaza y vuelve a otorgarlo para no dejar inutilizado el script de carga.

```powershell
docker compose cp .\\practica4\\pruebas-permisos.sql db:/tmp/pruebas-permisos.sql
docker compose exec -T db psql -U postgres -d ventas_industriales -f /tmp/pruebas-permisos.sql
```
