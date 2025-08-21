from fastapi import APIRouter, Depends
import oracledb
from db import get_db, rows_to_dicts

router = APIRouter(prefix="/reportes", tags=["reportes"])

@router.get('/ventas_por_mes/{anio}')
def ventas_por_mes(anio: int, conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        ref = cur.callfunc('pkg_reportes.cur_ventas_por_mes', oracledb.CURSOR, [anio])
        return rows_to_dicts(ref)
    finally:
        cur.close()

@router.get('/clientes_sin_pedidos/{meses}')
def clientes_sin_pedidos(meses: int, conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        ref = cur.callfunc('pkg_reportes.cur_clientes_sin_pedidos', oracledb.CURSOR, [meses])
        return rows_to_dicts(ref)
    finally:
        cur.close()

@router.get('/stock_por_categoria')
def stock_por_categoria(conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        ref = cur.callfunc('pkg_reportes.cur_stock_por_categoria', oracledb.CURSOR)
        return rows_to_dicts(ref)
    finally:
        cur.close()
