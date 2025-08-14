-- pkg_producto.sql
-- Package: pkg_producto
-- Contiene: procedimientos y funciones para la tabla PRODUCTO

create or replace package pkg_producto as
   procedure insertar_producto (
      p_nombre       in producto.nombre%type,
      p_descripcion  in producto.descripcion%type,
      p_precio       in producto.precio%type,
      p_stock_minimo in producto.stock_minimo%type,
      p_stock_actual in producto.stock_actual%type,
      p_id_categoria in producto.id_categoria%type,
      p_id_proveedor in producto.id_proveedor%type,
      p_usuario      in producto.usuario_creacion%type default user
   );
   procedure actualizar_producto (
      p_id_producto  in producto.id_producto%type,
      p_nombre       in producto.nombre%type,
      p_descripcion  in producto.descripcion%type,
      p_precio       in producto.precio%type,
      p_stock_minimo in producto.stock_minimo%type,
      p_stock_actual in producto.stock_actual%type,
      p_id_categoria in producto.id_categoria%type,
      p_id_proveedor in producto.id_proveedor%type
   );
   procedure eliminar_producto (
      p_id_producto in producto.id_producto%type
   );
   function obtener_productos return sys_refcursor;

   function fn_obtener_nombre_producto (
      p_id_producto in producto.id_producto%type
   ) return varchar2;
   function fn_precio_promedio_categoria (
      p_id_categoria in categoria.id_categoria%type
   ) return number;
   function cur_productos_por_categoria (
      p_id_categoria in categoria.id_categoria%type
   ) return sys_refcursor;
   function cur_productos_sin_movimientos (
      p_dias in number
   ) return sys_refcursor;
end pkg_producto;

create or replace package body pkg_producto as
   procedure insertar_producto (
      p_nombre       in producto.nombre%type,
      p_descripcion  in producto.descripcion%type,
      p_precio       in producto.precio%type,
      p_stock_minimo in producto.stock_minimo%type,
      p_stock_actual in producto.stock_actual%type,
      p_id_categoria in producto.id_categoria%type,
      p_id_proveedor in producto.id_proveedor%type,
      p_usuario      in producto.usuario_creacion%type
   ) is
   begin
      insert into producto (
         nombre,
         descripcion,
         precio,
         stock_minimo,
         stock_actual,
         id_categoria,
         id_proveedor,
         usuario_creacion
      ) values ( p_nombre,
                 p_descripcion,
                 p_precio,
                 p_stock_minimo,
                 p_stock_actual,
                 p_id_categoria,
                 p_id_proveedor,
                 p_usuario );
    -- commit;
   end insertar_producto;

   procedure actualizar_producto (
      p_id_producto  in producto.id_producto%type,
      p_nombre       in producto.nombre%type,
      p_descripcion  in producto.descripcion%type,
      p_precio       in producto.precio%type,
      p_stock_minimo in producto.stock_minimo%type,
      p_stock_actual in producto.stock_actual%type,
      p_id_categoria in producto.id_categoria%type,
      p_id_proveedor in producto.id_proveedor%type
   ) is
   begin
      update producto
         set nombre = p_nombre,
             descripcion = p_descripcion,
             precio = p_precio,
             stock_minimo = p_stock_minimo,
             stock_actual = p_stock_actual,
             id_categoria = p_id_categoria,
             id_proveedor = p_id_proveedor
       where id_producto = p_id_producto;
      commit;
   end actualizar_producto;

   procedure eliminar_producto (
      p_id_producto in producto.id_producto%type
   ) is
   begin
      delete from producto
       where id_producto = p_id_producto;
      commit;
   end eliminar_producto;

   function obtener_productos return sys_refcursor is
      c_productos sys_refcursor;
   begin
      open c_productos for select *
                             from producto;
      return c_productos;
   end obtener_productos;

   function fn_obtener_nombre_producto (
      p_id_producto in producto.id_producto%type
   ) return varchar2 is
      v_nombre varchar2(4000);
   begin
      select nombre
        into v_nombre
        from producto
       where id_producto = p_id_producto;
      return v_nombre;
   exception
      when no_data_found then
         return null;
   end fn_obtener_nombre_producto;

   function fn_precio_promedio_categoria (
      p_id_categoria in categoria.id_categoria%type
   ) return number is
      v_prom number;
   begin
      select nvl(
         avg(precio),
         0
      )
        into v_prom
        from producto
       where id_categoria = p_id_categoria;
      return v_prom;
   exception
      when no_data_found then
         return null;
   end fn_precio_promedio_categoria;

   function cur_productos_por_categoria (
      p_id_categoria in categoria.id_categoria%type
   ) return sys_refcursor is
      rc sys_refcursor;
   begin
      open rc for select p.*
                                from producto p
                   where p.id_categoria = p_id_categoria;
      return rc;
   end cur_productos_por_categoria;

   function cur_productos_sin_movimientos (
      p_dias in number
   ) return sys_refcursor is
      rc       sys_refcursor;
      v_cutoff timestamp := systimestamp - numtodsinterval(
         nvl(
            p_dias,
            30
         ),
         'DAY'
      );
   begin
      open rc for select p.*
                                from producto p
                   where not exists (
                     select 1
                       from movimientos m
                      where m.id_producto = p.id_producto
                        and m.fecha >= v_cutoff
                  )
                   order by p.nombre;
      return rc;
   end cur_productos_sin_movimientos;
end pkg_producto;