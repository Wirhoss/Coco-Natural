-- pkg_pedido.sql
-- Package: pkg_pedido
-- Contiene: procedimientos y funciones para la tabla PEDIDO y procesamiento de pedidos

create or replace package pkg_pedido as
  procedure procesar_pedido(p_id_pedido in pedido.id_pedido%type);
  procedure calcular_total_pedido(p_id_pedido in pedido.id_pedido%type);
  function cur_detalle_pedido_completo(p_id_pedido in pedido.id_pedido%type) return sys_refcursor;

  function fn_generar_codigo_pedido return varchar2;
  function fn_total_compras_cliente(p_id_cliente in cliente.id_cliente%type) return number;
  function fn_dias_entrega_promedio(p_id_pedido in pedido.id_pedido%type) return number;
end pkg_pedido;
/
create or replace package body pkg_pedido as
  procedure procesar_pedido(p_id_pedido in pedido.id_pedido%type) is
    cursor c_detalles is select id_producto, cantidad from detalle_pedido where id_pedido = p_id_pedido;
  begin
    for det in c_detalles loop
      update producto set stock_actual = stock_actual - det.cantidad where id_producto = det.id_producto;
      insert into movimientos(tipo, cantidad, id_producto) values ('salida', det.cantidad, det.id_producto);
    end loop;
    update pedido set estado = 'completado' where id_pedido = p_id_pedido;
    commit;
  end procesar_pedido;

  procedure calcular_total_pedido(p_id_pedido in pedido.id_pedido%type) is
    v_total pedido.total%type;
  begin
    select nvl(sum(cantidad * precio),0) into v_total from detalle_pedido where id_pedido = p_id_pedido;
    update pedido set total = v_total where id_pedido = p_id_pedido;
  exception when others then
    raise;
  end calcular_total_pedido;

  function cur_detalle_pedido_completo(p_id_pedido in pedido.id_pedido%type) return sys_refcursor is
    rc sys_refcursor;
  begin
    open rc for
      select dp.*, pr.nombre as producto_nombre, pr.descripcion as producto_descripcion,
             o.fecha_pedido, o.fecha_entrega, o.estado, o.total, c.nombre as cliente_nombre, c.email as cliente_email
      from detalle_pedido dp
      join producto pr on dp.id_producto = pr.id_producto
      join pedido o on dp.id_pedido = o.id_pedido
      join cliente c on o.id_cliente = c.id_cliente
      where dp.id_pedido = p_id_pedido
      order by dp.id_detalle;
    return rc;
  end cur_detalle_pedido_completo;

  function fn_generar_codigo_pedido return varchar2 is
    v_exists number := 0;
    v_seq number;
    v_codigo varchar2(100);
  begin
    select count(*) into v_exists from user_sequences where sequence_name = 'SEQ_CODIGO_PEDIDO';
    if v_exists > 0 then
      execute immediate 'select seq_codigo_pedido.nextval from dual' into v_seq;
      v_codigo := 'P-' || to_char(sysdate,'YYYY') || '-' || lpad(v_seq,6,'0');
    else
      v_codigo := 'P-' || to_char(sysdate,'YYYYMMDDHH24MISS') || '-' || substr(dbms_random.string('X',6),1,6);
    end if;
    return v_codigo;
  exception when others then
    return null;
  end fn_generar_codigo_pedido;

  function fn_total_compras_cliente(p_id_cliente in cliente.id_cliente%type) return number is
    v_total number;
  begin
    select nvl(sum(d.subtotal),0) into v_total
      from pedido o join detalle_pedido d on d.id_pedido = o.id_pedido
      where o.id_cliente = p_id_cliente;
    return v_total;
  exception when others then
    return null;
  end fn_total_compras_cliente;

  function fn_dias_entrega_promedio(p_id_pedido in pedido.id_pedido%type) return number is
    v_days number;
  begin
    if p_id_pedido is not null then
      select (o.fecha_entrega - o.fecha_pedido) into v_days from pedido o where o.id_pedido = p_id_pedido and o.fecha_entrega is not null;
      return v_days;
    else
      select avg(o.fecha_entrega - o.fecha_pedido) into v_days from pedido o where o.fecha_entrega is not null and o.fecha_pedido is not null;
      return v_days;
    end if;
  exception when no_data_found then
    return null;
  when others then
    return null;
  end fn_dias_entrega_promedio;
end pkg_pedido;
/
