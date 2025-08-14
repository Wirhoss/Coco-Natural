CREATE OR REPLACE PACKAGE pkg_cursores IS
  -- 1) PRODUCTO filtrado por CATEGORIA
  FUNCTION cur_productos_por_categoria(p_id_categoria IN NUMBER) RETURN SYS_REFCURSOR;

  -- 2) PEDIDO + CLIENTE por cliente
  FUNCTION cur_pedidos_por_cliente(p_id_cliente IN NUMBER) RETURN SYS_REFCURSOR;

  -- 3) MOVIMIENTOS por producto
  FUNCTION cur_movimientos_por_producto(p_id_producto IN NUMBER) RETURN SYS_REFCURSOR;

  -- 4) PROVEEDORES con productos en stock critico (stock_actual < stock_minimo)
  FUNCTION cur_proveedores_con_stock_bajo RETURN SYS_REFCURSOR;

  -- 5) CLIENTES sin pedidos en los últimos N meses (default 6)
  FUNCTION cur_clientes_sin_pedidos(p_meses IN NUMBER DEFAULT 6) RETURN SYS_REFCURSOR;

  -- 6) VENTAS por mes (agrupación mensual) para un año dado
  FUNCTION cur_ventas_por_mes(p_anio IN NUMBER) RETURN SYS_REFCURSOR;

  -- 7) PRODUCTOS sin movimientos en N días (default 30)
  FUNCTION cur_productos_sin_movimientos(p_dias IN NUMBER DEFAULT 30) RETURN SYS_REFCURSOR;

  -- 8) DETALLE_PEDIDO completo (detalle + producto + pedido) por pedido
  FUNCTION cur_detalle_pedido_completo(p_id_pedido IN NUMBER) RETURN SYS_REFCURSOR;

  -- 9) AUDITORIA de movimientos recientes (auditoria_movimientos)
  FUNCTION cur_auditoria_cambios(p_days_back IN NUMBER DEFAULT 30) RETURN SYS_REFCURSOR;

  -- 10) STOCK por CATEGORIA (agrupado)
  FUNCTION cur_stock_por_categoria RETURN SYS_REFCURSOR;

  -- 11) PEDIDOS urgentes (fecha_entrega dentro de N días, default 7)
  FUNCTION cur_pedidos_urgentes(p_dias_adelante IN NUMBER DEFAULT 7) RETURN SYS_REFCURSOR;

  -- 12) PRODUCTOS por PROVEEDOR
  FUNCTION cur_productos_proveedor(p_id_proveedor IN NUMBER) RETURN SYS_REFCURSOR;

  -- 13) TOTAL VENTAS anual (por año)
  FUNCTION cur_total_ventas_anual(p_anio IN NUMBER) RETURN SYS_REFCURSOR;

  -- 14) CLIENTES top por monto comprado (limit DEFAULT 10)
  FUNCTION cur_clientes_top(p_limit IN NUMBER DEFAULT 10) RETURN SYS_REFCURSOR;

  -- 15) MOVIMIENTOS inválidos (cantidad <= 0)
  FUNCTION cur_movimientos_invalidos RETURN SYS_REFCURSOR;
END pkg_cursores;


CREATE OR REPLACE PACKAGE BODY pkg_cursores IS

  FUNCTION cur_productos_por_categoria(p_id_categoria IN NUMBER) RETURN SYS_REFCURSOR IS
    rc SYS_REFCURSOR;
  BEGIN
    OPEN rc FOR
      SELECT p.*
        FROM producto p
       WHERE p.id_categoria = p_id_categoria;
    RETURN rc;
  END cur_productos_por_categoria;

  FUNCTION cur_pedidos_por_cliente(p_id_cliente IN NUMBER) RETURN SYS_REFCURSOR IS
    rc SYS_REFCURSOR;
  BEGIN
    OPEN rc FOR
      SELECT o.*, c.nombre AS cliente_nombre, c.email AS cliente_email
        FROM pedido o
        JOIN cliente c ON o.id_cliente = c.id_cliente
       WHERE o.id_cliente = p_id_cliente
       ORDER BY o.fecha_pedido DESC;
    RETURN rc;
  END cur_pedidos_por_cliente;

  FUNCTION cur_movimientos_por_producto(p_id_producto IN NUMBER) RETURN SYS_REFCURSOR IS
    rc SYS_REFCURSOR;
  BEGIN
    OPEN rc FOR
      SELECT m.*, p.nombre AS producto_nombre, p.stock_actual
        FROM movimientos m
        JOIN producto p ON m.id_producto = p.id_producto
       WHERE m.id_producto = p_id_producto
       ORDER BY m.fecha DESC;
    RETURN rc;
  END cur_movimientos_por_producto;

  FUNCTION cur_proveedores_con_stock_bajo RETURN SYS_REFCURSOR IS
    rc SYS_REFCURSOR;
  BEGIN
    OPEN rc FOR
      SELECT pr.id_proveedor, pr.nombre AS proveedor_nombre, p.id_producto, p.nombre AS producto_nombre,
             p.stock_actual, p.stock_minimo
        FROM proveedor pr
        JOIN producto p ON p.id_proveedor = pr.id_proveedor
       WHERE p.stock_actual < p.stock_minimo
       ORDER BY pr.nombre, p.nombre;
    RETURN rc;
  END cur_proveedores_con_stock_bajo;

  FUNCTION cur_clientes_sin_pedidos(p_meses IN NUMBER DEFAULT 6) RETURN SYS_REFCURSOR IS
    rc SYS_REFCURSOR;
    v_cutoff DATE := ADD_MONTHS(TRUNC(SYSDATE), -p_meses);
  BEGIN
    OPEN rc FOR
      SELECT c.*
        FROM cliente c
       WHERE NOT EXISTS (
             SELECT 1 FROM pedido o WHERE o.id_cliente = c.id_cliente
               AND o.fecha_pedido >= v_cutoff
           )
       ORDER BY c.nombre;
    RETURN rc;
  END cur_clientes_sin_pedidos;

  FUNCTION cur_ventas_por_mes(p_anio IN NUMBER) RETURN SYS_REFCURSOR IS
    rc SYS_REFCURSOR;
  BEGIN
    OPEN rc FOR
      SELECT TO_CHAR(TRUNC(o.fecha_pedido,'MM'),'YYYY-MM') AS mes,
             EXTRACT(MONTH FROM o.fecha_pedido) AS numero_mes,
             COUNT(d.id_detalle) AS cantidad_items,
             NVL(SUM(d.subtotal),0) AS total_ventas
        FROM pedido o
        JOIN detalle_pedido d ON d.id_pedido = o.id_pedido
       WHERE EXTRACT(YEAR FROM o.fecha_pedido) = p_anio
       GROUP BY TRUNC(o.fecha_pedido,'MM')
       ORDER BY TRUNC(o.fecha_pedido,'MM');
    RETURN rc;
  END cur_ventas_por_mes;

  FUNCTION cur_productos_sin_movimientos(p_dias IN NUMBER DEFAULT 30) RETURN SYS_REFCURSOR IS
    rc SYS_REFCURSOR;
    v_cutoff TIMESTAMP := SYSTIMESTAMP - NUMTODSINTERVAL(p_dias,'DAY');
  BEGIN
    OPEN rc FOR
      SELECT p.*
        FROM producto p
       WHERE NOT EXISTS (
         SELECT 1 FROM movimientos m WHERE m.id_producto = p.id_producto AND m.fecha >= v_cutoff
       )
       ORDER BY p.nombre;
    RETURN rc;
  END cur_productos_sin_movimientos;

  FUNCTION cur_detalle_pedido_completo(p_id_pedido IN NUMBER) RETURN SYS_REFCURSOR IS
    rc SYS_REFCURSOR;
  BEGIN
    OPEN rc FOR
      SELECT dp.*, pr.nombre AS producto_nombre, pr.descripcion AS producto_descripcion,
             o.fecha_pedido, o.fecha_entrega, o.estado, o.total,
             c.nombre AS cliente_nombre, c.email AS cliente_email
        FROM detalle_pedido dp
        JOIN producto pr ON dp.id_producto = pr.id_producto
        JOIN pedido o ON dp.id_pedido = o.id_pedido
        JOIN cliente c ON o.id_cliente = c.id_cliente
       WHERE dp.id_pedido = p_id_pedido
       ORDER BY dp.id_detalle;
    RETURN rc;
  END cur_detalle_pedido_completo;

  FUNCTION cur_auditoria_cambios(p_days_back IN NUMBER DEFAULT 30) RETURN SYS_REFCURSOR IS
    rc SYS_REFCURSOR;
    v_cutoff TIMESTAMP := SYSTIMESTAMP - NUMTODSINTERVAL(p_days_back,'DAY');
  BEGIN
    OPEN rc FOR
      SELECT am.id_auditoria, am.id_movimiento, am.fecha_auditoria, am.usuario, am.accion
        FROM auditoria_movimientos am
       WHERE am.fecha_auditoria >= v_cutoff
       ORDER BY am.fecha_auditoria DESC;
    RETURN rc;
  END cur_auditoria_cambios;

  FUNCTION cur_stock_por_categoria RETURN SYS_REFCURSOR IS
    rc SYS_REFCURSOR;
  BEGIN
    OPEN rc FOR
      SELECT c.id_categoria, c.nombre AS categoria_nombre,
             NVL(SUM(p.stock_actual),0) AS stock_total,
             NVL(SUM(p.stock_minimo),0) AS stock_minimo_total,
             COUNT(p.id_producto) AS productos_count
        FROM categoria c
        LEFT JOIN producto p ON p.id_categoria = c.id_categoria
       GROUP BY c.id_categoria, c.nombre
       ORDER BY c.nombre;
    RETURN rc;
  END cur_stock_por_categoria;

  FUNCTION cur_pedidos_urgentes(p_dias_adelante IN NUMBER DEFAULT 7) RETURN SYS_REFCURSOR IS
    rc SYS_REFCURSOR;
    v_cutoff DATE := TRUNC(SYSDATE) + p_dias_adelante;
  BEGIN
    OPEN rc FOR
      SELECT o.*, c.nombre AS cliente_nombre, c.telefono
        FROM pedido o
        JOIN cliente c ON o.id_cliente = c.id_cliente
       WHERE o.fecha_entrega IS NOT NULL
         AND TRUNC(o.fecha_entrega) <= v_cutoff
         AND o.estado = 'pendiente'
       ORDER BY o.fecha_entrega ASC;
    RETURN rc;
  END cur_pedidos_urgentes;

  FUNCTION cur_productos_proveedor(p_id_proveedor IN NUMBER) RETURN SYS_REFCURSOR IS
    rc SYS_REFCURSOR;
  BEGIN
    OPEN rc FOR
      SELECT p.*
        FROM producto p
       WHERE p.id_proveedor = p_id_proveedor
       ORDER BY p.nombre;
    RETURN rc;
  END cur_productos_proveedor;

  FUNCTION cur_total_ventas_anual(p_anio IN NUMBER) RETURN SYS_REFCURSOR IS
    rc SYS_REFCURSOR;
  BEGIN
    OPEN rc FOR
      SELECT EXTRACT(MONTH FROM o.fecha_pedido) AS mes,
             COUNT(d.id_detalle) AS items_vendidos,
             NVL(SUM(d.subtotal),0) AS total_ventas
        FROM pedido o
        JOIN detalle_pedido d ON d.id_pedido = o.id_pedido
       WHERE EXTRACT(YEAR FROM o.fecha_pedido) = p_anio
       GROUP BY EXTRACT(MONTH FROM o.fecha_pedido)
       ORDER BY EXTRACT(MONTH FROM o.fecha_pedido);
    RETURN rc;
  END cur_total_ventas_anual;

  FUNCTION cur_clientes_top(p_limit IN NUMBER DEFAULT 10) RETURN SYS_REFCURSOR IS
    rc SYS_REFCURSOR;
  BEGIN
    OPEN rc FOR
      SELECT c.id_cliente, c.nombre, c.email, NVL(SUM(d.subtotal),0) AS total_comprado,
             COUNT(DISTINCT o.id_pedido) AS pedidos_count
        FROM cliente c
        LEFT JOIN pedido o ON o.id_cliente = c.id_cliente
        LEFT JOIN detalle_pedido d ON d.id_pedido = o.id_pedido
       GROUP BY c.id_cliente, c.nombre, c.email
       ORDER BY total_comprado DESC
       FETCH FIRST p_limit ROWS ONLY;
    RETURN rc;
  END cur_clientes_top;

  FUNCTION cur_movimientos_invalidos RETURN SYS_REFCURSOR IS
    rc SYS_REFCURSOR;
  BEGIN
    OPEN rc FOR
      SELECT m.*, p.nombre AS producto_nombre
        FROM movimientos m
        LEFT JOIN producto p ON m.id_producto = p.id_producto
       WHERE m.cantidad <= 0
       ORDER BY m.fecha DESC;
    RETURN rc;
  END cur_movimientos_invalidos;

END pkg_cursores;
