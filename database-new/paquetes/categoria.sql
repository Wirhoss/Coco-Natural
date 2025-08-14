-- pkg_categoria.sql
-- Package: pkg_categoria
-- Contiene: procedimientos y funciones para la tabla CATEGORIA

create or replace package pkg_categoria as
  procedure insertar_categoria(p_id_categoria in categoria.id_categoria%type,
                              p_nombre       in categoria.nombre%type,
                              p_descripcion  in categoria.descripcion%type);
  procedure actualizar_categoria(p_id_categoria in categoria.id_categoria%type,
                                 p_nombre       in categoria.nombre%type,
                                 p_descripcion  in categoria.descripcion%type);
  procedure eliminar_categoria(p_id_categoria in categoria.id_categoria%type);
  function obtener_categorias return sys_refcursor;
end pkg_categoria;
/
create or replace package body pkg_categoria as
  procedure insertar_categoria(p_id_categoria in categoria.id_categoria%type,
                              p_nombre       in categoria.nombre%type,
                              p_descripcion  in categoria.descripcion%type) is
  begin
    insert into categoria(id_categoria, nombre, descripcion)
    values (p_id_categoria, p_nombre, p_descripcion);
    commit;
  end insertar_categoria;

  procedure actualizar_categoria(p_id_categoria in categoria.id_categoria%type,
                                 p_nombre       in categoria.nombre%type,
                                 p_descripcion  in categoria.descripcion%type) is
  begin
    update categoria set nombre = p_nombre, descripcion = p_descripcion
      where id_categoria = p_id_categoria;
    commit;
  end actualizar_categoria;

  procedure eliminar_categoria(p_id_categoria in categoria.id_categoria%type) is
  begin
    delete from categoria where id_categoria = p_id_categoria;
    commit;
  end eliminar_categoria;

  function obtener_categorias return sys_refcursor is
    c_categorias sys_refcursor;
  begin
    open c_categorias for select * from categoria;
    return c_categorias;
  end obtener_categorias;
end pkg_categoria;
/
