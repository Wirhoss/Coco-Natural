-- pkg_proveedor.sql
-- Package: pkg_proveedor
-- Contiene: procedimientos y funciones para la tabla PROVEEDOR y reportes relacionados

create or replace package pkg_proveedor as
   procedure insertar_proveedor (
      p_nombre    in proveedor.nombre%type,
      p_telefono  in proveedor.telefono%type,
      p_email     in proveedor.email%type,
      p_direccion in proveedor.direccion%type,
      p_usuario   in proveedor.usuario_creacion%type default user
   );
   procedure actualizar_proveedor (
      p_id_proveedor in proveedor.id_proveedor%type,
      p_nombre       in proveedor.nombre%type,
      p_telefono     in proveedor.telefono%type,
      p_email        in proveedor.email%type,
      p_direccion    in proveedor.direccion%type
   );
   procedure eliminar_proveedor (
      p_id_proveedor in proveedor.id_proveedor%type
   );
   procedure obtener_proveedores (
      p_cursor out sys_refcursor
   );

   function cur_productos_proveedor (
      p_id_proveedor in proveedor.id_proveedor%type
   ) return sys_refcursor;
   function fn_contar_productos_proveedor (
      p_id_proveedor in proveedor.id_proveedor%type
   ) return number;
   function cur_proveedores_con_stock_bajo return sys_refcursor;
end pkg_proveedor;

create or replace package body pkg_proveedor as
   procedure insertar_proveedor (
      p_nombre    in proveedor.nombre%type,
      p_telefono  in proveedor.telefono%type,
      p_email     in proveedor.email%type,
      p_direccion in proveedor.direccion%type,
      p_usuario   in proveedor.usuario_creacion%type
   ) is
   begin
      insert into proveedor (
         nombre,
         telefono,
         email,
         direccion,
         usuario_creacion
      ) values ( p_nombre,
                 p_telefono,
                 p_email,
                 p_direccion,
                 p_usuario );
    -- commit;
   end insertar_proveedor;

   procedure actualizar_proveedor (
      p_id_proveedor in proveedor.id_proveedor%type,
      p_nombre       in proveedor.nombre%type,
      p_telefono     in proveedor.telefono%type,
      p_email        in proveedor.email%type,
      p_direccion    in proveedor.direccion%type
   ) is
   begin
      update proveedor
         set nombre = p_nombre,
             telefono = p_telefono,
             email = p_email,
             direccion = p_direccion
       where id_proveedor = p_id_proveedor;
      commit;
   end actualizar_proveedor;

   procedure eliminar_proveedor (
      p_id_proveedor in proveedor.id_proveedor%type
   ) is
   begin
      delete from proveedor
       where id_proveedor = p_id_proveedor;
      commit;
   end eliminar_proveedor;

   procedure obtener_proveedores (
      p_cursor out sys_refcursor
   ) is
   begin
      open p_cursor for select *
                          from proveedor;
   end obtener_proveedores;

   function cur_productos_proveedor (
      p_id_proveedor in proveedor.id_proveedor%type
   ) return sys_refcursor is
      rc sys_refcursor;
   begin
      open rc for select p.*
                                from producto p
                   where p.id_proveedor = p_id_proveedor
                   order by p.nombre;
      return rc;
   end cur_productos_proveedor;

   function fn_contar_productos_proveedor (
      p_id_proveedor in proveedor.id_proveedor%type
   ) return number is
      v_count number;
   begin
      select count(*)
        into v_count
        from producto
       where id_proveedor = p_id_proveedor;
      return v_count;
   exception
      when others then
         return null;
   end fn_contar_productos_proveedor;

   function cur_proveedores_con_stock_bajo return sys_refcursor is
      rc sys_refcursor;
   begin
      open rc for select pr.id_proveedor,
                         pr.nombre as proveedor_nombre,
                         p.id_producto,
                         p.nombre as producto_nombre,
                         p.stock_actual,
                         p.stock_minimo
                                from proveedor pr
                                join producto p
                              on p.id_proveedor = pr.id_proveedor
                   where p.stock_actual < p.stock_minimo
                   order by pr.nombre,
                            p.nombre;
      return rc;
   end cur_proveedores_con_stock_bajo;
end pkg_proveedor;