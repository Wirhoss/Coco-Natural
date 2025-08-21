from fastapi import APIRouter, Depends
import oracledb
from db import get_db, rows_to_dicts

router = APIRouter(prefix="/cliente", tags=["cliente"])

@router.get("/", summary="List clients")
def list_clientes(conn=Depends(get_db)):
    cur = conn.cursor()
    result_cursor = None 
    try:
        out_cursor = cur.var(oracledb.DB_TYPE_CURSOR)
        cur.callproc("pkg_cliente.obtener_clientes", [out_cursor])
        result_cursor = out_cursor.getvalue()
        data = rows_to_dicts(result_cursor)
        return data
    finally:
        if result_cursor:
            result_cursor.close()
        cur.close()

@router.post("/", summary="Create client")
def create_cliente(payload: dict, conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        cur.callproc("pkg_cliente.insertar_cliente", [payload.get('nombre'), payload.get('telefono'), payload.get('email'), payload.get('direccion')])
        conn.commit()
        return {"status":"created"}
    finally:
        cur.close()

@router.put("/{id}", summary="Update client")
def update_cliente(id: int, payload: dict, conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        cur.callproc("pkg_cliente.actualizar_cliente", [id, payload.get('nombre'), payload.get('telefono'), payload.get('email'), payload.get('direccion')])
        conn.commit()
        return {"status":"updated"}
    finally:
        cur.close()

@router.delete("/{id}", summary="Delete client")
def delete_cliente(id: int, conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        cur.callproc("pkg_cliente.eliminar_cliente", [id])
        conn.commit()
        return {"status":"deleted"}
    finally:
        cur.close()