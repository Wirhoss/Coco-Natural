create or replace procedure actualizar_stock (
   p_id_producto number,
   p_cantidad    number,
   p_tipo        varchar2
) as
begin
   if p_tipo = 'entrada' then
      update producto
         set
         stock_actual = stock_actual + p_cantidad
       where id_producto = p_id_producto;
   elsif p_tipo = 'salida' then
      update producto
         set
         stock_actual = stock_actual - p_cantidad
       where id_producto = p_id_producto;
   end if;
   commit;
end;

create or replace procedure calcular_total_pedido (
   p_id_pedido in pedido.id_pedido%type
) as
   v_total pedido.total%type;
begin
   select nvl(
      sum(cantidad * precio),
      0
   )
     into v_total
     from detalle_pedido
    where id_pedido = p_id_pedido;
   update pedido
      set
      total = v_total
    where id_pedido = p_id_pedido;
exception
   when others then
      raise;
end calcular_total_pedido;


create or replace procedure generar_alerta_stock as
   cursor c_productos is
   select id_producto,
          nombre,
          stock_actual,
          stock_minimo
     from producto
    where stock_actual < stock_minimo;
begin
   for prod in c_productos loop
      insert into alertas_stock (
         id_producto,
         mensaje,
         fecha
      ) values ( prod.id_producto,
                 'Stock crítico: '
                 || prod.nombre
                 || ' - Actual: '
                 || prod.stock_actual
                 || '/Mínimo: '
                 || prod.stock_minimo,
                 sysdate );
   end loop;
   commit;
end;

create or replace procedure procesar_pedido (
   p_id_pedido number
) as
   cursor c_detalles is
   select id_producto,
          cantidad
     from detalle_pedido
    where id_pedido = p_id_pedido;
begin
   for det in c_detalles loop
      update producto
         set
         stock_actual = stock_actual - det.cantidad
       where id_producto = det.id_producto;

      insert into movimientos (
         tipo,
         cantidad,
         id_producto
      ) values ( 'salida',
                 det.cantidad,
                 det.id_producto );
   end loop;

   update pedido
      set
      estado = 'completado'
    where id_pedido = p_id_pedido;
   commit;
end;

create or replace procedure registrar_entrada_inventario (
   p_id_producto  number,
   p_cantidad     number,
   p_id_proveedor number
) as
begin
   insert into movimientos (
      tipo,
      cantidad,
      id_producto
   ) values ( 'entrada',
              p_cantidad,
              p_id_producto );

   update producto
      set
      stock_actual = stock_actual + p_cantidad
    where id_producto = p_id_producto;

   commit;
end;