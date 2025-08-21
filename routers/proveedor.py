from fastapi import APIRouter, Depends, Body
from db import get_db
from routers.common import exec_named_proc_omit_defaults, call_proc, call_proc_out_cursor, call_func_cursor, call_func_scalar
import oracledb

router = APIRouter(prefix="/proveedor", tags=["proveedor"])

@router.get("")
def listar(conn=Depends(get_db)):
    return call_proc_out_cursor(conn, "pkg_proveedor.obtener_proveedores", [])

@router.post("")
def crear(
    nombre: str = Body(...),
    telefono: str | None = Body(None),
    email: str = Body(...),
    direccion: str = Body(...),
    conn=Depends(get_db)
):
    return exec_named_proc_omit_defaults(conn, "pkg_proveedor", "insertar_proveedor", {
        "p_nombre": nombre,
        "p_telefono": telefono,
        "p_email": email,
        "p_direccion": direccion
    })

@router.put("/{id_proveedor}")
def actualizar(
    id_proveedor: int,
    nombre: str | None = Body(None),
    telefono: str | None = Body(None),
    email: str | None = Body(None),
    direccion: str | None = Body(None),
    conn=Depends(get_db)
):
    return call_proc(conn, "pkg_proveedor.actualizar_proveedor",
                     [id_proveedor, nombre, telefono, email, direccion])

@router.delete("/{id_proveedor}")
def eliminar(id_proveedor: int, conn=Depends(get_db)):
    return call_proc(conn, "pkg_proveedor.eliminar_proveedor", [id_proveedor])

@router.get("/{id_proveedor}/productos")
def productos_proveedor(id_proveedor: int, conn=Depends(get_db)):
    return call_func_cursor(conn, "pkg_proveedor.cur_productos_proveedor", [id_proveedor])

@router.get("/{id_proveedor}/productos/count")
def contar_productos(id_proveedor: int, conn=Depends(get_db)):
    val = call_func_scalar(conn, "pkg_proveedor.fn_contar_productos_proveedor", oracledb.NUMBER, [id_proveedor])
    return {"id_proveedor": id_proveedor, "total_productos": int(val) if val is not None else None}

@router.get("/stock-bajo")
def proveedores_con_stock_bajo(conn=Depends(get_db)):
    return call_func_cursor(conn, "pkg_proveedor.cur_proveedores_con_stock_bajo", [])
