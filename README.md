# Prácticas 4 y 5 — Proyecto propio y proyecto asignado

## Integrantes
- Brenda Roa Venegas
- Omar Flores Olivares

Grupo: 3BV1. Gestor del proyecto propio: PostgreSQL 17.

## Proyecto propio

El proyecto representa las ventas y los envíos de tres líneas industriales: OMNIGOLD, HYVOLT y HYPRENE. La población principal se encuentra en el Excel sintético base_datos_pedidos2.xlsx. El equipo adaptó la estructura de referencia de una base privada, explicó el modelo y sus reglas a Claude (Anthropic), y Claude colaboró en la generación aleatoria y controlada de los registros.

El Excel contiene 80 clientes, 30 transportistas, 40 productos, 100 sucursales, 500 pedidos, 1,500 detalles y 452 envíos (2,702 registros en total). Todos los registros son sintéticos; no son ventas reales ni datos de la empresa privada. La procedencia, correspondencia de campos y calidad se documentan en [fuente.md](./practica4/fuente.md).
## 1. Requisitos
- Docker Desktop instalado y abierto.
- Python 3 (en Mac y Linux, el comando python3; en Windows, el comando **py**).
- Git para descargar o actualizar los repositorios.
- El archivo Excel revisado **base_datos_pedidos2.xlsx**.


No necesitas instalar PostgreSQL directamente en Windows: Docker ejecuta el servidor de base de datos.
## 2. Ejecución del proyecto propio

### Paso 1. Abrir la carpeta de trabajo
Abre una terminal en la carpeta del repositorio, **todos los comandos de esta carpeta.**
### Paso 2. Comprobar archivo Excel

Comprueba que el archivo **base_datos_pedidos2.xlsx** se encuentre dentro de esta ruta:

    practica4\datos\base_datos_pedidos2.xlsx

El cargador espera exactamente ese nombre y las siguientes cantidades:

| Hoja | Filas esperadas |
|---|---:|
| cliente | 80 |
| transportista | 30 |
| producto | 40 |
| sucursal | 100 |
| pedido | 500 |
| detalle | 1,500 |
| envio | 452 |
| **Total** | **2,702** |

Comprueba que el archivo exista en esa ubicación antes de continuar. Si no está, el programa de carga se detendrá con un error.

Los registros son sintéticos. El equipo modificó y abstrajo la estructura de referencia de una base privada, explicó el modelo a Claude (Anthropic) y Claude colaboró en la generación aleatoria y controlada de los registros. No se incluyen datos privados de la empresa original. La explicación completa está en [fuente.md](./practica4/fuente.md)

### Paso 3. Contraseñas con variables de entorno 

Las contraseñas no se guardan en el repositorio. Se leen desde un archivo .env que cada integrante crea en su computadora y que no se sube (está en el .gitignore).

1. Copia la plantilla:

   ```bash
   cp .env.example .env
   ```

2. Abre `.env` y escribe una contraseña para cada variable. Usa valores distintos entre sí:

   | Variable | Para qué se usa |
   |---|---|
   | `POSTGRES_PASSWORD` | Administrador inicial de PostgreSQL (`postgres`). Lo lee `compose.yaml`. |
   | `APP_DB_PASSWORD` | Usuario `usuario_app`: carga el Excel y consulta, inserta, actualiza y borra registros. Lo leen los programas Python. |
   | `CONSULTA_DB_PASSWORD` | Usuario `usuario_consulta`: solo lectura. |
   | `ADMIN_DB_PASSWORD` | Usuario `usuario_admin`: administra las tablas, sin ser superusuario. |

3. Carga las variables en la terminal. Hay que repetirlo cada vez que abras una ventana nueva:

   ```bash
   set -a; source .env; set +a
   ```

Dónde se usa cada variable:

- `compose.yaml`: lee `POSTGRES_PASSWORD` directamente del `.env`. Como es obligatoria, Docker Compose se detiene con un aviso si falta.
- `practica4/permisos.sql`: recibe las contraseñas de los tres usuarios como variables de psql (comando del Paso 6).
- `practica4/poblar/poblar.py` y `practica4/poblar/comparar-copy-insert.py`: leen `APP_DB_PASSWORD`. Si no está definida, se detienen con el mensaje "Falta la variable de entorno APP_DB_PASSWORD".

Variables opcionales de conexión (con su valor por omisión): `DB_NAME` (`ventas_industriales`), `DB_USER` (`usuario_app`), `DB_HOST` (`127.0.0.1`) y `DB_PORT` (`5434`).

**Importante:** `POSTGRES_PASSWORD` solo se aplica cuando Docker crea el volumen por primera vez. Si se cambia después, usar `docker compose down -v` para recrear la base.



### Paso 4. Iniciar el servidor de base de datos

Asegúrate de que Docker Desktop esté abierto y ejecuta:

~~~powershell
docker compose up -d
docker compose ps
~~~

El servicio de base de datos se llama db. Docker publica PostgreSQL en el puerto 5434 de tu computadora y crea la base ventas_industriales.

La primera vez que se crea el volumen, PostgreSQL ejecuta automáticamente esquema.sql y crea las siete tablas vacías. Comprueba que el servidor responda:

~~~powershell
docker compose exec db pg_isready -U postgres -d ventas_industriales
~~~

Debe aparecer un mensaje indicando que acepta conexiones.

**Importante sobre el volumen:** Docker conserva la base aunque detengas los contenedores. Si ya habías iniciado una base anterior, no vuelvas a aplicar el esquema manualmente. Las migraciones siguientes se ejecutan una sola vez sobre una base recién inicializada.

Para detener los contenedores sin borrar los datos:

~~~powershell
docker compose down
~~~

Solo si deseas borrar por completo la base local y empezar de cero, puedes eliminar también el volumen:

~~~powershell
docker compose down -v
~~~

Este último comando elimina los datos almacenados localmente. Úsalo únicamente si no necesitas conservarlos.

### Paso 5. Aplicar las migraciones

Las migraciones agregan dominios, restricciones y una relación referencial compuesta. Deben ejecutarse en este orden y una sola vez.

**Primera migración: dominios y restricciones**

~~~powershell
docker compose cp .\practica4\migraciones\001-dominios.sql db:/tmp/001-dominios.sql
docker compose exec -T db psql -U postgres -d ventas_industriales -v ON_ERROR_STOP=1 -f /tmp/001-dominios.sql
~~~

**Segunda migración: integridad referencial**

~~~powershell
docker compose cp .\practica5\migraciones\002-referencias.sql db:/tmp/002-referencias.sql
docker compose exec -T db psql -U postgres -d ventas_industriales -v ON_ERROR_STOP=1 -f /tmp/002-referencias.sql
~~~

Si PostgreSQL muestra un error, detente y revisa el mensaje antes de continuar. No ejecutes otra vez una migración que ya se aplicó correctamente: los archivos contienen instrucciones ALTER TABLE que no están diseñadas para repetirse.

### Paso 6. Crear los usuarios y permisos

`practica4/permisos.sql` crea tres roles de grupo y un usuario para cada uno. No contiene contraseñas: las recibe del `.env`. Con el `.env` cargado (Paso 3), ejecuta:

```bash
docker compose cp ./practica4/permisos.sql db:/tmp/permisos.sql
docker compose exec -T db psql -U postgres -d ventas_industriales -v ON_ERROR_STOP=1 \
  -v app_pw="$APP_DB_PASSWORD" \
  -v ro_pw="$CONSULTA_DB_PASSWORD" \
  -v adm_pw="$ADMIN_DB_PASSWORD" \
  -f /tmp/permisos.sql
```

El script crea o actualiza estos usuarios:

| Usuario | Función |
|---|---|
| usuario_app | Leer, insertar, actualizar y borrar registros. Es el usuario que utiliza el cargador. |
| usuario_consulta | Consultar las tablas, sin modificar información. |
| usuario_admin | Administrar las tablas y crear objetos en el esquema public, sin ser superusuario ni poder crear otros roles. |

La matriz completa está en [permisos.md](./practica4/permisos.md). Para cambiar una contraseña, edita el `.env`, vuelve a cargarlo y ejecuta de nuevo este paso.


### Paso 7. Preparar Python

En la misma ventana de PowerShell, crea y activa un entorno virtual e instala las dependencias:

~~~powershell
py -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r .\practica4\poblar\requirements.txt
~~~

Si PowerShell impide activar el entorno virtual, puedes instalar las dependencias y ejecutar los programas usando directamente el intérprete del entorno:

~~~powershell
.\.venv\Scripts\python.exe -m pip install -r .\practica4\poblar\requirements.txt
.\.venv\Scripts\python.exe .\practica4\poblar\poblar.py
.\.venv\Scripts\python.exe .\practica4\poblar\comparar-copy-insert.py
~~~

Cuando el entorno está activo, la línea de comandos empieza con `(.venv)`. Si abres una terminal nueva, vuelve a activarlo con `source .venv/bin/activate`.

`requirements.txt` acepta `psycopg2-binary` en la versión 2.9.10 o posterior. Una versión fija puede no tener paquete precompilado para tu versión de Python, y entonces pip intenta compilarla y falla con `pg_config executable not found'

### Paso 8. Conexión automática del cargador

El cargador y el benchmark se conectan como `usuario_app` a la base `ventas_industriales`, en `127.0.0.1:5434`. La contraseña la leen de `APP_DB_PASSWORD`, que se carga con el `.env` (Paso 3). Si la variable no está definida, el programa lo avisa y se detiene sin intentar conectarse.

### Paso 9. Cargar el Excel

Confirma que el archivo Excel está en practica4\datos y ejecuta:

~~~powershell
python .\practica4\poblar\poblar.py
~~~

El programa:

1. Comprueba que existan las siete hojas y que sus encabezados coincidan.
2. Comprueba que cada hoja tenga el número de filas esperado.
3. Carga primero las tablas padre y después las tablas que dependen de ellas.
4. Utiliza COPY mediante tablas temporales para realizar la carga masiva.
5. Inserta los datos definitivos dentro de una sola transacción.
6. Informa cuántos registros leyó, insertó y encontró ya existentes.

Si una fila incumple una restricción, el programa ejecuta ROLLBACK y no deja una carga parcial.

**Comprueba que la carga sea repetible:** ejecuta el mismo comando por segunda vez:

~~~powershell
py .\practica4\poblar\poblar.py
~~~

En la segunda ejecución, las claves ya existentes deben aparecer como registros existentes (0 insertadas) y no deben duplicarse.


### Paso 10. Comparar INSERT contra COPY

Con el Excel y la conexión todavía disponibles, ejecuta:

~~~powershell
python .\practica4\poblar\comparar-copy-insert.py
~~~

El programa mide INSERT individual y COPY usando los mismos 1,500 renglones de la hoja detalle. Guarda los tiempos que muestre tu equipo: dependen del hardware y del entorno, por lo que no se incluyen valores inventados en los documentos.


### Paso 11. Ejecutar las pruebas de la Práctica 4

**Pruebas de dominio:**

~~~powershell
docker compose cp .\practica4\pruebas-dominio.sql db:/tmp/pruebas-dominio.sql
docker compose exec -T db psql -U postgres -d ventas_industriales -v ON_ERROR_STOP=1 -f /tmp/pruebas-dominio.sql
~~~

**Pruebas de permisos:**

~~~powershell
docker compose cp .\practica4\pruebas-permisos.sql db:/tmp/pruebas-permisos.sql
docker compose exec -T db psql -U postgres -d ventas_industriales -f /tmp/pruebas-permisos.sql
~~~

Las pruebas de permisos se ejecutan como postgres porque retiran y restauran temporalmente privilegios mediante REVOKE y GRANT. Los mensajes de permiso denegado forman parte de las pruebas negativas esperadas.

### Paso 12. Ejecutar las pruebas de la Práctica 5

**Integridad referencial:**

~~~powershell
docker compose cp .\practica5\sql\pruebas-referenciales.sql db:/tmp/pruebas-referenciales.sql
docker compose exec -T db psql -U postgres -d ventas_industriales -v ON_ERROR_STOP=1 -f /tmp/pruebas-referenciales.sql
~~~

**Operaciones DML y transacciones:**

~~~powershell
docker compose cp .\practica5\sql\edicion-de-valores.sql db:/tmp/edicion-de-valores.sql
docker compose exec -T db psql -U postgres -d ventas_industriales -f /tmp/edicion-de-valores.sql
~~~

El archivo DML contiene INSERT, UPDATE, DELETE, borrado lógico, SAVEPOINT, ROLLBACK y una transacción que falla por una clave foránea inexistente. Revisa practica5/edicion-de-valores.md para conocer qué resultado debe observarse.

Las pruebas contienen operaciones temporales y bloques de ROLLBACK para no mezclar los datos de demostración con la población original. Aun así, ejecútalas únicamente sobre la base local dedicada a la práctica.




