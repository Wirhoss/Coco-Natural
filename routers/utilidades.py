from fastapi import APIRouter, Depends
from db import get_db
from routers.common import call_func_scalar
import oracledb

router = APIRouter(prefix="/utilidades", tags=["utilidades"])

@router.get("/subtotal")
def calcular_subtotal(cantidad: float, precio: float, conn=Depends(get_db)):
    val = call_func_scalar(conn, "pkg_utilidades.fn_calcular_subtotal", oracledb.NUMBER, [cantidad, precio])
    return {"cantidad": cantidad, "precio": precio, "subtotal": float(val)}

@router.get("/codigo-pedido/nuevo")
def generar_codigo_pedido(conn=Depends(get_db)):
    val = call_func_scalar(conn, "pkg_utilidades.fn_generar_codigo_pedido", oracledb.STRING, [])
    return {"codigo": val}
