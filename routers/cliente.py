# routers/cliente.py
from fastapi import APIRouter, Depends, Body
from db import get_db
from routers.common import call_proc_out_cursor, exec_named_proc_omit_defaults, call_proc, call_func_scalar
import oracledb

router = APIRouter(prefix="/cliente", tags=["cliente"])

@router.get("")
def listar_clientes(conn=Depends(get_db)):
    return call_proc_out_cursor(conn, "pkg_cliente.obtener_clientes", [])

@router.post("")
def crear_cliente(
    nombre: str = Body(...),
    telefono: str = Body(...),
    email: str = Body(...),
    direccion: str = Body(...),
    conn=Depends(get_db)
):
    return exec_named_proc_omit_defaults(conn, "pkg_cliente", "insertar_cliente", {
        "p_nombre": nombre,
        "p_telefono": telefono,
        "p_email": email,
        "p_direccion": direccion
    })

@router.put("/{id_cliente}")
def actualizar_cliente(
    id_cliente: int,
    nombre: str | None = Body(None),
    telefono: str | None = Body(None),
    email: str | None = Body(None),
    direccion: str | None = Body(None),
    conn=Depends(get_db)
):
    args = [id_cliente, nombre, telefono, email, direccion]
    return call_proc(conn, "pkg_cliente.actualizar_cliente", args)

@router.delete("/{id_cliente}")
def eliminar_cliente(id_cliente: int, conn=Depends(get_db)):
    return call_proc(conn, "pkg_cliente.eliminar_cliente", [id_cliente])

@router.get("/{id_cliente}/pedidos")
def pedidos_por_cliente(id_cliente: int, conn=Depends(get_db)):
    return call_func_cursor(conn, "pkg_cliente.cur_pedidos_por_cliente", [id_cliente])

@router.get("/{id_cliente}/pedidos/count")
def contar_pedidos(id_cliente: int, conn=Depends(get_db)):
    val = call_func_scalar(conn, "pkg_cliente.fn_contar_pedidos_cliente", oracledb.NUMBER, [id_cliente])
    return {"id_cliente": id_cliente, "total_pedidos": int(val) if val is not None else None}

@router.get("/{id_cliente}/edad")
def edad_cliente(id_cliente: int, conn=Depends(get_db)):
    val = call_func_scalar(conn, "pkg_cliente.fn_calcular_edad_cliente", oracledb.NUMBER, [id_cliente])
    return {"id_cliente": id_cliente, "edad": int(val) if val is not None else None}
