create view vw_stock_critico as
   select id_producto,
          nombre,
          stock_actual,
          stock_minimo
     from producto
    where stock_actual < stock_minimo;

create view vw_ventas_mensuales as
   select to_char(
      fecha_pedido,
      'YYYY-MM'
   ) as mes,
          sum(total) as total_ventas
     from pedido
    group by to_char(
      fecha_pedido,
      'YYYY-MM'
   );

create view vw_top_productos as
   select p.id_producto,
          p.nombre,
          sum(dp.cantidad) as total_vendido
     from detalle_pedido dp
     join producto p
   on dp.id_producto = p.id_producto
    group by p.id_producto,
             p.nombre
    order by total_vendido desc;

create or replace view vw_pedidos_pendientes as
   select id_pedido,
          fecha_pedido,
          id_cliente,
          total,
          estado
     from pedido
    where estado = 'pendiente'
with read only;

create view vw_proveedores_productos as
   select pr.id_proveedor,
          pr.nombre as proveedor,
          p.id_producto,
          p.nombre as producto
     from proveedor pr
     join producto p
   on pr.id_proveedor = p.id_proveedor;

create view vw_clientes_frecuentes as
   select c.id_cliente,
          c.nombre,
          count(p.id_pedido) as total_pedidos
     from cliente c
     left join pedido p
   on c.id_cliente = p.id_cliente
    group by c.id_cliente,
             c.nombre
    order by total_pedidos desc;

create view vw_movimientos_recientes as
   select *
     from movimientos
    where fecha >= sysdate - 30;

create view vw_inventario_completo as
   select p.id_producto,
          p.nombre as producto,
          c.nombre as categoria,
          p.stock_actual,
          p.stock_minimo
     from producto p
     join categoria c
   on p.id_categoria = c.id_categoria;

create view vw_total_ventas_categoria as
   select c.id_categoria,
          c.nombre as categoria,
          sum(dp.cantidad * dp.precio) as total_ventas
     from detalle_pedido dp
     join producto p
   on dp.id_producto = p.id_producto
     join categoria c
   on p.id_categoria = c.id_categoria
    group by c.id_categoria,
             c.nombre;

create view vw_detalle_pedidos as
   select pe.id_pedido,
          pe.fecha_pedido,
          c.nombre as cliente,
          p.nombre as producto,
          dp.cantidad,
          dp.precio,
          ( dp.cantidad * dp.precio ) as subtotal
     from pedido pe
     join cliente c
   on pe.id_cliente = c.id_cliente
     join detalle_pedido dp
   on pe.id_pedido = dp.id_pedido
     join producto p
   on dp.id_producto = p.id_producto;