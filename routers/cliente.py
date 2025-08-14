from fastapi import APIRouter, Depends
import oracledb
from db import get_db, rows_to_dicts

router = APIRouter(prefix="/cliente", tags=["cliente"])

@router.get("/", summary="List clients")
def list_clientes(conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        cur.callproc("pkg_cliente.obtener_clientes", [cur])
        # When procedure returns via OUT cursor param, procedure was defined that way in original; in our package we used a procedure with OUT param
        # But to keep compatibility if it was function returning cursor, fallback to callfunc
        try:
            data = rows_to_dicts(cur)
            return data
        except Exception:
            # fallback assuming function
            ref = cur.callfunc("pkg_cliente.cur_pedidos_por_cliente", oracledb.CURSOR, [0])
            return rows_to_dicts(ref)
    finally:
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