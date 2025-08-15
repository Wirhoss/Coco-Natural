-- pkg_producto.sql
-- Package: pkg_producto
-- Contiene: procedimientos y funciones para la tabla PRODUCTO

CREATE OR REPLACE PACKAGE pkg_producto AS
   PROCEDURE insertar_producto (
      p_nombre       IN producto.nombre%TYPE,
      p_descripcion  IN producto.descripcion%TYPE,
      p_precio       IN producto.precio%TYPE,
      p_stock_minimo IN producto.stock_minimo%TYPE,
      p_stock_actual IN producto.stock_actual%TYPE,
      p_id_categoria IN producto.id_categoria%TYPE,
      p_id_proveedor IN producto.id_proveedor%TYPE,
      p_usuario      IN producto.usuario_creacion%TYPE DEFAULT USER
   );

   PROCEDURE actualizar_producto (
      p_id_producto  IN producto.id_producto%TYPE,
      p_nombre       IN producto.nombre%TYPE,
      p_descripcion  IN producto.descripcion%TYPE,
      p_precio       IN producto.precio%TYPE,
      p_stock_minimo IN producto.stock_minimo%TYPE,
      p_stock_actual IN producto.stock_actual%TYPE,
      p_id_categoria IN producto.id_categoria%TYPE,
      p_id_proveedor IN producto.id_proveedor%TYPE
   );

   PROCEDURE eliminar_producto (
      p_id_producto IN producto.id_producto%TYPE
   );

   FUNCTION obtener_productos RETURN SYS_REFCURSOR;

   FUNCTION fn_obtener_nombre_producto (
      p_id_producto IN producto.id_producto%TYPE
   ) RETURN VARCHAR2;

   FUNCTION fn_precio_promedio_categoria (
      p_id_categoria IN categoria.id_categoria%TYPE
   ) RETURN NUMBER;

   FUNCTION cur_productos_por_categoria (
      p_id_categoria IN categoria.id_categoria%TYPE
   ) RETURN SYS_REFCURSOR;

   FUNCTION cur_productos_sin_movimientos (
      p_dias IN NUMBER
   ) RETURN SYS_REFCURSOR;
END pkg_producto;

CREATE OR REPLACE PACKAGE BODY pkg_producto AS
   PROCEDURE insertar_producto (
      p_nombre       IN producto.nombre%TYPE,
      p_descripcion  IN producto.descripcion%TYPE,
      p_precio       IN producto.precio%TYPE,
      p_stock_minimo IN producto.stock_minimo%TYPE,
      p_stock_actual IN producto.stock_actual%TYPE,
      p_id_categoria IN producto.id_categoria%TYPE,
      p_id_proveedor IN producto.id_proveedor%TYPE,
      p_usuario      IN producto.usuario_creacion%TYPE
   ) IS
   BEGIN
      INSERT INTO producto (
         nombre, descripcion, precio, stock_minimo, stock_actual,
         id_categoria, id_proveedor, usuario_creacion
      ) VALUES (
         p_nombre, p_descripcion, p_precio, p_stock_minimo, p_stock_actual,
         p_id_categoria, p_id_proveedor, p_usuario
      );
   END insertar_producto;

   PROCEDURE actualizar_producto (
      p_id_producto  IN producto.id_producto%TYPE,
      p_nombre       IN producto.nombre%TYPE,
      p_descripcion  IN producto.descripcion%TYPE,
      p_precio       IN producto.precio%TYPE,
      p_stock_minimo IN producto.stock_minimo%TYPE,
      p_stock_actual IN producto.stock_actual%TYPE,
      p_id_categoria IN producto.id_categoria%TYPE,
      p_id_proveedor IN producto.id_proveedor%TYPE
   ) IS
   BEGIN
      UPDATE producto
         SET nombre       = COALESCE(p_nombre,       nombre),
             descripcion  = COALESCE(p_descripcion,  descripcion),
             precio       = COALESCE(p_precio,       precio),
             stock_minimo = COALESCE(p_stock_minimo, stock_minimo),
             stock_actual = COALESCE(p_stock_actual, stock_actual),
             id_categoria = COALESCE(p_id_categoria, id_categoria),
             id_proveedor = COALESCE(p_id_proveedor, id_proveedor)
       WHERE id_producto = p_id_producto;
      -- Sin COMMIT aquí.
   END actualizar_producto;

   PROCEDURE eliminar_producto (
      p_id_producto IN producto.id_producto%TYPE
   ) IS
   BEGIN
      DELETE FROM producto
       WHERE id_producto = p_id_producto;
      -- Sin COMMIT aquí.
   END eliminar_producto;

   FUNCTION obtener_productos RETURN SYS_REFCURSOR IS
      c_productos SYS_REFCURSOR;
   BEGIN
      OPEN c_productos FOR
         SELECT *
           FROM producto;
      RETURN c_productos;
   END obtener_productos;

   FUNCTION fn_obtener_nombre_producto (
      p_id_producto IN producto.id_producto%TYPE
   ) RETURN VARCHAR2 IS
      v_nombre VARCHAR2(4000);
   BEGIN
      SELECT nombre
        INTO v_nombre
        FROM producto
       WHERE id_producto = p_id_producto;
      RETURN v_nombre;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RETURN NULL;
   END fn_obtener_nombre_producto;

   FUNCTION fn_precio_promedio_categoria (
      p_id_categoria IN categoria.id_categoria%TYPE
   ) RETURN NUMBER IS
      v_prom NUMBER;
   BEGIN
      SELECT NVL(AVG(precio), 0)
        INTO v_prom
        FROM producto
       WHERE id_categoria = p_id_categoria;
      RETURN v_prom;
   END fn_precio_promedio_categoria;

   FUNCTION cur_productos_por_categoria (
      p_id_categoria IN categoria.id_categoria%TYPE
   ) RETURN SYS_REFCURSOR IS
      rc SYS_REFCURSOR;
   BEGIN
      OPEN rc FOR
         SELECT p.*
           FROM producto p
          WHERE p.id_categoria = p_id_categoria;
      RETURN rc;
   END cur_productos_por_categoria;

   FUNCTION cur_productos_sin_movimientos (
      p_dias IN NUMBER
   ) RETURN SYS_REFCURSOR IS
      rc       SYS_REFCURSOR;
      v_cutoff TIMESTAMP := SYSTIMESTAMP - NUMTODSINTERVAL(NVL(p_dias, 30), 'DAY');
   BEGIN
      OPEN rc FOR
         SELECT p.*
           FROM producto p
          WHERE NOT EXISTS (
                   SELECT 1
                     FROM movimientos m
                    WHERE m.id_producto = p.id_producto
                      AND m.fecha >= v_cutoff
                )
          ORDER BY p.nombre;
      RETURN rc;
   END cur_productos_sin_movimientos;
END pkg_producto;