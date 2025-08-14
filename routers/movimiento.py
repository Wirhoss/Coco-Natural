from fastapi import APIRouter, Depends
import oracledb
from db import get_db, rows_to_dicts

router = APIRouter(prefix="/movimiento", tags=["movimiento"])

@router.get('/')
def list_movimientos(conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        ref = cur.callfunc('pkg_movimiento.obtener_movimientos', oracledb.CURSOR)
        return rows_to_dicts(ref)
    finally:
        cur.close()

@router.post('/')
def create_movimiento(payload: dict, conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        cur.callproc('pkg_movimiento.insertar_movimiento', [payload.get('id_movimiento'), payload.get('tipo'), payload.get('cantidad'), payload.get('id_producto')])
        conn.commit()
        return {"status":"created"}
    finally:
        cur.close()

@router.get('/producto/{id}')
def movimientos_por_producto(id: int, conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        ref = cur.callfunc('pkg_movimiento.cur_movimientos_por_producto', oracledb.CURSOR, [id])
        return rows_to_dicts(ref)
    finally:
        cur.close()