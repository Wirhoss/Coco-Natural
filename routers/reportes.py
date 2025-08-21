from fastapi import APIRouter, Depends
from db import get_db
from routers.common import call_func_cursor

router = APIRouter(prefix="/reportes", tags=["reportes"])

@router.get("/ventas-por-mes/{anio}")
def ventas_por_mes(anio: int, conn=Depends(get_db)):
    return call_func_cursor(conn, "pkg_reportes.cur_ventas_por_mes", [anio])

@router.get("/total-ventas-anual/{anio}")
def total_ventas_anual(anio: int, conn=Depends(get_db)):
    return call_func_cursor(conn, "pkg_reportes.cur_total_ventas_anual", [anio])

@router.get("/clientes-sin-pedidos")
def clientes_sin_pedidos(meses: int = 6, conn=Depends(get_db)):
    return call_func_cursor(conn, "pkg_reportes.cur_clientes_sin_pedidos", [meses])

@router.get("/clientes-top")
def clientes_top(limit: int = 10, conn=Depends(get_db)):
    return call_func_cursor(conn, "pkg_reportes.cur_clientes_top", [limit])

@router.get("/pedidos-urgentes")
def pedidos_urgentes(dias_adelante: int = 7, conn=Depends(get_db)):
    return call_func_cursor(conn, "pkg_reportes.cur_pedidos_urgentes", [dias_adelante])

@router.get("/stock-por-categoria")
def stock_por_categoria(conn=Depends(get_db)):
    return call_func_cursor(conn, "pkg_reportes.cur_stock_por_categoria", [])

@router.get("/productos-sin-movimientos")
def productos_sin_movimientos(dias: int = 30, conn=Depends(get_db)):
    return call_func_cursor(conn, "pkg_reportes.cur_productos_sin_movimientos", [dias])
