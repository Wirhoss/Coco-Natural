from fastapi import APIRouter, Depends, HTTPException
import oracledb
from db import get_db, rows_to_dicts

router = APIRouter(prefix="/categoria", tags=["categoria"])

@router.get("/", summary="List categories")
def list_categorias(conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        ref = cur.callfunc("pkg_categoria.obtener_categorias", oracledb.CURSOR)
        data = rows_to_dicts(ref)
        return data
    finally:
        cur.close()

@router.post("/", summary="Create category")
def create_categoria(payload: dict, conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        cur.callproc("pkg_categoria.insertar_categoria", [payload.get("id_categoria"), payload.get("nombre"), payload.get("descripcion")])
        conn.commit()
        return {"status":"created"}
    finally:
        cur.close()

@router.put("/{id}", summary="Update category")
def update_categoria(id: int, payload: dict, conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        cur.callproc("pkg_categoria.actualizar_categoria", [id, payload.get("nombre"), payload.get("descripcion")])
        conn.commit()
        return {"status":"updated"}
    finally:
        cur.close()

@router.delete("/{id}", summary="Delete category")
def delete_categoria(id: int, conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        cur.callproc("pkg_categoria.eliminar_categoria", [id])
        conn.commit()
        return {"status":"deleted"}
    finally:
        cur.close()
