#!/usr/bin/env python3
"""Compara INSERT individual y COPY con los 1,500 detalles del Excel."""
from __future__ import annotations

import csv
import time
from io import StringIO
from pathlib import Path

import psycopg2
from openpyxl import load_workbook
from psycopg2.extensions import make_dsn

ROOT = Path(__file__).resolve().parents[2]
ARCHIVO = ROOT / "practica4" / "datos" / "base_datos_pedidos2.xlsx"

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

def leer_detalles():
    if not ARCHIVO.is_file():
        raise FileNotFoundError(f"No se encontró el Excel: {ARCHIVO}")
    libro = load_workbook(ARCHIVO, read_only=True, data_only=True)
    try:
        ws = libro["detalle"]
        iterator = ws.iter_rows(values_only=True)
        encabezados = list(next(iterator))
        esperados = [
            "folio", "claveParcial", "claveProducto",
            "costoProduccion", "precioAplicado", "cantidad"
        ]
        if encabezados != esperados:
            raise ValueError(f"Encabezados inesperados: {encabezados}")
        filas = [
            tuple(fila)
            for fila in iterator
            if any(valor is not None and valor != "" for valor in fila)
        ]
        if len(filas) != 1500:
            raise ValueError(
                f"Se esperaban 1,500 detalles en el Excel; se encontraron {len(filas)}."
            )
        return filas
    finally:
        libro.close()

def main():
    filas = leer_detalles()
    insert_sql = (
        "INSERT INTO bench_insert "
        "(folio, claveparcial, claveproducto, costoproduccion, precioaplicado, cantidad) "
        "VALUES (%s, %s, %s, %s, %s, %s)"
    )
    columnas = """(
        folio INTEGER,
        claveparcial INTEGER,
        claveproducto VARCHAR(10),
        costoproduccion NUMERIC(12,2),
        precioaplicado NUMERIC(12,2),
        cantidad INTEGER
    )"""

    with psycopg2.connect(obtener_dsn()) as conn:
        with conn.cursor() as cur:
            cur.execute("CREATE TEMP TABLE bench_insert " + columnas)
            cur.execute("CREATE TEMP TABLE bench_copy " + columnas)

            inicio = time.perf_counter()
            for fila in filas:
                cur.execute(insert_sql, fila)
            tiempo_insert = time.perf_counter() - inicio

            buffer = StringIO()
            writer = csv.writer(buffer, lineterminator="\n")
            writer.writerows(filas)
            buffer.seek(0)

            inicio = time.perf_counter()
            cur.copy_expert(
                "COPY bench_copy "
                "(folio, claveparcial, claveproducto, costoproduccion, precioaplicado, cantidad) "
                "FROM STDIN WITH (FORMAT CSV, NULL '')",
                buffer,
            )
            tiempo_copy = time.perf_counter() - inicio

            cur.execute("SELECT COUNT(*) FROM bench_insert")
            total_insert = cur.fetchone()[0]
            cur.execute("SELECT COUNT(*) FROM bench_copy")
            total_copy = cur.fetchone()[0]

    if total_insert != len(filas) or total_copy != len(filas):
        raise RuntimeError("INSERT y COPY no cargaron el mismo número de filas.")

    print(f"Fuente: {ARCHIVO.name}, hoja detalle")
    print(f"Registros comparados: {len(filas)}")
    print(f"INSERT individual: {tiempo_insert:.6f} segundos ({total_insert} filas)")
    print(f"COPY:              {tiempo_copy:.6f} segundos ({total_copy} filas)")
    if tiempo_copy > 0:
        print(f"Relación INSERT/COPY: {tiempo_insert / tiempo_copy:.2f}x")
    if tiempo_insert > 0:
        ahorro = (1 - tiempo_copy / tiempo_insert) * 100
        print(f"Reducción de tiempo con COPY: {ahorro:.2f}%")

if __name__ == "__main__":
    main()
