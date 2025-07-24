Para instalar los paquetes necesarios en python:

1. https://visualstudio.microsoft.com/visual-cpp-build-tools/
2. pip install -r /path/to/requirements.txt


Lista de cosas por hacer:
25 Procedimientos Almacenados

CRUD Básico (5 tablas × 4 operaciones = 20):
  insertar_producto (PRODUCTO)
  actualizar_producto (PRODUCTO)
  eliminar_producto (PRODUCTO)
  obtener_productos (PRODUCTO)
  insertar_categoria (CATEGORIA)
  actualizar_categoria (CATEGORIA)
  eliminar_categoria (CATEGORIA)
  obtener_categorias (CATEGORIA)
  insertar_movimiento (MOVIMIENTOS)
  actualizar_movimiento (MOVIMIENTOS)
  eliminar_movimiento (MOVIMIENTOS)
  obtener_movimientos (MOVIMIENTOS)
  insertar_proveedor (PROVEEDOR)
  actualizar_proveedor (PROVEEDOR)
  eliminar_proveedor (PROVEEDOR)
  obtener_proveedores (PROVEEDOR)
  insertar_cliente (CLIENTE)
  actualizar_cliente (CLIENTE)
  eliminar_cliente (CLIENTE)
  obtener_clientes (CLIENTE)

Lógica de Negocio (5):
  actualizar_stock (después de movimiento)
  calcular_total_pedido (PEDIDO + DETALLE)
  generar_alerta_stock (notificar stock < mínimo)
  procesar_pedido (validar stock + actualizar)
  registrar_entrada_inventario (MOVIMIENTOS + PRODUCTO)

10 Vistas
Reportes Críticos:
  vw_stock_critico (PRODUCTO: stock_actual < stock_minimo)
  vw_ventas_mensuales (PEDIDO + DETALLE agrupado por mes)
  vw_top_productos (productos más vendidos)
  vw_pedidos_pendientes (PEDIDO con estado "pendiente")
  vw_proveedores_productos (PROVEEDOR + PRODUCTO)
  vw_clientes_frecuentes (CLIENTE + conteo de PEDIDO)
  vw_movimientos_recientes (MOVIMIENTOS últimos 30 días)
  vw_inventario_completo (PRODUCTO + CATEGORIA + stock)
  vw_total_ventas_categoria (CATEGORIA + ventas totales)
  vw_detalle_pedidos (PEDIDO + DETALLE + CLIENTE)

15 Funciones
Cálculos y Validaciones:
  fn_calcular_subtotal (cantidad * precio)
  fn_stock_disponible (PRODUCTO)
  fn_validar_stock (producto_id, cantidad) → BOOLEAN
  fn_contar_pedidos_cliente (CLIENTE)
  fn_total_ventas_mes (mes, año)
  fn_precio_promedio_categoria (CATEGORIA)
  fn_obtener_nombre_producto (PRODUCTO)
  fn_obtener_nombre_proveedor (PROVEEDOR)
  fn_contar_productos_proveedor (PROVEEDOR)
  fn_calcular_edad_cliente (CLIENTE - si hay fecha_nacimiento)
  fn_dias_entrega_promedio (PEDIDO)
  fn_porcentaje_stock (stock_actual / stock_minimo)
  fn_generar_codigo_pedido (secuencia + año)
  fn_contar_movimientos_tipo (MOVIMIENTOS: "entrada"/"salida")
  fn_total_compras_cliente (CLIENTE)

10 Paquetes

Agrupación Lógica:
  pkg_productos (CRUD + stock)
  pkg_inventario (movimientos + alertas)
  pkg_pedidos (pedidos + detalles)
  pkg_clientes (CRUD + reportes)
  pkg_proveedores (CRUD + productos asociados)
  pkg_reportes (funciones de vistas complejas)
  pkg_seguridad (validación de usuarios)
  pkg_utilidades (funciones de formato/conversión)
  pkg_auditoria (triggers de registro)
  pkg_validaciones (reglas de negocio)

5 Triggers
Automatización/Auditoría:
  trg_actualizar_stock (después de INSERT en MOVIMIENTOS)
  trg_auditar_productos (después de UPDATE/DELETE en PRODUCTO)
  trg_validar_pedido (antes de INSERT en DETALLE_PEDIDO - stock suficiente)
  trg_generar_codigo (antes de INSERT en PEDIDO - código único)
  trg_actualizar_total_pedido (después de INSERT/UPDATE/DELETE en DETALLE_PEDIDO)

15 Cursores
Manejo de Conjuntos de Datos:
    cur_productos_por_categoria (PRODUCTO filtrado por CATEGORIA)
    cur_pedidos_por_cliente (PEDIDO + CLIENTE)
    cur_movimientos_por_producto (MOVIMIENTOS + PRODUCTO)
    cur_proveedores_con_stock_bajo (PROVEEDOR + PRODUCTO con stock crítico)
    cur_clientes_sin_pedidos (CLIENTE sin PEDIDO en últimos 6 meses)
    cur_ventas_por_mes (agrupación mensual)
    cur_productos_sin_movimientos (PRODUCTO sin MOVIMIENTOS en 30 días)
    cur_detalle_pedido_completo (DETALLE + PRODUCTO + PEDIDO)
    cur_auditoria_cambios (registros de AUDITORIA)
    cur_stock_por_categoria (PRODUCTO agrupado por CATEGORIA)
    cur_pedidos_urgentes (PEDIDO con fecha_entrega próxima)
    cur_productos_proveedor (PRODUCTO por PROVEEDOR)
    cur_total_ventas_anual (ventas por año)
    cur_clientes_top (CLIENTE ordenado por monto comprado)
    cur_movimientos_invalidos (MOVIMIENTOS con cantidad negativa)