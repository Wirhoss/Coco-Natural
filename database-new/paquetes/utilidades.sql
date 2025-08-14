-- pkg_utilidades.sql
-- Package: pkg_utilidades
-- Funciones utilitarias y helpers

create or replace package pkg_utilidades as
  function fn_calcular_subtotal(p_cantidad in number, p_precio in number) return number;
  function fn_generar_codigo_pedido return varchar2;
end pkg_utilidades;

create or replace package body pkg_utilidades as
  function fn_calcular_subtotal(p_cantidad in number, p_precio in number) return number is
  begin
    return nvl(p_cantidad,0) * nvl(p_precio,0);
  end fn_calcular_subtotal;

  function fn_generar_codigo_pedido return varchar2 is
    v_exists number := 0; v_seq number; v_codigo varchar2(100);
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
end pkg_utilidades;