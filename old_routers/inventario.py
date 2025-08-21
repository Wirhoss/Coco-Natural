from fastapi import APIRouter, Depends
import oracledb
from db import get_db, rows_to_dicts

router = APIRouter(prefix="/inventario", tags=["inventario"])

@router.post('/actualizar/{id}')
def actualizar_stock(id: int, payload: dict, conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        cur.callproc('pkg_inventario.actualizar_stock', [id, payload.get('cantidad'), payload.get('tipo')])
        conn.commit()
        return {"status":"updated"}
    finally:
        cur.close()

@router.post('/registrar_entrada/{id}')
def registrar_entrada(id: int, payload: dict, conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        cur.callproc('pkg_inventario.registrar_entrada_inventario', [id, payload.get('cantidad'), payload.get('id_proveedor')])
        conn.commit()
        return {"status":"registered"}
    finally:
        cur.close()

@router.get('/stock/{id}')
def stock_disponible(id: int, conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        v = cur.callfunc('pkg_inventario.fn_stock_disponible', oracledb.NUMBER, [id])
        return {"stock": v}
    finally:
        cur.close()

@router.post('/generar_alertas')
def generar_alertas(conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        # wrapper
        cur.callproc('pkg_alertas.generar_alertas_stock', [])
        conn.commit()
        return {"status":"alerts_generated"}
    finally:
        cur.close()
