# routers/auditoria.py
from fastapi import APIRouter, Depends
from db import get_db
from routers.common import call_func_cursor

router = APIRouter(prefix="/auditoria", tags=["auditoria"])

@router.get("/cambios")
def auditoria_cambios(days_back: int = 30, conn=Depends(get_db)):
    return call_func_cursor(conn, "pkg_auditoria.cur_auditoria_cambios", [days_back])
