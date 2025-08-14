create or replace package pkg_funciones is
  -- 1) calcular subtotal (cantidad * precio)
   function fn_calcular_subtotal (
      p_cantidad in number,
      p_precio   in number
   ) return number;

  -- 2) stock disponible (producto_id)
   function fn_stock_disponible (
      p_id_producto in number
   ) return number;

  -- 3) validar stock -> devuelve 1 si suficiente, 0 si no
   function fn_validar_stock (
      p_id_producto in number,
      p_cantidad    in number
   ) return number;

  -- 4) contar pedidos de un cliente
   function fn_contar_pedidos_cliente (
      p_id_cliente in number
   ) return number;

  -- 5) total ventas en mes/año
   function fn_total_ventas_mes (
      p_mes  in number,
      p_anio in number
   ) return number;

  -- 6) precio promedio por categoria
   function fn_precio_promedio_categoria (
      p_id_categoria in number
   ) return number;

  -- 7) obtener nombre producto
   function fn_obtener_nombre_producto (
      p_id_producto in number
   ) return varchar2;

  -- 8) obtener nombre proveedor
   function fn_obtener_nombre_proveedor (
      p_id_proveedor in number
   ) return varchar2;

  -- 9) contar productos por proveedor
   function fn_contar_productos_proveedor (
      p_id_proveedor in number
   ) return number;

  -- 10) calcular edad cliente (si existe fecha_nacimiento en tabla cliente)
  --     devuelve NULL si la columna o el valor no existe
   function fn_calcular_edad_cliente (
      p_id_cliente in number
   ) return number;

  -- 11) dias entrega promedio: si p_id_pedido IS NULL devuelve promedio general, si se pasa id devuelve diff dias para ese pedido
   function fn_dias_entrega_promedio (
      p_id_pedido in number default null
   ) return number;

  -- 12) porcentaje stock (stock_actual / stock_minimo) como decimal (ej: 1.5 = 150%)
   function fn_porcentaje_stock (
      p_id_producto in number
   ) return number;

  -- 13) generar codigo pedido (usa seq_codigo_pedido si existe, sino genera con timestamp + id)
   function fn_generar_codigo_pedido return varchar2;

  -- 14) contar movimientos por tipo ('entrada' o 'salida')
   function fn_contar_movimientos_tipo (
      p_tipo in varchar2
   ) return number;

  -- 15) total compras de un cliente (suma de subtotales)
   function fn_total_compras_cliente (
      p_id_cliente in number
   ) return number;
end pkg_funciones;
/

create or replace package body pkg_funciones is

   function fn_calcular_subtotal (
      p_cantidad in number,
      p_precio   in number
   ) return number is
   begin
      return nvl(
         p_cantidad,
         0
      ) * nvl(
         p_precio,
         0
      );
   end fn_calcular_subtotal;

   function fn_stock_disponible (
      p_id_producto in number
   ) return number is
      v_stock number;
   begin
      select stock_actual
        into v_stock
        from producto
       where id_producto = p_id_producto;
      return v_stock;
   exception
      when no_data_found then
         return null;
   end fn_stock_disponible;

   function fn_validar_stock (
      p_id_producto in number,
      p_cantidad    in number
   ) return number is
      v_stock number;
   begin
      select stock_actual
        into v_stock
        from producto
       where id_producto = p_id_producto;
      if v_stock >= nvl(
         p_cantidad,
         0
      ) then
         return 1; -- suficiente
      else
         return 0; -- insuficiente
      end if;
   exception
      when no_data_found then
         return 0;
   end fn_validar_stock;

   function fn_contar_pedidos_cliente (
      p_id_cliente in number
   ) return number is
      v_count number;
   begin
      select count(*)
        into v_count
        from pedido
       where id_cliente = p_id_cliente;
      return v_count;
   end fn_contar_pedidos_cliente;

   function fn_total_ventas_mes (
      p_mes  in number,
      p_anio in number
   ) return number is
      v_total number;
      v_start date;
      v_end   date;
   begin
      v_start := to_date ( lpad(
         p_mes,
         2,
         '0'
      )
                           || '-'
                           || to_char(p_anio),'MM-YYYY' );
      v_end := add_months(
         v_start,
         1
      ) - 1 / 86400; -- hasta fin de mes (con fracción)

      select nvl(
         sum(d.subtotal),
         0
      )
        into v_total
        from pedido o
        join detalle_pedido d
      on d.id_pedido = o.id_pedido
       where o.fecha_pedido between v_start and v_end;

      return v_total;
   exception
      when others then
         return null;
   end fn_total_ventas_mes;

   function fn_precio_promedio_categoria (
      p_id_categoria in number
   ) return number is
      v_prom number;
   begin
      select nvl(
         avg(precio),
         0
      )
        into v_prom
        from producto
       where id_categoria = p_id_categoria;
      return v_prom;
   exception
      when no_data_found then
         return null;
   end fn_precio_promedio_categoria;

   function fn_obtener_nombre_producto (
      p_id_producto in number
   ) return varchar2 is
      v_nombre varchar2(4000);
   begin
      select nombre
        into v_nombre
        from producto
       where id_producto = p_id_producto;
      return v_nombre;
   exception
      when no_data_found then
         return null;
   end fn_obtener_nombre_producto;

   function fn_obtener_nombre_proveedor (
      p_id_proveedor in number
   ) return varchar2 is
      v_nombre varchar2(4000);
   begin
      select nombre
        into v_nombre
        from proveedor
       where id_proveedor = p_id_proveedor;
      return v_nombre;
   exception
      when no_data_found then
         return null;
   end fn_obtener_nombre_proveedor;

   function fn_contar_productos_proveedor (
      p_id_proveedor in number
   ) return number is
      v_count number;
   begin
      select count(*)
        into v_count
        from producto
       where id_proveedor = p_id_proveedor;
      return v_count;
   end fn_contar_productos_proveedor;

   function fn_calcular_edad_cliente (
      p_id_cliente in number
   ) return number is
      v_exists number := 0;
      v_fecha  date;
      v_edad   number;
   begin
    -- Verificar si la columna FECHA_NACIMIENTO existe en la tabla CLIENTE
      select count(*)
        into v_exists
        from user_tab_columns
       where table_name = 'CLIENTE'
         and column_name = 'FECHA_NACIMIENTO';

      if v_exists = 0 then
         return null; -- columna no existente
      end if;

    -- Si existe, intentar obtener el valor
      execute immediate 'SELECT fecha_nacimiento FROM cliente WHERE id_cliente = :1'
        into v_fecha
         using p_id_cliente;
      if v_fecha is null then
         return null;
      end if;
      v_edad := floor(months_between(
         trunc(sysdate),
         trunc(v_fecha)
      ) / 12);
      return v_edad;
   exception
      when no_data_found then
         return null;
      when others then
         return null;
   end fn_calcular_edad_cliente;

   function fn_dias_entrega_promedio (
      p_id_pedido in number default null
   ) return number is
      v_days number;
   begin
      if p_id_pedido is not null then
         select ( o.fecha_entrega - o.fecha_pedido )
           into v_days
           from pedido o
          where o.id_pedido = p_id_pedido
            and o.fecha_entrega is not null;
         return v_days;
      else
         select avg(o.fecha_entrega - o.fecha_pedido)
           into v_days
           from pedido o
          where o.fecha_entrega is not null
            and o.fecha_pedido is not null;
         return v_days;
      end if;
   exception
      when no_data_found then
         return null;
      when others then
         return null;
   end fn_dias_entrega_promedio;

   function fn_porcentaje_stock (
      p_id_producto in number
   ) return number is
      v_stock number;
      v_min   number;
   begin
      select stock_actual,
             stock_minimo
        into
         v_stock,
         v_min
        from producto
       where id_producto = p_id_producto;
      if v_min is null
      or v_min = 0 then
         return null;
      end if;
      return ( v_stock / v_min );
   exception
      when no_data_found then
         return null;
   end fn_porcentaje_stock;

   function fn_generar_codigo_pedido return varchar2 is
      v_exists number := 0;
      v_seq    number;
      v_codigo varchar2(100);
   begin
    -- Verificamos si existe la secuencia seq_codigo_pedido
      select count(*)
        into v_exists
        from user_sequences
       where sequence_name = 'SEQ_CODIGO_PEDIDO';

      if v_exists > 0 then
         execute immediate 'SELECT seq_codigo_pedido.NEXTVAL FROM dual'
           into v_seq;
         v_codigo := 'P-'
                     || to_char(
            sysdate,
            'YYYY'
         )
                     || '-'
                     || lpad(
            v_seq,
            6,
            '0'
         );
      else
      -- Si no hay secuencia, generamos con timestamp + random
         v_codigo := 'P-'
                     || to_char(
            sysdate,
            'YYYYMMDDHH24MISS'
         )
                     || '-'
                     || substr(
            dbms_random.string(
               'X',
               6
            ),
            1,
            6
         );
      end if;

      return v_codigo;
   exception
      when others then
         return null;
   end fn_generar_codigo_pedido;

   function fn_contar_movimientos_tipo (
      p_tipo in varchar2
   ) return number is
      v_count number;
   begin
      select count(*)
        into v_count
        from movimientos
       where upper(tipo) = upper(nvl(
         p_tipo,
         ' '
      ));
      return v_count;
   exception
      when others then
         return null;
   end fn_contar_movimientos_tipo;

   function fn_total_compras_cliente (
      p_id_cliente in number
   ) return number is
      v_total number;
   begin
      select nvl(
         sum(d.subtotal),
         0
      )
        into v_total
        from pedido o
        join detalle_pedido d
      on d.id_pedido = o.id_pedido
       where o.id_cliente = p_id_cliente;
      return v_total;
   exception
      when others then
         return null;
   end fn_total_compras_cliente;

end pkg_funciones;