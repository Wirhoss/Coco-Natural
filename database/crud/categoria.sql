--Tabla Categoria
-- INSERTAR CATEGORIA
create or replace procedure insertar_categoria (
   p_id_categoria in number,
   p_nombre       in varchar2,
   p_descripcion  in varchar2
) as
begin
   insert into categoria values ( p_id_categoria,
                                  p_nombre,
                                  p_descripcion );
   commit;
end;

-- ACTUALIZAR CATEGORIA
create or replace procedure actualizar_categoria (
   p_id_categoria in number,
   p_nombre       in varchar2,
   p_descripcion  in varchar2
) as
begin
   update categoria
      set nombre = p_nombre,
          descripcion = p_descripcion
    where id_categoria = p_id_categoria;
   commit;
end;

-- ELIMINAR CATEGORIA
create or replace procedure eliminar_categoria (
   p_id_categoria in number
) as
begin
   delete from categoria
    where id_categoria = p_id_categoria;
   commit;
end;

-- OBTENER CATEGORIAS
create or replace function obtener_categorias return sys_refcursor as
   c_categorias sys_refcursor;
begin
   open c_categorias for select *
                           from categoria;
   return c_categorias;
end;