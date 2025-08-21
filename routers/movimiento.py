# routers/movimiento.py
from fastapi import APIRouter, Depends, Body
from db import get_db
from routers.common import call_proc, call_func_cursor, call_func_scalar, exec_named_proc_omit_defaults
import oracledb

router = APIRouter(prefix="/movimiento", tags=["movimiento"])

@router.get("")
def listar(conn=Depends(get_db)):
    return call_func_cursor(conn, "pkg_movimiento.obtener_movimientos", [])

@router.post("")
def crear(
    tipo: str = Body(..., description="entrada|salida"),
    cantidad: int = Body(..., gt=0),
    id_producto: int = Body(...),
    conn=Depends(get_db)
):
    return exec_named_proc_omit_defaults(conn, "pkg_movimiento", "insertar_movimiento", {
        "p_tipo": tipo, "p_cantidad": cantidad, "p_id_producto": id_producto
    })

@router.put("/{id_movimiento}")
def actualizar(
    id_movimiento: int,
    tipo: str | None = Body(None),
    cantidad: int | None = Body(None),
    id_producto: int | None = Body(None),
    conn=Depends(get_db)
):
    return call_proc(conn, "pkg_movimiento.actualizar_movimiento",
                     [id_movimiento, tipo, cantidad, id_producto])

@router.delete("/{id_movimiento}")
def eliminar(id_movimiento: int, conn=Depends(get_db)):
    return call_proc(conn, "pkg_movimiento.eliminar_movimiento", [id_movimiento])

@router.get("/producto/{id_producto}")
def por_producto(id_producto: int, conn=Depends(get_db)):
    return call_func_cursor(conn, "pkg_movimiento.cur_movimientos_por_producto", [id_producto])

@router.get("/invalidos")
def invalidos(conn=Depends(get_db)):
    return call_func_cursor(conn, "pkg_movimiento.cur_movimientos_invalidos", [])

@router.get("/count")
def contar(tipo: str | None = None, conn=Depends(get_db)):
    val = call_func_scalar(conn, "pkg_movimiento.fn_contar_movimientos_tipo", oracledb.NUMBER, [tipo])
    return {"tipo": tipo, "total": int(val) if val is not None else None}
