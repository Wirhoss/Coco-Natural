create or replace trigger trg_actualizar_stock after
   insert on movimientos
   for each row
declare
   v_stock     producto.stock_actual%type;
   v_tipo_norm varchar2(20);
   v_user      varchar2(128);
begin
   v_user := nvl(
      :new.usuario_creacion,
      user
   );
   v_tipo_norm := lower(trim(:new.tipo));
   if v_tipo_norm not in ( 'entrada',
                           'salida' ) then
      raise_application_error(
         -20006,
         'Tipo de movimiento inválido: '
         || nvl(
            :new.tipo,
            'NULL'
         )
         || ' (permitidos: entrada/salida)'
      );
   end if;

   if nvl(
      :new.cantidad,
      0
   ) <= 0 then
      raise_application_error(
         -20005,
         'Cantidad debe ser mayor a cero.'
      );
   end if;

   select nvl(
      stock_actual,
      0
   )
     into v_stock
     from producto
    where id_producto = :new.id_producto
   for update;

   if v_tipo_norm = 'entrada' then
      update producto
         set stock_actual = nvl(
         stock_actual,
         0
      ) + :new.cantidad,
             fecha_modificacion = systimestamp,
             usuario_modificacion = v_user
       where id_producto = :new.id_producto;

   else -- 'salida'
      if v_stock < :new.cantidad then
         raise_application_error(
            -20001,
            'Stock insuficiente para el movimiento. Producto ID='
            || :new.id_producto
            || ' (solicitado='
            || :new.cantidad
            || ', disponible='
            || v_stock
            || ')'
         );
      end if;

      update producto
         set stock_actual = nvl(
         stock_actual,
         0
      ) - :new.cantidad,
             fecha_modificacion = systimestamp,
             usuario_modificacion = v_user
       where id_producto = :new.id_producto;
   end if;

exception
   when no_data_found then
      raise_application_error(
         -20002,
         'Producto no encontrado (movimientos -> id_producto='
         || :new.id_producto
         || ')'
      );
end trg_actualizar_stock;

create or replace trigger trg_validar_pedido before
   insert on detalle_pedido
   for each row
declare
   v_stock producto.stock_actual%type;
begin
   if nvl(
      :new.cantidad,
      0
   ) <= 0 then
      raise_application_error(
         -20007,
         'Cantidad del detalle debe ser mayor a cero.'
      );
   end if;

   select nvl(
      stock_actual,
      0
   )
     into v_stock
     from producto
    where id_producto = :new.id_producto
   for update;

   if v_stock < :new.cantidad then
      raise_application_error(
         -20003,
         'No hay stock suficiente para el producto ID='
         || :new.id_producto
         || ' (solicitado='
         || :new.cantidad
         || ', disponible='
         || v_stock
         || ')'
      );
   end if;

exception
   when no_data_found then
      raise_application_error(
         -20004,
         'Producto no encontrado al validar pedido. ID=' || :new.id_producto
      );
end trg_validar_pedido;

create or replace trigger trg_generar_codigo before
   insert on pedido
   for each row
declare
   v_seq number;
begin
   if :new.codigo is null then
      select seq_codigo_pedido.nextval
        into v_seq
        from dual;
      :new.codigo := 'P-'
                     || to_char(
         sysdate,
         'YYYY'
      )
                     || '-'
                     || lpad(
         to_char(v_seq),
         6,
         '0'
      );
   end if;
end trg_generar_codigo;

create or replace package pkg_dp_ctx as
   type t_num_list is
      table of number index by pls_integer;
   procedure reset;
   procedure add_id (
      p_id number
   );
   function get_count return pls_integer;
   function get_id (
      p_index pls_integer
   ) return number;
end pkg_dp_ctx;

create or replace package body pkg_dp_ctx as
   g_ids   t_num_list;
   g_count pls_integer := 0;

   procedure reset is
   begin
      g_ids.delete;
      g_count := 0;
   end;

   procedure add_id (
      p_id number
   ) is
      i pls_integer;
   begin
      if p_id is null then
         return;
      end if;
    -- evitar duplicados
      i := 1;
      while i <= g_count loop
         if g_ids(i) = p_id then
            return;
         end if;
         i := i + 1;
      end loop;
      g_count := g_count + 1;
      g_ids(g_count) := p_id;
   end;

   function get_count return pls_integer is
   begin
      return g_count;
   end;

   function get_id (
      p_index pls_integer
   ) return number is
   begin
      return g_ids(p_index);
   end;
end pkg_dp_ctx;

create or replace trigger trg_dp_total_bstmt before
   insert or update or delete on detalle_pedido
begin
   pkg_dp_ctx.reset;
end trg_dp_total_bstmt;

create or replace trigger trg_dp_total_aerow after
   insert or update or delete on detalle_pedido
   for each row
begin
   if inserting
   or updating then
      pkg_dp_ctx.add_id(:new.id_pedido);
   end if;
   if deleting
   or updating then
      pkg_dp_ctx.add_id(:old.id_pedido);
   end if;
end trg_dp_total_aerow;

create or replace trigger trg_dp_total_astmt after
   insert or update or delete on detalle_pedido
declare
   v_total number(
      12,
      2
   );
   i       pls_integer;
   v_id    number;
begin
   i := 1;
   while i <= pkg_dp_ctx.get_count loop
      v_id := pkg_dp_ctx.get_id(i);
      select nvl(
         sum(subtotal),
         0
      )
        into v_total
        from detalle_pedido
       where id_pedido = v_id;

      update pedido
         set total = v_total,
             fecha_modificacion = systimestamp
       where id_pedido = v_id;

      i := i + 1;
   end loop;
end trg_dp_total_astmt;

create or replace trigger trg_auditar_productos after
   update or delete on producto
   for each row
declare
   v_accion      varchar2(10);
   v_usuario     varchar2(128);
   v_id_producto producto.id_producto%type;
   v_detalles    varchar2(4000);
   function nvls (
      v varchar2
   ) return varchar2 is
   begin
      return nvl(
         v,
         'NULL'
      );
   end;
begin
   if updating then
      v_accion := 'UPDATE';
      v_id_producto := :new.id_producto;
      v_usuario := coalesce(
         :new.usuario_modificacion,
         :old.usuario_modificacion,
         :new.usuario_creacion,
         :old.usuario_creacion,
         user
      );
      v_detalles := 'ANTES{'
                    || 'nombre='
                    || nvls(:old.nombre)
                    || ', descripcion='
                    || nvls(:old.descripcion)
                    || ', precio='
                    || nvls(to_char(:old.precio))
                    || ', stock_min='
                    || nvls(to_char(:old.stock_minimo))
                    || ', stock_act='
                    || nvls(to_char(:old.stock_actual))
                    || ', id_categoria='
                    || nvls(to_char(:old.id_categoria))
                    || ', id_proveedor='
                    || nvls(to_char(:old.id_proveedor))
                    || '} | DESPUES{'
                    || 'nombre='
                    || nvls(:new.nombre)
                    || ', descripcion='
                    || nvls(:new.descripcion)
                    || ', precio='
                    || nvls(to_char(:new.precio))
                    || ', stock_min='
                    || nvls(to_char(:new.stock_minimo))
                    || ', stock_act='
                    || nvls(to_char(:new.stock_actual))
                    || ', id_categoria='
                    || nvls(to_char(:new.id_categoria))
                    || ', id_proveedor='
                    || nvls(to_char(:new.id_proveedor))
                    || '}';
   elsif deleting then
      v_accion := 'DELETE';
      v_id_producto := :old.id_producto;
      v_usuario := coalesce(
         :old.usuario_modificacion,
         :old.usuario_creacion,
         user
      );
      v_detalles := 'ELIMINADO{'
                    || 'nombre='
                    || nvls(:old.nombre)
                    || ', descripcion='
                    || nvls(:old.descripcion)
                    || ', precio='
                    || nvls(to_char(:old.precio))
                    || ', stock_min='
                    || nvls(to_char(:old.stock_minimo))
                    || ', stock_act='
                    || nvls(to_char(:old.stock_actual))
                    || ', id_categoria='
                    || nvls(to_char(:old.id_categoria))
                    || ', id_proveedor='
                    || nvls(to_char(:old.id_proveedor))
                    || '}';
   end if;
   insert into auditoria_producto (
      id_producto,
      fecha_auditoria,
      usuario,
      accion,
      detalles
   ) values ( v_id_producto,
              systimestamp,
              v_usuario,
              v_accion,
              v_detalles );
end trg_auditar_productos;