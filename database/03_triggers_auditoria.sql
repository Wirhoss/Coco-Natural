-- En algun momento lo terminare, esto es solo un draft, no usar

create or replace trigger trg_auditoria_general before
   insert or update on producto
   for each row
begin
   if inserting then
      :new.fecha_creacion := systimestamp;
      :new.usuario_creacion := user;
   elsif updating then
      :new.fecha_modificacion := systimestamp;
      :new.usuario_modificacion := user;
   end if;
end;
/

create or replace trigger trg_auditoria_categoria before
   insert or update on categoria
   for each row
begin
   if inserting then
      :new.fecha_creacion := systimestamp;
      :new.usuario_creacion := user;
   elsif updating then
      :new.fecha_modificacion := systimestamp;
      :new.usuario_modificacion := user;
   end if;
end;
/

create or replace trigger trg_auditar_movimientos after
   insert or update or delete on movimientos
   for each row
declare
   v_accion varchar2(10);
begin
   if inserting then
      v_accion := 'INSERT';
      insert into auditoria_movimientos (
         id_movimiento,
         usuario,
         accion
      ) values ( :new.id_movimiento,
                 user,
                 v_accion );
   elsif updating then
      v_accion := 'UPDATE';
      insert into auditoria_movimientos (
         id_movimiento,
         usuario,
         accion
      ) values ( :new.id_movimiento,
                 user,
                 v_accion );
   elsif deleting then
      v_accion := 'DELETE';
      insert into auditoria_movimientos (
         id_movimiento,
         usuario,
         accion
      ) values ( :old.id_movimiento,
                 user,
                 v_accion );
   end if;
end;
/