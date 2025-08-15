CREATE OR REPLACE TRIGGER trg_actualizar_stock
AFTER INSERT ON movimientos
FOR EACH ROW
DECLARE
  v_stock     producto.stock_actual%TYPE;
  v_tipo_norm VARCHAR2(20);
  v_user      VARCHAR2(128);
BEGIN
  v_user := NVL(:NEW.usuario_creacion, USER);
  v_tipo_norm := LOWER(TRIM(:NEW.tipo));

  IF v_tipo_norm NOT IN ('entrada','salida') THEN
    RAISE_APPLICATION_ERROR(-20006,
      'Tipo de movimiento inválido: '||NVL(:NEW.tipo,'NULL')||' (permitidos: entrada/salida)');
  END IF;

  IF NVL(:NEW.cantidad, 0) <= 0 THEN
    RAISE_APPLICATION_ERROR(-20005, 'Cantidad debe ser mayor a cero.');
  END IF;

  SELECT NVL(stock_actual,0)
    INTO v_stock
    FROM producto
   WHERE id_producto = :NEW.id_producto
     FOR UPDATE;

  IF v_tipo_norm = 'entrada' THEN
    UPDATE producto
       SET stock_actual         = NVL(stock_actual,0) + :NEW.cantidad,
           fecha_modificacion   = SYSTIMESTAMP,
           usuario_modificacion = v_user
     WHERE id_producto = :NEW.id_producto;

  ELSE -- 'salida'
    IF v_stock < :NEW.cantidad THEN
      RAISE_APPLICATION_ERROR(
        -20001,
        'Stock insuficiente para el movimiento. Producto ID='||:NEW.id_producto||
        ' (solicitado='||:NEW.cantidad||', disponible='||v_stock||')'
      );
    END IF;

    UPDATE producto
       SET stock_actual         = NVL(stock_actual,0) - :NEW.cantidad,
           fecha_modificacion   = SYSTIMESTAMP,
           usuario_modificacion = v_user
     WHERE id_producto = :NEW.id_producto;
  END IF;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(
      -20002,
      'Producto no encontrado (movimientos -> id_producto='||:NEW.id_producto||')'
    );
END trg_actualizar_stock;

CREATE OR REPLACE TRIGGER trg_validar_pedido
BEFORE INSERT ON detalle_pedido
FOR EACH ROW
DECLARE
  v_stock producto.stock_actual%TYPE;
BEGIN
  IF NVL(:NEW.cantidad, 0) <= 0 THEN
    RAISE_APPLICATION_ERROR(-20007, 'Cantidad del detalle debe ser mayor a cero.');
  END IF;

  SELECT NVL(stock_actual,0)
    INTO v_stock
    FROM producto
   WHERE id_producto = :NEW.id_producto
     FOR UPDATE;

  IF v_stock < :NEW.cantidad THEN
    RAISE_APPLICATION_ERROR(
      -20003,
      'No hay stock suficiente para el producto ID='||:NEW.id_producto||
      ' (solicitado='||:NEW.cantidad||', disponible='||v_stock||')'
    );
  END IF;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20004, 'Producto no encontrado al validar pedido. ID='||:NEW.id_producto);
END trg_validar_pedido;

CREATE OR REPLACE TRIGGER trg_generar_codigo
BEFORE INSERT ON pedido
FOR EACH ROW
DECLARE
  v_seq NUMBER;
BEGIN
  IF :NEW.codigo IS NULL THEN
    SELECT seq_codigo_pedido.NEXTVAL INTO v_seq FROM dual;
    :NEW.codigo := 'P-' || TO_CHAR(SYSDATE,'YYYY') || '-' || LPAD(TO_CHAR(v_seq), 6, '0');
  END IF;
END trg_generar_codigo;

CREATE OR REPLACE PACKAGE pkg_dp_ctx AS
  TYPE t_num_list IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  PROCEDURE reset;
  PROCEDURE add_id(p_id NUMBER);
  FUNCTION get_count RETURN PLS_INTEGER;
  FUNCTION get_id(p_index PLS_INTEGER) RETURN NUMBER;
END pkg_dp_ctx;

CREATE OR REPLACE PACKAGE BODY pkg_dp_ctx AS
  g_ids   t_num_list;
  g_count PLS_INTEGER := 0;

  PROCEDURE reset IS
  BEGIN
    g_ids.DELETE;
    g_count := 0;
  END;

  PROCEDURE add_id(p_id NUMBER) IS
    i PLS_INTEGER;
  BEGIN
    IF p_id IS NULL THEN
      RETURN;
    END IF;
    -- evitar duplicados
    i := 1;
    WHILE i <= g_count LOOP
      IF g_ids(i) = p_id THEN
        RETURN;
      END IF;
      i := i + 1;
    END LOOP;
    g_count := g_count + 1;
    g_ids(g_count) := p_id;
  END;

  FUNCTION get_count RETURN PLS_INTEGER IS
  BEGIN
    RETURN g_count;
  END;

  FUNCTION get_id(p_index PLS_INTEGER) RETURN NUMBER IS
  BEGIN
    RETURN g_ids(p_index);
  END;
END pkg_dp_ctx;

CREATE OR REPLACE TRIGGER trg_dp_total_bstmt
BEFORE INSERT OR UPDATE OR DELETE ON detalle_pedido
BEGIN
  pkg_dp_ctx.reset;
END trg_dp_total_bstmt;

CREATE OR REPLACE TRIGGER trg_dp_total_aerow
AFTER INSERT OR UPDATE OR DELETE ON detalle_pedido
FOR EACH ROW
BEGIN
  IF INSERTING OR UPDATING THEN
    pkg_dp_ctx.add_id(:NEW.id_pedido);
  END IF;

  IF DELETING OR UPDATING THEN
    pkg_dp_ctx.add_id(:OLD.id_pedido);
  END IF;
END trg_dp_total_aerow;

CREATE OR REPLACE TRIGGER trg_dp_total_astmt
AFTER INSERT OR UPDATE OR DELETE ON detalle_pedido
DECLARE
  v_total NUMBER(12,2);
  i       PLS_INTEGER;
  v_id    NUMBER;
BEGIN
  i := 1;
  WHILE i <= pkg_dp_ctx.get_count LOOP
    v_id := pkg_dp_ctx.get_id(i);

    SELECT NVL(SUM(subtotal),0)
      INTO v_total
      FROM detalle_pedido
     WHERE id_pedido = v_id;

    UPDATE pedido
       SET total = v_total,
           fecha_modificacion = SYSTIMESTAMP
     WHERE id_pedido = v_id;

    i := i + 1;
  END LOOP;
END trg_dp_total_astmt;

CREATE OR REPLACE TRIGGER trg_auditar_productos
AFTER UPDATE OR DELETE ON producto
FOR EACH ROW
DECLARE
  v_accion      VARCHAR2(10);
  v_detalles    VARCHAR2(4000);
  v_usuario     VARCHAR2(128);
  v_id_producto producto.id_producto%TYPE;
BEGIN
  IF UPDATING THEN
    v_accion      := 'UPDATE';
    v_usuario     := NVL(:NEW.usuario_modificacion, :OLD.usuario_modificacion);
    v_id_producto := :NEW.id_producto;

    v_detalles := 'ANTES -> nombre='||NVL(:OLD.nombre,'NULL')||
                  ', precio='||NVL(TO_CHAR(:OLD.precio),'NULL')||
                  ' | DESPUES -> nombre='||NVL(:NEW.nombre,'NULL')||
                  ', precio='||NVL(TO_CHAR(:NEW.precio),'NULL');

  ELSIF DELETING THEN
    v_accion      := 'DELETE';
    v_usuario     := NVL(:OLD.usuario_modificacion, :OLD.usuario_creacion);
    v_id_producto := :OLD.id_producto;

    v_detalles := 'ELIMINADO -> nombre='||NVL(:OLD.nombre,'NULL')||
                  ', precio='||NVL(TO_CHAR(:OLD.precio),'NULL');
  END IF;

  INSERT INTO auditoria_producto (id_producto, fecha_auditoria, usuario, accion, detalles)
  VALUES (v_id_producto, SYSTIMESTAMP, v_usuario, v_accion, v_detalles);
END trg_auditar_productos;

