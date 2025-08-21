# routers/pedido.py
from fastapi import APIRouter, Depends, Body
from db import get_db
from routers.common import call_proc, call_func_cursor, call_func_scalar
import oracledb

router = APIRouter(prefix="/pedido", tags=["pedido"])

@router.post("/{id_pedido}/procesar")
def procesar(id_pedido: int, conn=Depends(get_db)):
    return call_proc(conn, "pkg_pedido.procesar_pedido", [id_pedido])

@router.post("/{id_pedido}/recalcular-total")
def recalcular_total(id_pedido: int, conn=Depends(get_db)):
    return call_proc(conn, "pkg_pedido.calcular_total_pedido", [id_pedido])

@router.get("/{id_pedido}/detalle-completo")
def detalle_completo(id_pedido: int, conn=Depends(get_db)):
    return call_func_cursor(conn, "pkg_pedido.cur_detalle_pedido_completo", [id_pedido])

@router.get("/codigo/nuevo")
def generar_codigo(conn=Depends(get_db)):
    code = call_func_scalar(conn, "pkg_pedido.fn_generar_codigo_pedido", oracledb.STRING, [])
    return {"codigo": code}

@router.get("/cliente/{id_cliente}/total-compras")
def total_compras(id_cliente: int, conn=Depends(get_db)):
    val = call_func_scalar(conn, "pkg_pedido.fn_total_compras_cliente", oracledb.NUMBER, [id_cliente])
    return {"id_cliente": id_cliente, "total_compras": float(val) if val is not None else None}

@router.get("/entrega/promedio")
def dias_entrega_promedio(id_pedido: int | None = None, conn=Depends(get_db)):
    args = [id_pedido] if id_pedido is not None else [None]
    val = call_func_scalar(conn, "pkg_pedido.fn_dias_entrega_promedio", oracledb.NUMBER, args)
    return {"id_pedido": id_pedido, "dias": float(val) if val is not None else None}
