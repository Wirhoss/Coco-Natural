-- pkg_utilidades.sql
-- Package: pkg_utilidades
-- Funciones utilitarias y helpers

create or replace package pkg_utilidades as
  function fn_calcular_subtotal(p_cantidad in number, p_precio in number) return number;
end pkg_utilidades;

create or replace package body pkg_utilidades as
  function fn_calcular_subtotal(p_cantidad in number, p_precio in number) return number is
  begin
    return nvl(p_cantidad,0) * nvl(p_precio,0);
  end fn_calcular_subtotal;
end pkg_utilidades;