create or replace procedure insertar_cliente (
   p_nombre    varchar2,
   p_telefono  number,
   p_email     varchar2,
   p_direccion varchar2
) as
begin
   insert into cliente (
      nombre,
      telefono,
      email,
      direccion
   ) values ( p_nombre,
              p_telefono,
              p_email,
              p_direccion );
   commit;
end;

create or replace procedure actualizar_cliente (
   p_id        number,
   p_nombre    varchar2,
   p_telefono  number,
   p_email     varchar2,
   p_direccion varchar2
) as
begin
   update cliente
      set nombre = p_nombre,
          telefono = p_telefono,
          email = p_email,
          direccion = p_direccion
    where id_cliente = p_id;
   commit;
end;

create or replace procedure eliminar_cliente (
   p_id number
) as
begin
   delete from cliente
    where id_cliente = p_id;
   commit;
end;

create or replace procedure obtener_clientes (
   p_cursor out sys_refcursor
) as
begin
   open p_cursor for select *
                       from cliente;
end;