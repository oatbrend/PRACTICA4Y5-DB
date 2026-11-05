# Ejercicio 2.5. Integridad referencial en el almacén asignado

## Tablas de hechos, dimensiones y granularidad


| Tabla de hechos | ¿Qué representa una fila? | Clave primaria |
|---|---|---|
| warehouse.fact_eventos_auditoria | Un evento de auditoría ocurrido en una fecha, con un tipo de evento y referencias opcionales a obra, región, personal, constructora, fuente, presupuesto, poblador o propuesta. | (tiempo_key, evento_key) |
| warehouse.fact_obra_mensual | El resumen de una obra para un mes específico: presupuesto, costo acumulado, saldo, avance, retraso y conteos de informes, evidencias y permisos. | (tiempo_key, obra_key) |

La granularidad de `fact_eventos_auditoria` es un evento individual. La granularidad de `fact_obra_mensual` es una combinación obra-mes: una obra puede tener una fila por cada mes de seguimiento, pero no dos filas para la misma obra y fecha.

Las diez dimensiones declaradas en el esquema son:

- `dim_tiempo`
- `dim_tipo_evento`
- `dim_obra`
- `dim_region`
- `dim_constructora`
- `dim_personal`
- `dim_fuente`
- `dim_presupuesto`
- `dim_poblador`
- `dim_propuesta`

## Claves foráneas declaradas

El archivo `db/arquitectura/ESQUEMA DEL DATA WAREHOUSE.sql` declara las claves foráneas de ambas tablas de hechos.

- `fact_eventos_auditoria.tiempo_key` y `tipo_evento_key` son NOT NULL y apuntan a `dim_tiempo` y `dim_tipo_evento\).
- Sus referencias a obra, región, personal, constructora, fuente, presupuesto, poblador y propuesta son opcionales; por eso admiten NULL.
- `fact_obra_mensual.tiempo_key` y `obra_key` son NOT NULL y apuntan a `dim_tiempo` y `dim_obra`.

No se encontró una FK faltante entre las tablas de hechos y las dimensiones enumeradas. El SQL de comprobación revisa de todos modos las referencias huérfanas con LEFT JOIN; cada conteo debe ser cero.

## ¿Por qué algunos almacenes no declaran todas las FK?

En almacenes con cargas muy grandes, a veces se omiten temporalmente algunas claves foráneas para que la carga masiva tarde menos o para aceptar primero los registros y validarlos después. El riesgo es que entren claves que no existen en las dimensiones. Entonces aparecen hechos huérfanos: al unirlos con la dimensión faltante, esos registros no se muestran y los conteos pueden ser incorrectos. En este proyecto las FK sí están declaradas, por lo que se conservan y se comprueban con las consultas anteriores.

## Consultas de comprobación

El archivo `sql/comprobar-integridad-almacen.sql` incluye:

1. Conteo de hechos sin dimensión de tiempo o tipo de evento.
2. Conteo de referencias no nulas a dimensiones inexistentes.
3. Conteo de hechos mensuales sin dimensión de obra.
4. Conteo de claves duplicadas y nulos en las referencias obligatorias.

## Tres restricciones de dominio que conviene agregar

Se proponen restricciones sencillas que protegen los valores almacenados, sin cambiar el modelo:

| Restricción | Regla | ¿Qué comprueba? |
|---|---|---|
| Montos no negativos en fact_obra_mensual | Presupuesto, costo acumulado y saldo no pueden ser negativos. | Busca registros con montos menores que cero. |
| Porcentajes de avance entre 0 y 100 en fact_obra_mensual | Un porcentaje no puede ser menor que cero ni mayor que cien. | Busca avances fuera del intervalo. |
| Porcentajes de avance entre 0 y 100 en fact_eventos_auditoria | Cuando se captura un porcentaje de avance, debe estar entre cero y cien. | Busca eventos con porcentaje fuera del intervalo. |

Las consultas previas a la migración permiten revisar si los datos actuales cumplen las reglas. La migración se debe aplicar en una copia de la base, tal como pide la práctica. El script de prueba intenta introducir un porcentaje de 101 y espera que PostgreSQL lo rechace.

## Datos y comparación con el artículo

El artículo reporta un escenario de datos sintéticos: 1,247 obras, 55 comunidades, presupuesto acumulado de $127.4 millones MXN, 8,934 eventos de auditoría, 3,421 evidencias, 2,341 pobladores, 2,156 propuestas y 8,723 votos. El generador del repositorio declara esos mismos valores y contiene una opción `--verificar` que comprueba la población prevista sin conectarse a PostgreSQL.

Los conteos reales de las tablas deben obtenerse después de ejecutar el generador. No se presentan como ejecutados en este documento porque requieren levantar el contenedor local.
