CREATE OR REPLACE VIEW vw_stock_critico AS
  SELECT id_producto,
         nombre,
         stock_actual,
         stock_minimo
    FROM producto
   WHERE stock_actual < stock_minimo;

CREATE OR REPLACE VIEW vw_ventas_mensuales AS
  SELECT TO_CHAR(fecha_pedido, 'YYYY-MM') AS mes,
         SUM(total) AS total_ventas
    FROM pedido
GROUP BY TO_CHAR(fecha_pedido, 'YYYY-MM');

CREATE OR REPLACE VIEW vw_top_productos AS
  SELECT p.id_producto,
         p.nombre,
         SUM(dp.cantidad) AS total_vendido
    FROM detalle_pedido dp
    JOIN producto p
      ON dp.id_producto = p.id_producto
GROUP BY p.id_producto, p.nombre;

CREATE OR REPLACE VIEW vw_pedidos_pendientes AS
  SELECT id_pedido,
         fecha_pedido,
         id_cliente,
         total,
         estado
    FROM pedido
   WHERE estado = 'pendiente'
WITH READ ONLY;

CREATE OR REPLACE VIEW vw_proveedores_productos AS
  SELECT pr.id_proveedor,
         pr.nombre AS proveedor,
         p.id_producto,
         p.nombre AS producto
    FROM proveedor pr
    JOIN producto p
      ON pr.id_proveedor = p.id_proveedor;

CREATE OR REPLACE VIEW vw_clientes_frecuentes AS
  SELECT c.id_cliente,
         c.nombre,
         COUNT(p.id_pedido) AS total_pedidos
    FROM cliente c
    LEFT JOIN pedido p
      ON c.id_cliente = p.id_cliente
GROUP BY c.id_cliente, c.nombre;

CREATE OR REPLACE VIEW vw_movimientos_recientes AS
  SELECT *
    FROM movimientos
   WHERE fecha >= SYSDATE - 30;

CREATE OR REPLACE VIEW vw_inventario_completo AS
  SELECT p.id_producto,
         p.nombre AS producto,
         c.nombre AS categoria,
         p.stock_actual,
         p.stock_minimo
    FROM producto p
    JOIN categoria c
      ON p.id_categoria = c.id_categoria;

CREATE OR REPLACE VIEW vw_total_ventas_categoria AS
  SELECT c.id_categoria,
         c.nombre AS categoria,
         SUM(dp.subtotal) AS total_ventas
    FROM detalle_pedido dp
    JOIN producto p
      ON dp.id_producto = p.id_producto
    JOIN categoria c
      ON p.id_categoria = c.id_categoria
GROUP BY c.id_categoria, c.nombre;

CREATE OR REPLACE VIEW vw_detalle_pedidos AS
  SELECT pe.id_pedido,
         pe.fecha_pedido,
         c.nombre AS cliente,
         p.nombre AS producto,
         dp.cantidad,
         dp.precio,
         dp.subtotal
    FROM pedido pe
    JOIN cliente c
      ON pe.id_cliente = c.id_cliente
    JOIN detalle_pedido dp
      ON pe.id_pedido = dp.id_pedido
    JOIN producto p
      ON dp.id_producto = p.id_producto;