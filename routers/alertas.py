# routers/alertas.py
from fastapi import APIRouter, Depends
from db import get_db
from routers.common import call_proc

router = APIRouter(prefix="/alertas", tags=["alertas"])

@router.post("/generar-stock")
def generar_alertas_stock(conn=Depends(get_db)):
    return call_proc(conn, "pkg_alertas.generar_alertas_stock", [])
