from fastapi import APIRouter, Depends, HTTPException
from decimal import Decimal, InvalidOperation
import oracledb
from db import get_db, rows_to_dicts

router = APIRouter(prefix="/producto", tags=["producto"])

def to_int(v, field):
    try:
        return None if v is None else int(v)
    except (TypeError, ValueError):
        raise HTTPException(status_code=400, detail=f"{field} debe ser entero. Recibido: {v!r}")

def to_decimal(v, field):
    if v is None:
        return None
    s = str(v).strip().replace(",", ".")
    try:
        return Decimal(s)
    except (InvalidOperation, TypeError):
        raise HTTPException(status_code=400, detail=f"{field} debe ser decimal. Recibido: {v!r}")

@router.get("/", summary="List productos")
def list_productos(conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        ref = cur.callfunc("pkg_producto.obtener_productos", oracledb.CURSOR)
        return rows_to_dicts(ref)
    finally:
        cur.close()

@router.post("/", summary="Create producto")
def create_producto(payload: dict, conn=Depends(get_db)):
    from decimal import Decimal
    cur = conn.cursor()
    try:
        nombre        = payload.get("nombre")
        descripcion   = payload.get("descripcion")
        precio        = Decimal(str(payload.get("precio")).replace(",", ".")) if payload.get("precio") is not None else None
        stock_minimo  = int(payload["stock_minimo"]) if payload.get("stock_minimo") is not None else None
        stock_actual  = int(payload["stock_actual"]) if payload.get("stock_actual") is not None else None
        id_categoria  = int(payload["id_categoria"]) if payload.get("id_categoria") is not None else None
        id_proveedor  = int(payload["id_proveedor"]) if payload.get("id_proveedor") is not None else None
        usuario       = payload.get("usuario")

        if usuario:
            cur.callproc(
                "pkg_producto.insertar_producto",
                keyword_parameters=dict(
                    p_nombre=nombre,
                    p_descripcion=descripcion,
                    p_precio=precio,
                    p_stock_minimo=stock_minimo,
                    p_stock_actual=stock_actual,
                    p_id_categoria=id_categoria,
                    p_id_proveedor=id_proveedor,
                    p_usuario=usuario,
                ),
            )
        else:
            cur.callproc(
                "pkg_producto.insertar_producto",
                keyword_parameters=dict(
                    p_nombre=nombre,
                    p_descripcion=descripcion,
                    p_precio=precio,
                    p_stock_minimo=stock_minimo,
                    p_stock_actual=stock_actual,
                    p_id_categoria=id_categoria,
                    p_id_proveedor=id_proveedor,
                ),
            )

        conn.commit()
        return {"status": "created"}
    finally:
        cur.close()

@router.get('/categoria/{id}', summary="Productos por categoría")
def productos_por_categoria(id: int, conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        ref = cur.callfunc("pkg_producto.cur_productos_por_categoria", oracledb.CURSOR, [id])
        return rows_to_dicts(ref)
    finally:
        cur.close()

@router.put('/{id}', summary="Update producto")
def update_producto(id: int, payload: dict, conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        nombre        = payload.get("nombre")
        descripcion   = payload.get("descripcion")
        precio        = to_decimal(payload.get("precio"), "precio") if "precio" in payload else None
        stock_minimo  = to_int(payload.get("stock_minimo"), "stock_minimo") if "stock_minimo" in payload else None
        stock_actual  = to_int(payload.get("stock_actual"), "stock_actual") if "stock_actual" in payload else None
        id_categoria  = to_int(payload.get("id_categoria"), "id_categoria") if "id_categoria" in payload else None
        id_proveedor  = to_int(payload.get("id_proveedor"), "id_proveedor") if "id_proveedor" in payload else None

        cur.setinputsizes(
            oracledb.NUMBER,
            None,
            None,
            oracledb.NUMBER,
            oracledb.NUMBER,
            oracledb.NUMBER,
            oracledb.NUMBER,
            oracledb.NUMBER
        )

        cur.callproc("pkg_producto.actualizar_producto", [
            id, nombre, descripcion, precio, stock_minimo, stock_actual, id_categoria, id_proveedor
        ])
        conn.commit()
        return {"status": "updated"}
    finally:
        cur.close()

@router.delete('/{id}', summary="Delete producto")
def delete_producto(id: int, conn=Depends(get_db)):
    cur = conn.cursor()
    try:
        cur.callproc("pkg_producto.eliminar_producto", [id])
        conn.commit()
        return {"status":"deleted"}
    finally:
        cur.close()
