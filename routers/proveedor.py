from fastapi import APIRouter, Depends
import oracledb
from db import get_db, rows_to_dicts

router = APIRouter(prefix="/proveedor", tags=["proveedor"])

@router.get("/", summary="List proveedores")
def list_proveedores(conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        cur.callproc("pkg_proveedor.obtener_proveedores", [cur])
        return rows_to_dicts(cur)
    finally:
        cur.close()

@router.post("/", summary="Create proveedor")
def create_proveedor(payload: dict, conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        cur.callproc("pkg_proveedor.insertar_proveedor", [payload.get('id_proveedor'), payload.get('nombre'), payload.get('telefono'), payload.get('email'), payload.get('direccion')])
        conn.commit()
        return {"status":"created"}
    finally:
        cur.close()

@router.put("/{id}")
def update_proveedor(id: int, payload: dict, conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        cur.callproc("pkg_proveedor.actualizar_proveedor", [id, payload.get('nombre'), payload.get('telefono'), payload.get('email'), payload.get('direccion')])
        conn.commit()
        return {"status":"updated"}
    finally:
        cur.close()

@router.delete("/{id}")
def delete_proveedor(id: int, conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        cur.callproc("pkg_proveedor.eliminar_proveedor", [id])
        conn.commit()
        return {"status":"deleted"}
    finally:
        cur.close()