from fastapi import APIRouter, Depends
import oracledb
from db import get_db, rows_to_dicts

router = APIRouter(prefix="/pedido", tags=["pedido"])

@router.post('/procesar/{id}')
def procesar_pedido(id: int, conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        cur.callproc('pkg_pedido.procesar_pedido', [id])
        conn.commit()
        return {"status":"processed"}
    finally:
        cur.close()

@router.post('/calcular_total/{id}')
def calcular_total(id: int, conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        cur.callproc('pkg_pedido.calcular_total_pedido', [id])
        conn.commit()
        return {"status":"calculated"}
    finally:
        cur.close()

@router.get('/detalle/{id}')
def detalle_pedido(id: int, conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        ref = cur.callfunc('pkg_pedido.cur_detalle_pedido_completo', oracledb.CURSOR, [id])
        return rows_to_dicts(ref)
    finally:
        cur.close()