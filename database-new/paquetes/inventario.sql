-- pkg_inventario.sql
-- Package: pkg_inventario
-- Contiene: procedimientos y funciones para gestión de inventario y alertas

create or replace package pkg_inventario as
  procedure actualizar_stock(p_id_producto in producto.id_producto%type,
                             p_cantidad in number,
                             p_tipo in varchar2);
  procedure registrar_entrada_inventario(p_id_producto in producto.id_producto%type,
                                         p_cantidad in number,
                                         p_id_proveedor in proveedor.id_proveedor%type);
  function fn_stock_disponible(p_id_producto in producto.id_producto%type) return number;
  function fn_validar_stock(p_id_producto in producto.id_producto%type, p_cantidad in number) return number;
  function fn_porcentaje_stock(p_id_producto in producto.id_producto%type) return number;
  procedure generar_alerta_stock;
end pkg_inventario;

create or replace package body pkg_inventario as
  procedure actualizar_stock(p_id_producto in producto.id_producto%type,
                             p_cantidad in number,
                             p_tipo in varchar2) is
  begin
    if lower(nvl(p_tipo,' ')) = 'entrada' then
      update producto set stock_actual = stock_actual + nvl(p_cantidad,0) where id_producto = p_id_producto;
    elsif lower(nvl(p_tipo,' ')) = 'salida' then
      update producto set stock_actual = stock_actual - nvl(p_cantidad,0) where id_producto = p_id_producto;
    end if;
    commit;
  end actualizar_stock;

  procedure registrar_entrada_inventario(p_id_producto in producto.id_producto%type,
                                         p_cantidad in number,
                                         p_id_proveedor in proveedor.id_proveedor%type) is
  begin
    insert into movimientos(tipo, cantidad, id_producto) values ('entrada', p_cantidad, p_id_producto);
    update producto set stock_actual = stock_actual + nvl(p_cantidad,0) where id_producto = p_id_producto;
    commit;
  end registrar_entrada_inventario;

  function fn_stock_disponible(p_id_producto in producto.id_producto%type) return number is
    v_stock number;
  begin
    select stock_actual into v_stock from producto where id_producto = p_id_producto;
    return v_stock;
  exception when no_data_found then
    return null;
  end fn_stock_disponible;

  function fn_validar_stock(p_id_producto in producto.id_producto%type, p_cantidad in number) return number is
    v_stock number;
  begin
    select stock_actual into v_stock from producto where id_producto = p_id_producto;
    if v_stock >= nvl(p_cantidad,0) then
      return 1;
    else
      return 0;
    end if;
  exception when no_data_found then
    return 0;
  end fn_validar_stock;

  function fn_porcentaje_stock(p_id_producto in producto.id_producto%type) return number is
    v_stock number; v_min number;
  begin
    select stock_actual, stock_minimo into v_stock, v_min from producto where id_producto = p_id_producto;
    if v_min is null or v_min = 0 then
      return null;
    end if;
    return (v_stock / v_min);
  exception when no_data_found then
    return null;
  end fn_porcentaje_stock;

  procedure generar_alerta_stock is
  begin
    for prod in (select id_producto, nombre, stock_actual, stock_minimo from producto where stock_actual < stock_minimo) loop
      insert into alertas_stock(id_producto, mensaje, fecha) values (
        prod.id_producto,
        'Stock crítico: ' || prod.nombre || ' - Actual: ' || prod.stock_actual || '/Mínimo: ' || prod.stock_minimo,
        sysdate);
    end loop;
    commit;
  end generar_alerta_stock;
end pkg_inventario;