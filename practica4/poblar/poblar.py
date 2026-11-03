#!/usr/bin/env python3
"""Carga el Excel sintético revisado del proyecto propio en PostgreSQL.

Fuente: practica4/datos/base_datos_pedidos2.xlsx
Carga transaccional con COPY, en orden de dependencia, sin duplicar claves.
"""
from __future__ import annotations

import argparse
import csv
import sys
from io import StringIO
from pathlib import Path

import psycopg2
from psycopg2 import sql
from psycopg2.extensions import make_dsn
from openpyxl import load_workbook

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_FILE = ROOT / "practica4" / "datos" / "base_datos_pedidos2.xlsx"

# Nombre de hoja, tabla de PostgreSQL y columnas en orden de importación.
TABLES = [
    ("cliente", "cliente",
     ["numerocliente", "razonsocial", "correocliente", "telefonocliente",
      "tipocliente", "rfc", "regimenfiscal", "estadoorigen",
      "idfiscalglobal", "paisreceptor"]),
    ("transportista", "transportista",
     ["clavetransportista", "nombreempresa", "telefonoatencion", "email",
      "esnacional", "esinternacional", "rfc", "codigoaduanal", "agenciaaduanal"]),
    ("producto", "producto",
     ["claveproducto", "modeloproducto", "costounitariousd", "preciounitariousd",
      "tipoproducto", "provmaquinaria", "provtransformador", "provtransporte"]),
    ("sucursal", "sucursal",
     ["numerocliente", "clavesucursal", "nombreplanta", "telefonoencargado",
      "calle", "numero", "ciudad", "estado", "pais", "cp"]),
    ("pedido", "pedido",
     ["folio", "numerocliente", "estatus", "dia", "mes", "anio", "activo"]),
    ("detalle", "detalle",
     ["folio", "claveparcial", "claveproducto", "costoproduccion",
      "precioaplicado", "cantidad"]),
    ("envio", "envio",
     ["numeroguia", "folio", "clavetransportista", "numerocliente",
      "clavesucursal", "costoflete", "dia", "mes", "anio"]),
]

# Conteos de control de esta versión del Excel. Si la fuente cambia,
# revisar fuente.md y actualizar estos valores conscientemente.
EXPECTED_ROWS = {
    "cliente": 80,
    "transportista": 30,
    "producto": 40,
    "sucursal": 100,
    "pedido": 500,
    "detalle": 1500,
    "envio": 452,
}

HEADERS = {
    "cliente": ["numeroCliente", "razonSocial", "correoCliente", "telefonoCliente",
                "tipoCliente", "RFC", "regimenFiscal", "estadoOrigen",
                "idFiscalGlobal", "paisReceptor"],
    "transportista": ["claveTransportista", "nombreEmpresa", "telefonoAtencion",
                      "email", "esNacional", "esInternacional", "RFC",
                      "codigoAduanal", "agenciaAduanal"],
    "producto": ["claveProducto", "modeloProducto", "costoUnitarioUSD",
                 "precioUnitarioUSD", "tipoProducto", "provMaquinaria",
                 "provTransformador", "provTransporte"],
    "sucursal": ["numeroCliente", "claveSucursal", "nombrePlanta",
                 "telefonoEncargado", "calle", "numero", "ciudad",
                 "estado", "pais", "CP"],
    "pedido": ["folio", "numeroCliente", "estatus", "dia", "mes", "anio", "activo"],
    "detalle": ["folio", "claveParcial", "claveProducto", "costoProduccion",
                "precioAplicado", "cantidad"],
    "envio": ["numeroGuia", "folio", "claveTransportista", "numeroCliente",
              "claveSucursal", "costoFlete", "dia", "mes", "anio"],
}

# Credenciales públicas de demostración para la base local de la práctica.
# Si cambias la contraseña de usuario_app, actualízala también en
# practica4/permisos.sql.
DB_NAME = "ventas_industriales"
DB_USER = "usuario_app"
DB_PASSWORD = "app_demo_2026"
DB_HOST = "127.0.0.1"
DB_PORT = "5434"

def obtener_dsn() -> str:
    return make_dsn(
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        host=DB_HOST,
        port=DB_PORT,
    )

def leer_excel(ruta: Path):
    if not ruta.is_file():
        raise FileNotFoundError(
            f"No se encontró el archivo fuente: {ruta}\n"
            "Coloca base_datos_pedidos2.xlsx en practica4/datos/."
        )

    libro = load_workbook(ruta, read_only=True, data_only=True)
    datos = []
    try:
        faltantes = {hoja for hoja, _, _ in TABLES} - set(libro.sheetnames)
        if faltantes:
            raise ValueError(f"Faltan hojas requeridas: {sorted(faltantes)}")

        for hoja, tabla, columnas in TABLES:
            ws = libro[hoja]
            iterator = ws.iter_rows(values_only=True)
            encabezados = next(iterator, None)
            encabezados = [
                str(valor).strip() if valor is not None else ""
                for valor in (encabezados or [])
            ]
            if encabezados != HEADERS[hoja]:
                raise ValueError(
                    f"Encabezados incorrectos en hoja {hoja}.\n"
                    f"Esperados: {HEADERS[hoja]}\nRecibidos: {encabezados}"
                )

            registros = []
            for numero_fila, fila in enumerate(iterator, start=2):
                fila = list(fila[:len(columnas)])
                if not fila or all(valor is None or valor == "" for valor in fila):
                    continue
                if len(fila) != len(columnas):
                    raise ValueError(
                        f"Hoja {hoja}, fila {numero_fila}: "
                        "número de columnas incorrecto."
                    )
                registros.append(
                    tuple(None if valor == "" else valor for valor in fila)
                )

            esperado = EXPECTED_ROWS[tabla]
            if len(registros) != esperado:
                raise ValueError(
                    f"Conteo inesperado en hoja {hoja}: {len(registros)} filas; "
                    f"la versión documentada debe tener {esperado}."
                )
            datos.append((tabla, columnas, registros))
    finally:
        libro.close()
    return datos

def copiar_tabla(cur, tabla: str, columnas: list[str], filas):
    """Usa COPY en staging y transfiere a la tabla definitiva sin duplicar PK."""
    temporal = f"stg_{tabla}"
    cur.execute(
        sql.SQL("CREATE TEMP TABLE {} (LIKE public.{} INCLUDING DEFAULTS) ON COMMIT DROP")
        .format(sql.Identifier(temporal), sql.Identifier(tabla))
    )

    buffer = StringIO()
    writer = csv.writer(buffer, lineterminator="\n")
    writer.writerows(filas)
    buffer.seek(0)

    columnas_sql = sql.SQL(", ").join(sql.Identifier(c) for c in columnas)
    copy_stmt = sql.SQL(
        "COPY {} ({}) FROM STDIN WITH (FORMAT CSV, NULL '')"
    ).format(sql.Identifier(temporal), columnas_sql)
    cur.copy_expert(copy_stmt.as_string(cur), buffer)

    insert_stmt = sql.SQL(
        "INSERT INTO public.{} ({}) SELECT {} FROM {} ON CONFLICT DO NOTHING"
    ).format(
        sql.Identifier(tabla),
        columnas_sql,
        columnas_sql,
        sql.Identifier(temporal),
    )
    cur.execute(insert_stmt)
    insertadas = cur.rowcount
    return len(filas), insertadas, len(filas) - insertadas

def main() -> int:
    parser = argparse.ArgumentParser(
        description="Carga la versión revisada del Excel de pedidos."
    )
    parser.add_argument(
        "--archivo",
        type=Path,
        default=DEFAULT_FILE,
        help="Ruta del XLSX fuente.",
    )
    args = parser.parse_args()

    conexion = None
    tabla_actual = "validación del archivo"
    try:
        datos = leer_excel(args.archivo)
        conexion = psycopg2.connect(obtener_dsn())
        conexion.autocommit = False

        resultados = []
        with conexion.cursor() as cur:
            for tabla, columnas, filas in datos:
                tabla_actual = tabla
                total, insertadas, existentes = copiar_tabla(
                    cur, tabla, columnas, filas
                )
                resultados.append((tabla, total, insertadas, existentes))

        conexion.commit()
        print("Carga confirmada. Fuente:", args.archivo)
        print("| Tabla | Filas del Excel | Insertadas | Ya existentes | Rechazadas |")
        print("|---|---:|---:|---:|---:|")
        for tabla, total, insertadas, existentes in resultados:
            print(f"| {tabla} | {total} | {insertadas} | {existentes} | 0 |")
        print("Total:", sum(item[1] for item in resultados), "registros.")
        print("Repite el comando para comprobar que no se duplican las claves.")
        return 0

    except Exception as exc:
        if conexion is not None:
            conexion.rollback()
        print("ERROR: la carga completa fue revertida.", file=sys.stderr)
        print("Tabla/etapa:", tabla_actual, file=sys.stderr)
        print("Detalle:", exc, file=sys.stderr)
        if isinstance(exc, psycopg2.Error) and exc.diag is not None:
            if exc.diag.sqlstate:
                print("SQLSTATE:", exc.diag.sqlstate, file=sys.stderr)
            if exc.diag.constraint_name:
                print("Restricción:", exc.diag.constraint_name, file=sys.stderr)
            if exc.diag.message_detail:
                print("Detalle de PostgreSQL:", exc.diag.message_detail, file=sys.stderr)
        print(
            "No se confirmó ninguna tabla: se ejecutó ROLLBACK.",
            file=sys.stderr,
        )
        return 1
    finally:
        if conexion is not None:
            conexion.close()

if __name__ == "__main__":
    raise SystemExit(main())
