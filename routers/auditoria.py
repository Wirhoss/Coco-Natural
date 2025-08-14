from fastapi import APIRouter, Depends
import oracledb
from db import get_db, rows_to_dicts

router = APIRouter(prefix="/auditoria", tags=["auditoria"])

@router.get('/cambios/{dias}')
def auditoria_cambios(dias: int, conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        ref = cur.callfunc('pkg_auditoria.cur_auditoria_cambios', oracledb.CURSOR, [dias])
        return rows_to_dicts(ref)
    finally:
        cur.close()