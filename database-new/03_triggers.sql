CREATE OR REPLACE TRIGGER trg_actualizar_stock
AFTER INSERT ON movimientos
FOR EACH ROW
DECLARE
  v_stock producto.stock_actual%TYPE;
BEGIN
  SELECT stock_actual
    INTO v_stock
    FROM producto
   WHERE id_producto = :NEW.id_producto
     FOR UPDATE;

  IF :NEW.tipo = 'entrada' THEN
    UPDATE producto
       SET stock_actual         = stock_actual + :NEW.cantidad,
           fecha_modificacion   = SYSTIMESTAMP,
           usuario_modificacion = :NEW.usuario_creacion
     WHERE id_producto = :NEW.id_producto;
  ELSE
    IF v_stock < :NEW.cantidad THEN
      RAISE_APPLICATION_ERROR(-20001, 'Stock insuficiente para el movimiento. Producto ID='||:NEW.id_producto);
    END IF;

    UPDATE producto
       SET stock_actual         = stock_actual - :NEW.cantidad,
           fecha_modificacion   = SYSTIMESTAMP,
           usuario_modificacion = :NEW.usuario_creacion
     WHERE id_producto = :NEW.id_producto;
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20002, 'Producto no encontrado (movimientos -> id_producto='||:NEW.id_producto||')');
END trg_actualizar_stock;

CREATE OR REPLACE TRIGGER trg_validar_pedido
BEFORE INSERT ON detalle_pedido
FOR EACH ROW
DECLARE
  v_stock producto.stock_actual%TYPE;
BEGIN
  SELECT stock_actual
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
    :NEW.codigo := 'P-' || TO_CHAR(SYSDATE,'YYYY') || '-' || LPAD(v_seq,6,'0');
  END IF;
END trg_generar_codigo;

CREATE OR REPLACE TRIGGER trg_actualizar_total_pedido
AFTER INSERT OR UPDATE OR DELETE ON detalle_pedido
FOR EACH ROW
DECLARE
  PROCEDURE recomputar_total(p_pedido IN detalle_pedido.id_pedido%TYPE) IS
    v_total NUMBER(12,2);
  BEGIN
    SELECT NVL(SUM(subtotal),0)
      INTO v_total
      FROM detalle_pedido
     WHERE id_pedido = p_pedido;

    UPDATE pedido
       SET total = v_total,
           fecha_modificacion = SYSTIMESTAMP
     WHERE id_pedido = p_pedido;
  END;
BEGIN
  IF INSERTING THEN
    recomputar_total(:NEW.id_pedido);

  ELSIF DELETING THEN
    recomputar_total(:OLD.id_pedido);

  ELSIF UPDATING THEN
    recomputar_total(:NEW.id_pedido);
    IF :NEW.id_pedido <> :OLD.id_pedido THEN
      recomputar_total(:OLD.id_pedido);
    END IF;
  END IF;
END trg_actualizar_total_pedido;


CREATE OR REPLACE TRIGGER trg_auditar_productos
AFTER UPDATE OR DELETE ON producto
FOR EACH ROW
DECLARE
  v_accion   VARCHAR2(10);
  v_detalles VARCHAR2(4000);
  v_usuario  VARCHAR2(50);
BEGIN
  IF UPDATING THEN
    v_accion := 'UPDATE';
    v_usuario := NVL(:NEW.usuario_modificacion, :OLD.usuario_modificacion);
    v_detalles := 'ANTES -> nombre='||NVL(:OLD.nombre,'NULL')||
                  ', precio='||NVL(TO_CHAR(:OLD.precio),'NULL')||
                  ' | DESPUES -> nombre='||NVL(:NEW.nombre,'NULL')||
                  ', precio='||NVL(TO_CHAR(:NEW.precio),'NULL');
  ELSE
    v_accion := 'DELETE';
    v_usuario := NVL(:OLD.usuario_modificacion, :OLD.usuario_creacion);
    v_detalles := 'ELIMINADO -> nombre='||NVL(:OLD.nombre,'NULL')||
                  ', precio='||NVL(TO_CHAR(:OLD.precio),'NULL');
  END IF;

  INSERT INTO auditoria_producto (id_producto, fecha_auditoria, usuario, accion, detalles)
  VALUES (NVL(:OLD.id_producto, :NEW.id_producto), SYSTIMESTAMP, v_usuario, v_accion, v_detalles);
END trg_auditar_productos;
