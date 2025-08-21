# routers/categoria.py
from fastapi import APIRouter, Depends, Body
from db import get_db
from routers.common import call_func_cursor, exec_named_proc_omit_defaults, call_proc
import oracledb

router = APIRouter(prefix="/categoria", tags=["categoria"])

@router.get("")
def listar_categorias(conn=Depends(get_db)):
    return call_func_cursor(conn, "pkg_categoria.obtener_categorias")

@router.post("")
def crear_categoria(
    nombre: str = Body(...),
    descripcion: str | None = Body(None),
    conn=Depends(get_db)
):
    return exec_named_proc_omit_defaults(conn, "pkg_categoria", "insertar_categoria", {
        "p_nombre": nombre,
        "p_descripcion": descripcion
    })

@router.put("/{id_categoria}")
def actualizar_categoria(
    id_categoria: int,
    nombre: str | None = Body(None),
    descripcion: str | None = Body(None),
    conn=Depends(get_db)
):
    args = [id_categoria, nombre, descripcion]
    return call_proc(conn, "pkg_categoria.actualizar_categoria", args)

@router.delete("/{id_categoria}")
def eliminar_categoria(id_categoria: int, conn=Depends(get_db)):
    return call_proc(conn, "pkg_categoria.eliminar_categoria", [id_categoria])
