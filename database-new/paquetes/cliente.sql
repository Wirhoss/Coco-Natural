-- pkg_cliente.sql
-- Package: pkg_cliente
-- Contiene procedimientos y funciones para la tabla CLIENTE y operaciones relacionadas

create or replace package pkg_cliente as
  procedure insertar_cliente(p_nombre    in cliente.nombre%type,
                             p_telefono  in cliente.telefono%type,
                             p_email     in cliente.email%type,
                             p_direccion in cliente.direccion%type);
  procedure actualizar_cliente(p_id        in cliente.id_cliente%type,
                               p_nombre    in cliente.nombre%type,
                               p_telefono  in cliente.telefono%type,
                               p_email     in cliente.email%type,
                               p_direccion in cliente.direccion%type);
  procedure eliminar_cliente(p_id in cliente.id_cliente%type);
  procedure obtener_clientes(p_cursor out sys_refcursor);

  function fn_contar_pedidos_cliente(p_id_cliente in cliente.id_cliente%type) return number;
  function fn_calcular_edad_cliente(p_id_cliente in cliente.id_cliente%type) return number;
  function cur_pedidos_por_cliente(p_id_cliente in cliente.id_cliente%type) return sys_refcursor;
end pkg_cliente;
/
create or replace package body pkg_cliente as
  procedure insertar_cliente(p_nombre    in cliente.nombre%type,
                             p_telefono  in cliente.telefono%type,
                             p_email     in cliente.email%type,
                             p_direccion in cliente.direccion%type) is
  begin
    insert into cliente(nombre, telefono, email, direccion)
    values (p_nombre, p_telefono, p_email, p_direccion);
    commit;
  end insertar_cliente;

  procedure actualizar_cliente(p_id        in cliente.id_cliente%type,
                               p_nombre    in cliente.nombre%type,
                               p_telefono  in cliente.telefono%type,
                               p_email     in cliente.email%type,
                               p_direccion in cliente.direccion%type) is
  begin
    update cliente set nombre = p_nombre, telefono = p_telefono,
        email = p_email, direccion = p_direccion
      where id_cliente = p_id;
    commit;
  end actualizar_cliente;

  procedure eliminar_cliente(p_id in cliente.id_cliente%type) is
  begin
    delete from cliente where id_cliente = p_id;
    commit;
  end eliminar_cliente;

  procedure obtener_clientes(p_cursor out sys_refcursor) is
  begin
    open p_cursor for select * from cliente;
  end obtener_clientes;

  function fn_contar_pedidos_cliente(p_id_cliente in cliente.id_cliente%type) return number is
    v_count number;
  begin
    select count(*) into v_count from pedido where id_cliente = p_id_cliente;
    return v_count;
  exception when others then
    return null;
  end fn_contar_pedidos_cliente;

  function fn_calcular_edad_cliente(p_id_cliente in cliente.id_cliente%type) return number is
    v_exists number := 0;
    v_fecha date;
    v_edad number;
  begin
    select count(*) into v_exists from user_tab_columns
      where table_name = 'CLIENTE' and column_name = 'FECHA_NACIMIENTO';
    if v_exists = 0 then
      return null;
    end if;

    execute immediate 'select fecha_nacimiento from cliente where id_cliente = :1'
      into v_fecha using p_id_cliente;

    if v_fecha is null then
      return null;
    end if;

    v_edad := floor(months_between(trunc(sysdate), trunc(v_fecha)) / 12);
    return v_edad;
  exception when no_data_found then
    return null;
  when others then
    return null;
  end fn_calcular_edad_cliente;

  function cur_pedidos_por_cliente(p_id_cliente in cliente.id_cliente%type) return sys_refcursor is
    rc sys_refcursor;
  begin
    open rc for
      select o.*, c.nombre as cliente_nombre, c.email as cliente_email
      from pedido o join cliente c on o.id_cliente = c.id_cliente
      where o.id_cliente = p_id_cliente
      order by o.fecha_pedido desc;
    return rc;
  end cur_pedidos_por_cliente;
end pkg_cliente;
/
