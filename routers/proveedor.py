from fastapi import APIRouter, Depends, HTTPException
import oracledb
from db import get_db, rows_to_dicts

router = APIRouter(prefix="/proveedor", tags=["proveedor"])

@router.get("/", summary="List proveedores")
def list_proveedores(conn=Depends(get_db)):
    cur = conn.cursor()
    try:

        out_rc = cur.var(oracledb.CURSOR)
        cur.callproc("pkg_proveedor.obtener_proveedores", [out_rc])

        db_rcur = out_rc.getvalue()

        return rows_to_dicts(db_rcur)

    except oracledb.Error as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cur.close()

@router.post("/", summary="Create proveedor")
def create_proveedor(payload: dict, conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        cur.callproc(
            "pkg_proveedor.insertar_proveedor",
            [
                payload.get("nombre"),
                payload.get("telefono"),
                payload.get("email"),
                payload.get("direccion"),
            ],
        )
        conn.commit()
        return {"status": "created"}
    except oracledb.Error as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cur.close()

@router.put("/{id}", summary="Update proveedor")
def update_proveedor(id: int, payload: dict, conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        cur.callproc(
            "pkg_proveedor.actualizar_proveedor",
            [
                id,
                payload.get("nombre"),
                payload.get("telefono"),
                payload.get("email"),
                payload.get("direccion"),
            ],
        )
        conn.commit()
        return {"status": "updated"}
    except oracledb.Error as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cur.close()

@router.delete("/{id}", summary="Delete proveedor")
def delete_proveedor(id: int, conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        cur.callproc("pkg_proveedor.eliminar_proveedor", [id])
        conn.commit()
        return {"status": "deleted"}
    except oracledb.Error as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        cur.close()
