-- pkg_alertas.sql
-- Package: pkg_alertas
-- Contiene wrappers para generación de alertas (usa pkg_inventario internamente)

create or replace package pkg_alertas as
  procedure generar_alertas_stock;
end pkg_alertas;
/
create or replace package body pkg_alertas as
  procedure generar_alertas_stock is
  begin
    pkg_inventario.generar_alerta_stock;
  end generar_alertas_stock;
end pkg_alertas;
/
