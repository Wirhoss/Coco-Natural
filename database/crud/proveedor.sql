--Tabla     Proveedor
-- INSERTAR PROVEEDOR
create or replace procedure insertar_proveedor (
   p_id_proveedor in number,
   p_nombre       in varchar2,
   p_telefono     in number,
   p_email        in varchar2,
   p_direccion    in varchar2
) as
begin
   insert into proveedor values ( p_id_proveedor,
                                  p_nombre,
                                  p_telefono,
                                  p_email,
                                  p_direccion );
   commit;
end;

-- ACTUALIZAR PROVEEDOR
create or replace procedure actualizar_proveedor (
   p_id_proveedor in number,
   p_nombre       in varchar2,
   p_telefono     in number,
   p_email        in varchar2,
   p_direccion    in varchar2
) as
begin
   update proveedor
      set nombre = p_nombre,
          telefono = p_telefono,
          email = p_email,
          direccion = p_direccion
    where id_proveedor = p_id_proveedor;
   commit;
end;

-- ELIMINAR PROVEEDOR
create or replace procedure eliminar_proveedor (
   p_id_proveedor in number
) as
begin
   delete from proveedor
    where id_proveedor = p_id_proveedor;
   commit;
end;

create or replace procedure obtener_proveedores (
   p_cursor out sys_refcursor
) as
begin
   open p_cursor for select *
                       from proveedor;
end;