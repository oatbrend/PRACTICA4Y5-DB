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
- Python instalado y disponible mediante el comando **py**.
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

### Paso 3. Credenciales predeterminadas

Los usuarios y contraseñas son públicos porque este repositorio está diseñado para una práctica académica local.

| Usuario | Contraseña predeterminada | Función |
|---|---|---|
| postgres | `postgres_demo_2026` | Administrador inicial de PostgreSQL; ejecuta migraciones y crea los demás usuarios. |
| usuario_app | `app_demo_2026` | Carga el Excel y puede consultar, insertar, actualizar y borrar registros. |
| usuario_consulta | `consulta_demo_2026` | Solo puede consultar las tablas. |
| usuario_admin | `admin_demo_2026` | Administra las tablas y crea objetos en el esquema public, sin ser superusuario. |

Las credenciales están definidas en estos archivos:

- `compose.yaml`: contraseña del usuario `postgres`.
- `practica4/permisos.sql`: contraseñas de `usuario_app`, `usuario_consulta` y `usuario_admin`.
- `practica4/poblar/poblar.py` y `practica4/poblar/comparar-copy-insert.py`: datos de conexión del usuario `usuario_app`. Si cambias su contraseña, actualízala en los tres archivos donde aparece.

**Seguridad:** estas son credenciales públicas para una base local desechable. No las reutilices en servidores, proyectos reales ni bases con información privada.

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

Los tres usuarios y sus contraseñas ya están definidos en `practica4/permisos.sql`. Ejecuta el script directamente; no tienes que definir variables de entorno ni escribir contraseñas:

~~~powershell
docker compose cp .\\practica4\\permisos.sql db:/tmp/permisos.sql
docker compose exec -T db psql -U postgres -d ventas_industriales -v ON_ERROR_STOP=1 -f /tmp/permisos.sql
~~~

El script crea o actualiza estos usuarios:

| Usuario | Contraseña | Función |
|---|---|---|
| usuario_app | `app_demo_2026` | Leer, insertar, actualizar y borrar registros. Es el usuario que utiliza el cargador. |
| usuario_consulta | `consulta_demo_2026` | Consultar las tablas, sin modificar información. |
| usuario_admin | `admin_demo_2026` | Administrar las tablas y crear objetos en el esquema public, sin ser superusuario ni poder crear otros roles. |

La matriz completa está en `practica4/permisos.md`. Para cambiar las contraseñas, edita los valores indicados en el Paso 3 y vuelve a ejecutar este script para aplicar los cambios a los usuarios existentes.

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

### Paso 8. Conexión automática del cargador

El cargador y el benchmark ya utilizan las credenciales predeterminadas de `usuario_app`, la base `ventas_industriales`, el servidor `127.0.0.1` y el puerto `5434`. No necesitas configurar `DATABASE_URL`, `APP_DB_PASSWORD` ni ninguna otra variable de entorno.

Si cambias la contraseña de `usuario_app`, recuerda actualizarla tanto en `practica4/permisos.sql` como en los dos programas Python indicados en el Paso 3. Si cambias el puerto publicado en `compose.yaml`, actualiza también el puerto en esos programas.

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

En esta segunda ejecución, las claves ya existentes deben aparecer como registros existentes y no deben duplicarse.

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
docker compose cp .\practica5\pruebas-referenciales.sql db:/tmp/pruebas-referenciales.sql
docker compose exec -T db psql -U postgres -d ventas_industriales -v ON_ERROR_STOP=1 -f /tmp/pruebas-referenciales.sql
~~~

**Operaciones DML y transacciones:**

~~~powershell
docker compose cp .\practica5\sql\edicion-de-valores.sql db:/tmp/edicion-de-valores.sql
docker compose exec -T db psql -U postgres -d ventas_industriales -f /tmp/edicion-de-valores.sql
~~~

El archivo DML contiene INSERT, UPDATE, DELETE, borrado lógico, SAVEPOINT, ROLLBACK y una transacción que falla por una clave foránea inexistente. Revisa practica5/edicion-de-valores.md para conocer qué resultado debe observarse.

Las pruebas contienen operaciones temporales y bloques de ROLLBACK para no mezclar los datos de demostración con la población original. Aun así, ejecútalas únicamente sobre la base local dedicada a la práctica.


## 3. Evidencias que debes guardar

Guarda capturas auténticas en la carpeta evidencias. Cada captura debe mostrar el comando ejecutado y el resultado. Oculta contraseñas y cualquier dato sensible.

| Evidencia | Qué debe mostrar |
|---|---|
| 01 | PostgreSQL del proyecto propio levantado. |
| 02 | Ejecución correcta de las migraciones 001 y 002. |
| 03 | Primera carga del Excel y conteos insertados por tabla. |
| 04 | Segunda carga y registros existentes, sin duplicados. |
| 05 | Comparación real de INSERT y COPY. |
| 06 | Pruebas de dominio. |
| 07 | Pruebas de permisos, operaciones permitidas/negadas y REVOKE. |
| 08 | Pruebas de integridad referencial y conteos antes/después. |
| 09 | Operaciones DML y transacciones. |
| 10 | Verificación de la población del proyecto asignado. |
| 11 | Carga y conteos del proyecto asignado. |
| 12 | Comprobaciones de integridad del almacén y pruebas de restricciones en una copia. |
| 13 | Pull Request revisado y fusionado. |

El archivo evidencias/README.md contiene la lista de capturas sugeridas.

## 4. Orden recomendado de trabajo

1. Coloca el Excel revisado en practica4\datos.
2. Inicia Docker y crea la base del proyecto propio.
3. Ejecuta la migración 001 y luego la 002.
4. Crea los usuarios y permisos.
5. Instala las dependencias de Python.
6. Ejecuta la carga del Excel dos veces.
7. Ejecuta la comparación INSERT/COPY.
8. Ejecuta las pruebas de dominio, permisos, integridad y DML.
9. Trabaja en el repositorio separado de Obra Pública Municipal.
10. Guarda las capturas y solicita revisión del Pull Request.

## 5. Documentación por ejercicio

| Archivo | Contenido |
|---|---|
| practica4/dominios.md | Tipos de dato, longitudes, dominios y reglas. |
| practica4/fuente.md | Fuente, colaboración de Claude, correspondencia y calidad de datos. |
| practica4/pruebas-dominio.md | Casos de prueba de restricciones. |
| practica4/permisos.md | Usuarios, roles y matriz de privilegios. |
| practica4/proyecto-asignado/ | Fuente, conteos y carga de Obra Pública Municipal. |
| practica5/referencias.md | Claves foráneas y acciones referenciales. |
| practica5/pruebas-referenciales.md | Pruebas de integridad referencial. |
| practica5/edicion-de-valores.md | DML y transacciones. |
| practica5/integridad-almacen.md | Integridad referencial del almacén asignado. |
| evidencias/README.md | Capturas que se deben obtener. |
