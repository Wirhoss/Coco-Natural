--Tabla Producto
-- INSERTAR PRODUCTO
create or replace procedure insertar_producto (
   p_id_producto  in number,
   p_nombre       in varchar2,
   p_descripcion  in varchar2,
   p_precio       in number,
   p_stock_minimo in number,
   p_stock_actual in number,
   p_id_categoria in number,
   p_id_proveedor in number
) as
begin
   insert into producto values ( p_id_producto,
                                 p_nombre,
                                 p_descripcion,
                                 p_precio,
                                 p_stock_minimo,
                                 p_stock_actual,
                                 p_id_categoria,
                                 p_id_proveedor );
   commit;
end;

-- ACTUALIZAR PRODUCTO
create or replace procedure actualizar_producto (
   p_id_producto  in number,
   p_nombre       in varchar2,
   p_descripcion  in varchar2,
   p_precio       in number,
   p_stock_minimo in number,
   p_stock_actual in number,
   p_id_categoria in number,
   p_id_proveedor in number
) as
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
end;


-- ELIMINAR PRODUCTO
create or replace procedure eliminar_producto (
   p_id_producto in number
) as
begin
   delete from producto
    where id_producto = p_id_producto;
   commit;
end;

-- OBTENER PRODUCTOS
create or replace function obtener_productos return sys_refcursor as
   c_productos sys_refcursor;
begin
   open c_productos for select *
                          from producto;
   return c_productos;
end;