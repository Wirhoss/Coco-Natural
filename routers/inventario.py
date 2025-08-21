# routers/inventario.py
from fastapi import APIRouter, Depends, Body
from db import get_db
from routers.common import call_proc, call_func_scalar
import oracledb

router = APIRouter(prefix="/inventario", tags=["inventario"])

@router.post("/actualizar-stock")
def actualizar_stock(
    id_producto: int = Body(...),
    cantidad: int = Body(...),
    tipo: str = Body(..., description="'entrada' o 'salida'"),
    conn=Depends(get_db)
):
    return call_proc(conn, "pkg_inventario.actualizar_stock", [id_producto, cantidad, tipo])

@router.post("/entrada")
def registrar_entrada(
    id_producto: int = Body(...),
    cantidad: int = Body(...),
    id_proveedor: int = Body(...),
    conn=Depends(get_db)
):
    return call_proc(conn, "pkg_inventario.registrar_entrada_inventario", [id_producto, cantidad, id_proveedor])

@router.get("/stock/{id_producto}")
def stock_disponible(id_producto: int, conn=Depends(get_db)):
    val = call_func_scalar(conn, "pkg_inventario.fn_stock_disponible", oracledb.NUMBER, [id_producto])
    return {"id_producto": id_producto, "stock": int(val) if val is not None else None}

@router.get("/validar/{id_producto}")
def validar_stock(id_producto: int, cantidad: int, conn=Depends(get_db)):
    val = call_func_scalar(conn, "pkg_inventario.fn_validar_stock", oracledb.NUMBER, [id_producto, cantidad])
    return {"id_producto": id_producto, "cantidad": cantidad, "valido": bool(val)}

@router.get("/porcentaje/{id_producto}")
def porcentaje_stock(id_producto: int, conn=Depends(get_db)):
    val = call_func_scalar(conn, "pkg_inventario.fn_porcentaje_stock", oracledb.NUMBER, [id_producto])
    return {"id_producto": id_producto, "porcentaje_minimo": float(val) if val is not None else None}

@router.post("/generar-alertas")
def generar_alertas(conn=Depends(get_db)):
    return call_proc(conn, "pkg_inventario.generar_alerta_stock", [])
