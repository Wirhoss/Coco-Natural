--Tabla Movimientos
-- INSERTAR MOVIMIENTO
create or replace procedure insertar_movimiento (
   p_id_movimiento in number,
   p_tipo          in varchar2,
   p_cantidad      in number,
   p_id_producto   in number
) as
begin
   insert into movimientos values ( p_id_movimiento,
                                    p_tipo,
                                    p_cantidad,
                                    p_id_producto );
   commit;
end;


-- ACTUALIZAR MOVIMIENTO
create or replace procedure actualizar_movimiento (
   p_id_movimiento in number,
   p_tipo          in varchar2,
   p_cantidad      in number,
   p_id_producto   in number
) as
begin
   update movimientos
      set tipo = p_tipo,
          cantidad = p_cantidad,
          id_producto = p_id_producto
    where id_movimiento = p_id_movimiento;
   commit;
end;


-- ELIMINAR MOVIMIENTO
create or replace procedure eliminar_movimiento (
   p_id_movimiento in number
) as
begin
   delete from movimientos
    where id_movimiento = p_id_movimiento;
   commit;
end;


-- OBTENER MOVIMIENTOS
create or replace function obtener_movimientos return sys_refcursor as
   c_movimientos sys_refcursor;
begin
   open c_movimientos for select *
                            from movimientos;
   return c_movimientos;
end;