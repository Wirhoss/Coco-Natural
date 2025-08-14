from fastapi import APIRouter, Depends
import oracledb
from db import get_db, rows_to_dicts

router = APIRouter(prefix="/producto", tags=["producto"])

@router.get("/", summary="List productos")
def list_productos(conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        ref = cur.callfunc("pkg_producto.obtener_productos", oracledb.CURSOR)
        return rows_to_dicts(ref)
    finally:
        cur.close()

@router.post("/")
def create_producto(payload: dict, conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        cur.callproc("pkg_producto.insertar_producto", [payload.get('id_producto'), payload.get('nombre'), payload.get('descripcion'), payload.get('precio'), payload.get('stock_minimo'), payload.get('stock_actual'), payload.get('id_categoria'), payload.get('id_proveedor')])
        conn.commit()
        return {"status":"created"}
    finally:
        cur.close()

@router.get('/categoria/{id}')
def productos_por_categoria(id: int, conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        ref = cur.callfunc("pkg_producto.cur_productos_por_categoria", oracledb.CURSOR, [id])
        return rows_to_dicts(ref)
    finally:
        cur.close()

@router.put('/{id}')
def update_producto(id: int, payload: dict, conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        cur.callproc("pkg_producto.actualizar_producto", [id, payload.get('nombre'), payload.get('descripcion'), payload.get('precio'), payload.get('stock_minimo'), payload.get('stock_actual'), payload.get('id_categoria'), payload.get('id_proveedor')])
        conn.commit()
        return {"status":"updated"}
    finally:
        cur.close()

@router.delete('/{id}')
def delete_producto(id: int, conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        cur.callproc("pkg_producto.eliminar_producto", [id])
        conn.commit()
        return {"status":"deleted"}
    finally:
        cur.close()