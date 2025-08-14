from fastapi import APIRouter, Depends
from db import get_db

router = APIRouter(prefix="/alertas", tags=["alertas"])

@router.post('/generar_stock')
def generar_stock_alertas(conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        cur.callproc('pkg_alertas.generar_alertas_stock', [])
        conn.commit()
        return {"status":"ok"}
    finally:
        cur.close()