-- pkg_auditoria.sql
-- Package: pkg_auditoria
-- Contiene cursores para auditoría

create or replace package pkg_auditoria as
   function cur_auditoria_cambios (
      p_days_back in number
   ) return sys_refcursor;
end pkg_auditoria;

create or replace package body pkg_auditoria as
   function cur_auditoria_cambios (
      p_days_back in number
   ) return sys_refcursor is
      rc       sys_refcursor;
      v_cutoff timestamp := systimestamp - numtodsinterval(
         coalesce(
            p_days_back,
            30
         ),
         'DAY'
      );
   begin
      open rc for select am.id_auditoria,
                         am.id_movimiento,
                         am.fecha_auditoria,
                         am.usuario,
                         am.accion
                                from auditoria_movimientos am
                   where am.fecha_auditoria >= v_cutoff
                   order by am.fecha_auditoria desc;
      return rc;
   end cur_auditoria_cambios;
end pkg_auditoria;