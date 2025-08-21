-- pkg_movimiento.sql
-- Package: pkg_movimiento
-- Contiene: procedimientos y funciones para la tabla MOVIMIENTOS

CREATE OR REPLACE PACKAGE pkg_movimiento AS
   PROCEDURE insertar_movimiento (
      p_tipo        IN movimientos.tipo%TYPE,
      p_cantidad    IN movimientos.cantidad%TYPE,
      p_id_producto IN movimientos.id_producto%TYPE,
      p_usuario     IN movimientos.usuario_creacion%TYPE DEFAULT USER
   );

   PROCEDURE actualizar_movimiento (
      p_id_movimiento IN movimientos.id_movimiento%TYPE,
      p_tipo          IN movimientos.tipo%TYPE,
      p_cantidad      IN movimientos.cantidad%TYPE,
      p_id_producto   IN movimientos.id_producto%TYPE
   );

   PROCEDURE eliminar_movimiento (
      p_id_movimiento IN movimientos.id_movimiento%TYPE
   );

   FUNCTION obtener_movimientos RETURN SYS_REFCURSOR;

   FUNCTION cur_movimientos_por_producto (
      p_id_producto IN producto.id_producto%TYPE
   ) RETURN SYS_REFCURSOR;

   FUNCTION cur_movimientos_invalidos RETURN SYS_REFCURSOR;

   FUNCTION fn_contar_movimientos_tipo (
      p_tipo IN VARCHAR2
   ) RETURN NUMBER;
END pkg_movimiento;

CREATE OR REPLACE PACKAGE BODY pkg_movimiento AS
   PROCEDURE insertar_movimiento (
      p_tipo        IN movimientos.tipo%TYPE,
      p_cantidad    IN movimientos.cantidad%TYPE,
      p_id_producto IN movimientos.id_producto%TYPE,
      p_usuario     IN movimientos.usuario_creacion%TYPE
   ) IS
   BEGIN
      INSERT INTO movimientos (
         tipo,
         cantidad,
         id_producto,
         usuario_creacion
      ) VALUES (
         p_tipo,
         p_cantidad,
         p_id_producto,
         p_usuario
      );
   END insertar_movimiento;

   PROCEDURE actualizar_movimiento (
      p_id_movimiento IN movimientos.id_movimiento%TYPE,
      p_tipo          IN movimientos.tipo%TYPE,
      p_cantidad      IN movimientos.cantidad%TYPE,
      p_id_producto   IN movimientos.id_producto%TYPE
   ) IS
   BEGIN
      UPDATE movimientos
         SET tipo        = COALESCE(NULLIF(p_tipo, ''), tipo),
             cantidad    = COALESCE(p_cantidad, cantidad),
             id_producto = COALESCE(p_id_producto, id_producto)
       WHERE id_movimiento = p_id_movimiento;
   END actualizar_movimiento;

   PROCEDURE eliminar_movimiento (
      p_id_movimiento IN movimientos.id_movimiento%TYPE
   ) IS
   BEGIN
      DELETE FROM movimientos
       WHERE id_movimiento = p_id_movimiento;
   END eliminar_movimiento;

   FUNCTION obtener_movimientos RETURN SYS_REFCURSOR IS
      c_movimientos SYS_REFCURSOR;
   BEGIN
      OPEN c_movimientos FOR
         SELECT * FROM movimientos;
      RETURN c_movimientos;
   END obtener_movimientos;

   FUNCTION cur_movimientos_por_producto (
      p_id_producto IN producto.id_producto%TYPE
   ) RETURN SYS_REFCURSOR IS
      rc SYS_REFCURSOR;
   BEGIN
      OPEN rc FOR
         SELECT m.*,
                p.nombre AS producto_nombre,
                p.stock_actual
           FROM movimientos m
           JOIN producto p
             ON m.id_producto = p.id_producto
          WHERE m.id_producto = p_id_producto
          ORDER BY m.fecha DESC;
      RETURN rc;
   END cur_movimientos_por_producto;

   FUNCTION cur_movimientos_invalidos RETURN SYS_REFCURSOR IS
      rc SYS_REFCURSOR;
   BEGIN
      OPEN rc FOR
         SELECT m.*,
                p.nombre AS producto_nombre
           FROM movimientos m
           LEFT JOIN producto p
             ON m.id_producto = p.id_producto
          WHERE m.cantidad <= 0
          ORDER BY m.fecha DESC;
      RETURN rc;
   END cur_movimientos_invalidos;

   FUNCTION fn_contar_movimientos_tipo (
      p_tipo IN VARCHAR2
   ) RETURN NUMBER IS
      v_count NUMBER;
   BEGIN
      IF p_tipo IS NULL THEN
         SELECT COUNT(*) INTO v_count FROM movimientos;
      ELSE
         SELECT COUNT(*)
           INTO v_count
           FROM movimientos
          WHERE UPPER(tipo) = UPPER(p_tipo);
      END IF;
      RETURN v_count;
   EXCEPTION
      WHEN OTHERS THEN
         RETURN NULL;
   END fn_contar_movimientos_tipo;
END pkg_movimiento;