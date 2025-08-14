from fastapi import APIRouter, Depends
import oracledb
from db import get_db

router = APIRouter(prefix="/utilidades", tags=["utilidades"])

@router.get('/generar_codigo_pedido')
def generar_codigo(conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        v = cur.callfunc('pkg_utilidades.fn_generar_codigo_pedido', oracledb.STRING)
        return {"codigo": v}
    finally:
        cur.close()

@router.get('/calcular_subtotal')
def calcular_subtotal(cantidad: float, precio: float, conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        v = cur.callfunc('pkg_utilidades.fn_calcular_subtotal', oracledb.NUMBER, [cantidad, precio])
        return {"subtotal": float(v)}
    finally:
        cur.close()