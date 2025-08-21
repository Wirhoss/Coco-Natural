from fastapi import APIRouter, Depends, Body
from db import get_db
from routers.common import exec_named_proc_omit_defaults ,call_proc, call_func_cursor, call_func_scalar
import oracledb

router = APIRouter(prefix="/producto", tags=["producto"])

@router.get("")
def listar(conn=Depends(get_db)):
    return call_func_cursor(conn, "pkg_producto.obtener_productos")

@router.post("")
def crear(
    nombre: str = Body(...),
    descripcion: str | None = Body(None),
    precio: float = Body(...),
    stock_minimo: int = Body(...),
    stock_actual: int = Body(...),
    id_categoria: int = Body(...),
    id_proveedor: int = Body(...),
    conn=Depends(get_db)
):
    return exec_named_proc_omit_defaults(conn, "pkg_producto", "insertar_producto", {
        "p_nombre": nombre,
        "p_descripcion": descripcion,
        "p_precio": precio,
        "p_stock_minimo": stock_minimo,
        "p_stock_actual": stock_actual,
        "p_id_categoria": id_categoria,
        "p_id_proveedor": id_proveedor
    })


@router.put("/{id_producto}")
def actualizar(
    id_producto: int,
    nombre: str | None = Body(None),
    descripcion: str | None = Body(None),
    precio: float | None = Body(None),
    stock_minimo: int | None = Body(None),
    stock_actual: int | None = Body(None),
    id_categoria: int | None = Body(None),
    id_proveedor: int | None = Body(None),
    conn=Depends(get_db)
):
    return call_proc(conn, "pkg_producto.actualizar_producto",
                     [id_producto, nombre, descripcion, precio, stock_minimo, stock_actual, id_categoria, id_proveedor])

@router.delete("/{id_producto}")
def eliminar(id_producto: int, conn=Depends(get_db)):
    return call_proc(conn, "pkg_producto.eliminar_producto", [id_producto])

@router.get("/{id_producto}/nombre")
def nombre_producto(id_producto: int, conn=Depends(get_db)):
    val = call_func_scalar(conn, "pkg_producto.fn_obtener_nombre_producto", oracledb.STRING, [id_producto])
    return {"id_producto": id_producto, "nombre": val}

@router.get("/categoria/{id_categoria}")
def productos_por_categoria(id_categoria: int, conn=Depends(get_db)):
    return call_func_cursor(conn, "pkg_producto.cur_productos_por_categoria", [id_categoria])

@router.get("/sin-movimientos")
def productos_sin_movimientos(dias: int = 30, conn=Depends(get_db)):
    return call_func_cursor(conn, "pkg_producto.cur_productos_sin_movimientos", [dias])

@router.get("/precio-promedio/{id_categoria}")
def precio_promedio_categoria(id_categoria: int, conn=Depends(get_db)):
    val = call_func_scalar(conn, "pkg_producto.fn_precio_promedio_categoria", oracledb.NUMBER, [id_categoria])
    return {"id_categoria": id_categoria, "precio_promedio": float(val) if val is not None else None}
