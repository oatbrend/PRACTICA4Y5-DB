# Ejercicio 1.3. Fuente de datos del proyecto propio

## Fuente seleccionada y procedencia

La fuente principal de esta práctica es el archivo [**base_datos_pedidos2.xlsx**](./datos/base_datos_pedidos2.xlsx). Contiene una base relacional sintética para una empresa que comercializa tres líneas de productos industriales: OMNIGOLD, HYVOLT y HYPRENE.

Tomamos como referencia la estructura de una base de datos que pertenecía a una empresa privada. Para no divulgar la información de esa empresa, se modificó y abstrajo el modelo: se conservaron las entidades, los atributos y las relaciones necesarios para representar el dominio, pero los registros utilizados en esta práctica son inventados. Después se explicó a **Claude (Anthropic), como colaborador de IA generativa**, la estructura modificada y las reglas de cada entidad para que apoyara la creación aleatoria y controlada de los datos.

La hoja Notas del archivo también indica que los registros son inventados y que se generaron a partir del diccionario de dominios. Por tanto, el Excel no es una exportación de ventas reales ni un conjunto de datos público. Claude se menciona como herramienta colaboradora en la generación, no como autor de datos comerciales reales ni como proveedor de una licencia.

## Referencia

Equipo del proyecto. (2026). *Base de datos sintética de pedidos* [Archivo de datos XLSX no publicado; generación asistida por Claude (Anthropic)]. Escuela Superior de Cómputo, Instituto Politécnico Nacional.

El archivo no fue publicado por una institución y no cuenta con una licencia abierta de datos. Su uso es académico dentro del proyecto. La estructura de la base privada que sirvió como referencia no se redistribuye; se utiliza únicamente el modelo abstraído y los registros sintéticos.

## Formato, tamaño y volumen

- Archivo recibido: **base_datos_pedidos2.xlsx**.
- Formato: Microsoft Excel (XLSX).
- Tamaño del archivo recibido: 120,440 bytes (aproximadamente 117.6 KiB).
- Hojas: siete hojas relacionales y una hoja de notas.
- Total de registros en las siete tablas: 2,702.
- Total de columnas relacionales: 59.
- Periodo de pedidos observado: 2025-01-02 a 2026-10-29.
- Periodo de envíos observado: 2025-01-06 a 2026-11-02.

| Hoja / tabla | Registros | Columnas |
|---|---:|---|
| cliente | 80 | numeroCliente, razonSocial, correoCliente, telefonoCliente, tipoCliente, RFC, regimenFiscal, estadoOrigen, idFiscalGlobal, paisReceptor |
| transportista | 30 | claveTransportista, nombreEmpresa, telefonoAtencion, email, esNacional, esInternacional, RFC, codigoAduanal, agenciaAduanal |
| producto | 40 | claveProducto, modeloProducto, costoUnitarioUSD, precioUnitarioUSD, tipoProducto, provMaquinaria, provTransformador, provTransporte |
| sucursal | 100 | numeroCliente, claveSucursal, nombrePlanta, telefonoEncargado, calle, numero, ciudad, estado, pais, CP |
| pedido | 500 | folio, numeroCliente, estatus, dia, mes, anio, activo |
| detalle | 1,500 | folio, claveParcial, claveProducto, costoProduccion, precioAplicado, cantidad |
| envio | 452 | numeroGuia, folio, claveTransportista, numeroCliente, claveSucursal, costoFlete, dia, mes, anio |
| **Total** | **2,702** | **59 columnas** |

La hoja Notas tiene doce renglones de explicación y no se importa como tabla.

**Aclaración sobre la modificación de la base de datos original:** En la versión original se contaba con más columnas de las reportadas en la modificada, precisamente se eliminaron aquellas que comprometían información privada para la empresa, atributos derivados que no contemplamos en el modelo de nuestro proyecto propio y columnas que funcionaban como consultas para la empresa privada, se conservaron aquellas columnas funcionales para el modelo relacional del proyecto propio.

## Correspondencia entre la fuente y el esquema

Las siete hojas relacionales corresponden directamente a las siete tablas del esquema. Sus encabezados se conservan como atributos equivalentes, normalizados a minúsculas al insertarse en PostgreSQL. No se descartan campos de las tablas. La hoja Notas se conserva como documentación y no se importa.

| Hoja | Tabla destino | Correspondencia |
|---|---|---|
| cliente | cliente | Las diez columnas pasan a atributos homónimos. |
| transportista | transportista | Las nueve columnas pasan a atributos homónimos. |
| producto | producto | Las ocho columnas pasan a atributos homónimos; modeloProducto se agrega mediante migración. |
| sucursal | sucursal | Las diez columnas pasan a atributos homónimos. |
| pedido | pedido | Las siete columnas pasan a atributos homónimos; activo se agrega mediante migración. |
| detalle | detalle | Las seis columnas pasan a atributos homónimos. |
| envio | envio | Las nueve columnas pasan a atributos homónimos. |
| Notas | No se importa | Describe volumen, supuestos y reglas de generación. |

## Revisión de calidad y decisiones

| Revisión | Resultado observado | Decisión |
|---|---|---|
| Claves primarias | No hay claves duplicadas en cliente, transportista, producto, pedido ni envio. Tampoco en las claves compuestas de sucursal y detalle. | Se conservan las claves primarias simples y compuestas del modelo. |
| Clientes | 80 registros: 60 NACIONAL y 20 EXPORTACION. Todos tienen razón social, correo y teléfono. | Se aplican NOT NULL a esos atributos. |
| Datos fiscales de clientes | Los 60 nacionales tienen RFC, régimen y estado; los 20 de exportación tienen identificador fiscal global y país. Los atributos del otro subtipo quedan NULL. | Se conserva la regla de especialización entre NACIONAL y EXPORTACION. |
| RFC de cliente | 60 no nulos, todos distintos y con el formato revisado. | Se conserva UNIQUE y CHECK de formato, admitiendo NULL para exportación. |
| Identificador fiscal global | 20 no nulos, sin duplicados. | Se conserva UNIQUE y se permite NULL para clientes nacionales. |
| Transportistas | 30 registros: 24 con modalidad nacional y 10 con modalidad internacional; cuatro operan en ambas. | Se conserva el CHECK de modalidad y las reglas de RFC y datos aduanales. |
| Contacto de transportistas | 29 correos y 25 teléfonos no nulos; los valores presentes son distintos y cumplen el formato revisado. | Se permite NULL en email y teléfono; se valida su formato cuando existen. |
| Datos aduanales | Diez transportistas tienen modalidad internacional y los diez tienen código y agencia aduanal. | Se conserva la obligatoriedad condicionada a esInternacional. |
| Productos | 40 productos, diez modelos con cuatro presentaciones cada uno. Tipos: 24 OMNIGOLD, 4 HYVOLT y 12 HYPRENE. | Se incorpora modeloProducto y se valida su correspondencia con tipoProducto. |
| Proveedor por línea | En cada producto solo se llena el proveedor de la línea correspondiente. | Se conserva el CHECK de proveedor por subtipo. |
| Precios de catálogo | En los 40 productos, precioUnitarioUSD es mayor que costoUnitarioUSD. | Se conserva un CHECK que impide precio de catálogo menor que costo. |
| Sucursales | 100 registros; todas las claves compuestas (numeroCliente, claveSucursal) son únicas y apuntan a un cliente existente. | Se conserva la PK compuesta y FK a cliente. |
| Teléfono de sucursal | 85 valores presentes y 15 NULL. | Se permite NULL y se valida el formato cuando existe. |
| Código postal | Los 100 valores tienen cinco dígitos. | Se conserva CHECK de formato, sin declarar UNIQUE como regla general del dominio. |
| Pedidos | 500 registros: 444 ENTREGADO, 41 CANCELADO, 8 ENVIADO y 7 EN PROCESO. | CHECK con los cuatro estados encontrados. |
| Borrado lógico | 456 pedidos activos y 44 inactivos; todos los cancelados están inactivos y hay tres entregados inactivos. | Se conserva activo; DEFAULT TRUE para nuevos pedidos y se permite representar inactividad de registros entregados. |
| Detalles | 1,500 renglones; cada pedido tiene entre uno y ocho detalles. No hay detalles huérfanos ni claves compuestas duplicadas. | Se conserva PK (folio, claveParcial) y las dos FKs. |
| Precio aplicado | En los 1,500 detalles, precioAplicado es mayor que costoProduccion. | Se añade CHECK para impedir ventas por debajo del costo de producción. |
| Envíos | 452 guías, todas distintas y con folio único. Hay exactamente un envío por cada pedido ENVIADO o ENTREGADO; los 41 CANCELADO y 7 EN PROCESO no tienen envío. | Se conserva UNIQUE en envio.folio y la FK hacia pedido. |
| Correspondencia de clientes | En todos los envíos, numeroCliente coincide con el cliente del pedido y con el de la sucursal destino. | Se agrega una FK compuesta entre envio(folio, numeroCliente) y pedido(folio, numeroCliente). |
| Transportista por tipo de cliente | Todos los clientes nacionales usan transportista nacional y todos los de exportación usan transportista internacional. | Se documenta y comprueba la consistencia de los datos. |
| Fechas | Todas las fechas forman fechas válidas. Los 452 envíos son posteriores a su pedido. | Se conservan CHECK de calendario y la validación referencial de las fechas entre pedido y envío en el análisis. |
| Huérfanos | Cero registros huérfanos en las siete relaciones revisadas. | Se mantienen declaradas las claves foráneas. |

Los valores NULL son parte de las reglas del dominio: por ejemplo, RFC y régimen no aplican a clientes de exportación, mientras que los identificadores fiscales globales y país no aplican a clientes nacionales. Los teléfonos opcionales de transportistas y sucursales tampoco deben convertirse artificialmente en obligatorios.

Los datos muestran que muchos pedidos se concentran en ciertos clientes y que cada pedido puede tener varios detalles. Esa distribución es útil para probar consultas posteriores, sin tener que crear artificialmente el mismo número de filas en todas las entidades.

## Carga automatizada
Desarrollado con el apoyo de ChatGPT como herramienta de guía para la estructuración del script de automatización y validación en Python.

El archivo debe colocarse en:

    practica4/datos/base_datos_pedidos2.xlsx

El programa practica4/poblar/poblar.py valida hojas, encabezados y cantidades esperadas; carga en orden de dependencia mediante COPY y confirma todo dentro de una sola transacción. La conexión se define con DATABASE_URL y debe utilizar usuario_app, no el administrador.

La carga debe ser repetible: en la segunda ejecución, las claves existentes se detectan mediante ON CONFLICT DO NOTHING y el programa informa cuántas filas ya estaban registradas. Si una fila incumple una restricción, se ejecuta ROLLBACK para no dejar una carga parcial.

El archivo XLSX es un insumo necesario para ejecutar la carga y debe acompañar el repositorio en la carpeta indicada. Los tiempos INSERT/COPY y los mensajes reales del gestor se obtienen al ejecutar en el equipo local; no se sustituyen por resultados simulados.
