from fastapi import FastAPI
from contextlib import asynccontextmanager
from db import get_db, get_conn

# Import routers
from routers.categoria import router as categoria_router
from routers.cliente import router as cliente_router
from routers.proveedor import router as proveedor_router
from routers.producto import router as producto_router
from routers.movimiento import router as movimiento_router
from routers.pedido import router as pedido_router
from routers.inventario import router as inventario_router
from routers.reportes import router as reportes_router
from routers.utilidades import router as utilidades_router
from routers.auditoria import router as auditoria_router
from routers.alertas import router as alertas_router

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Test database connection
    try:
        conn = get_conn()
        conn.close()
        print("✅ Database connection test successful")
    except Exception as e:
        print(f"❌ Database connection failed: {e}")
        raise
    
    yield
    
    # Shutdown
    print("🔄 Application shutting down")

# Initialize FastAPI app with lifespan context manager
app = FastAPI(
    title="Oracle PL/SQL Packages API",
    description="API wrapping Oracle PL/SQL packages for inventory management",
    version="1.0.0",
    lifespan=lifespan
)

# Include all routers
app.include_router(categoria_router)
app.include_router(cliente_router)
app.include_router(proveedor_router)
app.include_router(producto_router)
app.include_router(movimiento_router)
app.include_router(pedido_router)
app.include_router(inventario_router)
app.include_router(reportes_router)
app.include_router(utilidades_router)
app.include_router(auditoria_router)
app.include_router(alertas_router)

@app.get("/")
async def root():
    return {
        "status": "ok", 
        "message": "API wrapping PL/SQL packages",
        "version": "1.0.0"
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    try:
        # Test database connection
        conn = get_conn()
        conn.close()
        return {
            "status": "healthy",
            "database": "connected",
            "message": "All systems operational"
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "database": "disconnected",
            "error": str(e)
        }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )