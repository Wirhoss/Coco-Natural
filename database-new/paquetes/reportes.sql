-- pkg_reportes.sql
-- Package: pkg_reportes
-- Contiene cursores y funciones para reportes (ventas, stock, clientes, etc.)

create or replace package pkg_reportes as
  function cur_ventas_por_mes(p_anio in number) return sys_refcursor;
  function cur_total_ventas_anual(p_anio in number) return sys_refcursor;
  function cur_clientes_sin_pedidos(p_meses in number) return sys_refcursor;
  function cur_clientes_top(p_limit in number) return sys_refcursor;
  function cur_pedidos_urgentes(p_dias_adelante in number) return sys_refcursor;
  function cur_stock_por_categoria return sys_refcursor;
  function cur_productos_sin_movimientos(p_dias in number) return sys_refcursor;
end pkg_reportes;
/
create or replace package body pkg_reportes as
  function cur_ventas_por_mes(p_anio in number) return sys_refcursor is
    rc sys_refcursor;
  begin
    open rc for
      select to_char(trunc(o.fecha_pedido,'MM'),'YYYY-MM') as mes,
             extract(month from o.fecha_pedido) as numero_mes,
             count(d.id_detalle) as cantidad_items,
             nvl(sum(d.subtotal),0) as total_ventas
      from pedido o join detalle_pedido d on d.id_pedido = o.id_pedido
      where extract(year from o.fecha_pedido) = p_anio
      group by trunc(o.fecha_pedido,'MM')
      order by trunc(o.fecha_pedido,'MM');
    return rc;
  end cur_ventas_por_mes;

  function cur_total_ventas_anual(p_anio in number) return sys_refcursor is
    rc sys_refcursor;
  begin
    open rc for
      select extract(month from o.fecha_pedido) as mes, count(d.id_detalle) as items_vendidos, nvl(sum(d.subtotal),0) as total_ventas
      from pedido o join detalle_pedido d on d.id_pedido = o.id_pedido
      where extract(year from o.fecha_pedido) = p_anio
      group by extract(month from o.fecha_pedido)
      order by extract(month from o.fecha_pedido);
    return rc;
  end cur_total_ventas_anual;

  function cur_clientes_sin_pedidos(p_meses in number) return sys_refcursor is
    rc sys_refcursor;
    v_cutoff date := add_months(trunc(sysdate), -nvl(p_meses,6));
  begin
    open rc for
      select c.* from cliente c where not exists (
        select 1 from pedido o where o.id_cliente = c.id_cliente and o.fecha_pedido >= v_cutoff)
      order by c.nombre;
    return rc;
  end cur_clientes_sin_pedidos;

  function cur_clientes_top(p_limit in number) return sys_refcursor is
    rc sys_refcursor;
  begin
    open rc for
      select c.id_cliente, c.nombre, c.email, nvl(sum(d.subtotal),0) as total_comprado, count(distinct o.id_pedido) as pedidos_count
      from cliente c left join pedido o on o.id_cliente = c.id_cliente left join detalle_pedido d on d.id_pedido = o.id_pedido
      group by c.id_cliente, c.nombre, c.email
      order by total_comprado desc fetch first nvl(p_limit,10) rows only;
    return rc;
  end cur_clientes_top;

  function cur_pedidos_urgentes(p_dias_adelante in number) return sys_refcursor is
    rc sys_refcursor;
    v_cutoff date := trunc(sysdate) + nvl(p_dias_adelante,7);
  begin
    open rc for
      select o.*, c.nombre as cliente_nombre, c.telefono
      from pedido o join cliente c on o.id_cliente = c.id_cliente
      where o.fecha_entrega is not null and trunc(o.fecha_entrega) <= v_cutoff and o.estado = 'pendiente'
      order by o.fecha_entrega asc;
    return rc;
  end cur_pedidos_urgentes;

  function cur_stock_por_categoria return sys_refcursor is
    rc sys_refcursor;
  begin
    open rc for
      select c.id_categoria, c.nombre as categoria_nombre, nvl(sum(p.stock_actual),0) as stock_total,
             nvl(sum(p.stock_minimo),0) as stock_minimo_total, count(p.id_producto) as productos_count
      from categoria c left join producto p on p.id_categoria = c.id_categoria
      group by c.id_categoria, c.nombre
      order by c.nombre;
    return rc;
  end cur_stock_por_categoria;

  function cur_productos_sin_movimientos(p_dias in number) return sys_refcursor is
    rc sys_refcursor;
    v_cutoff timestamp := systimestamp - numtodsinterval(nvl(p_dias,30),'DAY');
  begin
    open rc for
      select p.* from producto p where not exists (
        select 1 from movimientos m where m.id_producto = p.id_producto and m.fecha >= v_cutoff)
      order by p.nombre;
    return rc;
  end cur_productos_sin_movimientos;
end pkg_reportes;
/
