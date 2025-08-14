-- pkg_movimiento.sql
-- Package: pkg_movimiento
-- Contiene: procedimientos y funciones para la tabla MOVIMIENTOS

create or replace package pkg_movimiento as
   procedure insertar_movimiento (
      p_tipo        in movimientos.tipo%type,
      p_cantidad    in movimientos.cantidad%type,
      p_id_producto in movimientos.id_producto%type,
      p_usuario     in movimientos.usuario_creacion%type default user
   );
   procedure actualizar_movimiento (
      p_id_movimiento in movimientos.id_movimiento%type,
      p_tipo          in movimientos.tipo%type,
      p_cantidad      in movimientos.cantidad%type,
      p_id_producto   in movimientos.id_producto%type
   );
   procedure eliminar_movimiento (
      p_id_movimiento in movimientos.id_movimiento%type
   );
   function obtener_movimientos return sys_refcursor;

   function cur_movimientos_por_producto (
      p_id_producto in producto.id_producto%type
   ) return sys_refcursor;
   function cur_movimientos_invalidos return sys_refcursor;
   function fn_contar_movimientos_tipo (
      p_tipo in varchar2
   ) return number;
end pkg_movimiento;

create or replace package body pkg_movimiento as
   procedure insertar_movimiento (
      p_tipo        in movimientos.tipo%type,
      p_cantidad    in movimientos.cantidad%type,
      p_id_producto in movimientos.id_producto%type,
      p_usuario     in movimientos.usuario_creacion%type
   ) is
   begin
      insert into movimientos (
         tipo,
         cantidad,
         id_producto,
         usuario_creacion
      ) values ( p_tipo,
                 p_cantidad,
                 p_id_producto,
                 p_usuario );
    -- commit;
   end insertar_movimiento;

   procedure actualizar_movimiento (
      p_id_movimiento in movements.id_movimiento%type,
      p_tipo          in movements.tipo%type,
      p_cantidad      in movements.cantidad%type,
      p_id_producto   in movements.id_producto%type
   ) is
   begin
      update movimientos
         set tipo = nvl(nullif(p_tipo,   ''), tipo),
             cantidad = nvl(nullif(p_cantidad,   ''), cantidad),
             id_producto = nvl(nullif(p_id_producto,   ''), id_producto)
       where id_movimiento = p_id_movimiento;
      commit;
   end actualizar_movimiento;

   procedure eliminar_movimiento (
      p_id_movimiento in movimientos.id_movimiento%type
   ) is
   begin
      delete from movimientos
       where id_movimiento = p_id_movimiento;
      commit;
   end eliminar_movimiento;

   function obtener_movimientos return sys_refcursor is
      c_movimientos sys_refcursor;
   begin
      open c_movimientos for select *
                               from movimientos;
      return c_movimientos;
   end obtener_movimientos;

   function cur_movimientos_por_producto (
      p_id_producto in producto.id_producto%type
   ) return sys_refcursor is
      rc sys_refcursor;
   begin
      open rc for select m.*,
                         p.nombre as producto_nombre,
                         p.stock_actual
                                from movimientos m
                                join producto p
                              on m.id_producto = p.id_producto
                   where m.id_producto = p_id_producto
                   order by m.fecha desc;
      return rc;
   end cur_movimientos_por_producto;

   function cur_movimientos_invalidos return sys_refcursor is
      rc sys_refcursor;
   begin
      open rc for select m.*,
                         p.nombre as producto_nombre
                                from movimientos m
                                left join producto p
                              on m.id_producto = p.id_producto
                   where m.cantidad <= 0
                   order by m.fecha desc;
      return rc;
   end cur_movimientos_invalidos;

   function fn_contar_movimientos_tipo (
      p_tipo in varchar2
   ) return number is
      v_count number;
   begin
      select count(*)
        into v_count
        from movimientos
       where upper(tipo) = upper(nvl(
         p_tipo,
         ' '
      ));
      return v_count;
   exception
      when others then
         return null;
   end fn_contar_movimientos_tipo;
end pkg_movimiento;